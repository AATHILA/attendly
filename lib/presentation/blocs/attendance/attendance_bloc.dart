import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/location_service.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository attendanceRepository;

  AttendanceBloc({required this.attendanceRepository})
      : super(const AttendanceState()) {
    on<MarkAttendanceRequested>(_onMarkAttendanceRequested);
    on<FetchEmployeeHistoryRequested>(_onFetchEmployeeHistoryRequested);
    on<SyncPendingRecordsRequested>(_onSyncPendingRecordsRequested);
  }

  Future<void> _onMarkAttendanceRequested(
    MarkAttendanceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStatus.loading));

    try {
      // 1. Capture real-time GPS location
      final coordinates = await LocationService.getCurrentCoordinates();

      // 2. Mark attendance (Validates QR, expiry, duplicate, and location)
      final record = await attendanceRepository.markAttendance(
        employeeId: event.employeeId,
        employeeName: event.employeeName,
        type: event.type,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        rawQrPayload: event.rawQrPayload,
      );

      final isCheckIn = record.type == AttendanceType.checkIn;

      emit(state.copyWith(
        status: AttendanceStatus.success,
        latestRecord: record,
        successMessage: isCheckIn
            ? 'Successfully Checked In!'
            : 'Successfully Checked Out!',
        hasCheckedInToday: isCheckIn ? true : state.hasCheckedInToday,
        hasCheckedOutToday: !isCheckIn ? true : state.hasCheckedOutToday,
      ));

      // Refresh history list
      add(FetchEmployeeHistoryRequested(event.employeeId));
    } on Failure catch (failure) {
      emit(state.copyWith(
        status: AttendanceStatus.failure,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStatus.failure,
        errorMessage: 'Attendance marking failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchEmployeeHistoryRequested(
    FetchEmployeeHistoryRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final records = await attendanceRepository.getEmployeeHistory(event.employeeId);
      final hasCheckedIn = await attendanceRepository.hasCheckedInToday(event.employeeId);
      final hasCheckedOut = await attendanceRepository.hasCheckedOutToday(event.employeeId);

      emit(state.copyWith(
        history: records,
        hasCheckedInToday: hasCheckedIn,
        hasCheckedOutToday: hasCheckedOut,
      ));
    } catch (_) {
      // Keep existing state if offline or cache error
    }
  }

  Future<void> _onSyncPendingRecordsRequested(
    SyncPendingRecordsRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true));
    try {
      final syncedCount = await attendanceRepository.syncOfflineRecords();
      final records = await attendanceRepository.getEmployeeHistory(event.employeeId);

      emit(state.copyWith(
        isSyncing: false,
        history: records,
        successMessage: syncedCount > 0
            ? 'Successfully synced $syncedCount offline record(s) to server!'
            : 'All records are already up to date.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: 'Sync failed: Server still unreachable.',
      ));
    }
  }
}