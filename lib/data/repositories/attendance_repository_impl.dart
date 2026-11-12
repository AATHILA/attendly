import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/qr_crypto_helper.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/local/attendance_database.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDatabase database;
  final Dio dio;
  final Uuid uuid;

  AttendanceRepositoryImpl({
    AttendanceDatabase? db,
    Dio? dioClient,
    Uuid? uuidGenerator,
  })  : database = db ?? AttendanceDatabase.instance,
        dio = dioClient ?? DioClient.dio,
        uuid = uuidGenerator ?? const Uuid();

  @override
  Future<AttendanceEntity> markAttendance({
    required String employeeId,
    required String employeeName,
    required AttendanceType type,
    required double latitude,
    required double longitude,
    required String rawQrPayload,
  }) async {
    // 1. Cryptographic QR Validation & Expiry Check
    final qrResult = QrCryptoHelper.validateQrPayload(rawQrPayload);
    if (!qrResult.isValid) {
      final msg = qrResult.errorMessage ?? 'Invalid QR code.';
      if (msg.toLowerCase().contains('expired')) {
        throw QRExpiredFailure(msg);
      }
      throw QRTamperedFailure(msg);
    }

    final qrData = qrResult.data!;
    final qrSessionId = qrData['sessionId'] as String;
    final qrType = AttendanceType.fromString(qrData['type'] as String);

    // 2. Prevent Duplicate Attendance
    if (qrType == AttendanceType.checkIn) {
      final alreadyCheckedIn = await database.hasCheckedInToday(employeeId);
      if (alreadyCheckedIn) {
        throw const DuplicateAttendanceFailure(
          'Duplicate Entry: You have already checked in today!',
        );
      }
    } else {
      // For Check-Out: verify employee has checked in today
      final hasCheckedIn = await database.hasCheckedInToday(employeeId);
      if (!hasCheckedIn) {
        throw const DuplicateAttendanceFailure(
          'Action Rejected: You must check in before checking out!',
        );
      }

      final alreadyCheckedOut = await database.hasCheckedOutToday(employeeId);
      if (alreadyCheckedOut) {
        throw const DuplicateAttendanceFailure(
          'Duplicate Entry: You have already checked out today!',
        );
      }
    }

    // 3. Construct Attendance Record with Timestamp and GPS
    final recordId = uuid.v4();
    final timestamp = DateTime.now();
    bool isSynced = false;

    // 4. Send to Mock REST API via Dio
    try {
      final response = await dio.post(
        AppConstants.endpointAttendanceMark,
        data: {
          'id': recordId,
          'employeeId': employeeId,
          'employeeName': employeeName,
          'type': qrType == AttendanceType.checkIn ? 'CHECK_IN' : 'CHECK_OUT',
          'timestamp': timestamp.toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
          'sessionId': qrSessionId,
        },
      );

      if (response.statusCode == 200) {
        isSynced = true;
      }
    } on DioException {
      // Network failed: Mark unsynced for offline sync handling
      isSynced = false;
    } catch (_) {
      isSynced = false;
    }

    // 5. Store in local SQLite database
    final recordModel = AttendanceModel(
      id: recordId,
      employeeId: employeeId,
      employeeName: employeeName,
      type: qrType,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      isSynced: isSynced,
      sessionId: qrSessionId,
    );

    await database.insertRecord(recordModel);

    return recordModel;
  }

  @override
  Future<List<AttendanceEntity>> getEmployeeHistory(String employeeId) async {
    try {
      final records = await database.getEmployeeRecords(employeeId);
      return records;
    } catch (e) {
      throw const CacheFailure('Failed to load employee attendance records.');
    }
  }

  @override
  Future<List<AttendanceEntity>> getAllAttendanceRecords() async {
    try {
      final records = await database.getAllRecords();
      return records;
    } catch (e) {
      throw const CacheFailure('Failed to load all attendance records.');
    }
  }

  @override
  Future<bool> hasCheckedInToday(String employeeId) async {
    return await database.hasCheckedInToday(employeeId);
  }

  @override
  Future<int> syncOfflineRecords() async {
    final unsynced = await database.getUnsyncedRecords();
    if (unsynced.isEmpty) return 0;

    final List<String> successfullySyncedIds = [];

    for (final record in unsynced) {
      try {
        final response = await dio.post(
          AppConstants.endpointAttendanceMark,
          data: record.toJson(),
        );

        if (response.statusCode == 200) {
          successfullySyncedIds.add(record.id);
        }
      } catch (_) {
        // If still offline, stop sync attempt
        break;
      }
    }

    if (successfullySyncedIds.isNotEmpty) {
      await database.markRecordsAsSynced(successfullySyncedIds);
    }

    return successfullySyncedIds.length;
  }
}