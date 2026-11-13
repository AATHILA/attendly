import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  /// Validates QR, checks location & duplicates, and records check-in/out
  Future<AttendanceEntity> markAttendance({
    required String employeeId,
    required String employeeName,
    required AttendanceType type,
    required double latitude,
    required double longitude,
    required String rawQrPayload,
  });

  /// Fetches history for a specific employee (from local DB + remote sync)
  Future<List<AttendanceEntity>> getEmployeeHistory(String employeeId);

  /// Fetches all records for Admin dashboard
  Future<List<AttendanceEntity>> getAllAttendanceRecords();

  /// Checks if employee already checked in today (duplicate prevention)
  Future<bool> hasCheckedInToday(String employeeId);

  /// Checks if employee already checked out today
  Future<bool> hasCheckedOutToday(String employeeId);

  /// Syncs pending offline records to mock server
  Future<int> syncOfflineRecords();
}