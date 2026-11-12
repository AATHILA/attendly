import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_entity.dart';

enum AttendanceStatus { initial, loading, success, failure }

class AttendanceState extends Equatable {
  final AttendanceStatus status;
  final List<AttendanceEntity> history;
  final AttendanceEntity? latestRecord;
  final String? errorMessage;
  final String? successMessage;
  final bool hasCheckedInToday;
  final bool hasCheckedOutToday;
  final bool isSyncing;

  const AttendanceState({
    this.status = AttendanceStatus.initial,
    this.history = const [],
    this.latestRecord,
    this.errorMessage,
    this.successMessage,
    this.hasCheckedInToday = false,
    this.hasCheckedOutToday = false,
    this.isSyncing = false,
  });

  AttendanceState copyWith({
    AttendanceStatus? status,
    List<AttendanceEntity>? history,
    AttendanceEntity? latestRecord,
    String? errorMessage,
    String? successMessage,
    bool? hasCheckedInToday,
    bool? hasCheckedOutToday,
    bool? isSyncing,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      history: history ?? this.history,
      latestRecord: latestRecord ?? this.latestRecord,
      errorMessage: errorMessage,
      successMessage: successMessage,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      hasCheckedOutToday: hasCheckedOutToday ?? this.hasCheckedOutToday,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        history,
        latestRecord,
        errorMessage,
        successMessage,
        hasCheckedInToday,
        hasCheckedOutToday,
        isSyncing,
      ];
}