import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_entity.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class MarkAttendanceRequested extends AttendanceEvent {
  final String rawQrPayload;
  final String employeeId;
  final String employeeName;
  final AttendanceType type;

  const MarkAttendanceRequested({
    required this.rawQrPayload,
    required this.employeeId,
    required this.employeeName,
    required this.type,
  });

  @override
  List<Object?> get props => [rawQrPayload, employeeId, employeeName, type];
}

class FetchEmployeeHistoryRequested extends AttendanceEvent {
  final String employeeId;

  const FetchEmployeeHistoryRequested(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class SyncPendingRecordsRequested extends AttendanceEvent {
  final String employeeId;

  const SyncPendingRecordsRequested(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}