import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../../domain/entities/qr_session_entity.dart';

enum AdminStatus { initial, loading, success, error }

class AdminState extends Equatable {
  final AdminStatus status;
  final List<AttendanceEntity> records;
  final QRSessionEntity? currentSession;
  final String? qrPayloadString;
  final int remainingSeconds;
  final AttendanceType selectedType;
  final String? errorMessage;

  const AdminState({
    this.status = AdminStatus.initial,
    this.records = const [],
    this.currentSession,
    this.qrPayloadString,
    this.remainingSeconds = 0,
    this.selectedType = AttendanceType.checkIn,
    this.errorMessage,
  });

  AdminState copyWith({
    AdminStatus? status,
    List<AttendanceEntity>? records,
    QRSessionEntity? currentSession,
    String? qrPayloadString,
    int? remainingSeconds,
    AttendanceType? selectedType,
    String? errorMessage,
  }) {
    return AdminState(
      status: status ?? this.status,
      records: records ?? this.records,
      currentSession: currentSession ?? this.currentSession,
      qrPayloadString: qrPayloadString ?? this.qrPayloadString,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedType: selectedType ?? this.selectedType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        records,
        currentSession,
        qrPayloadString,
        remainingSeconds,
        selectedType,
        errorMessage,
      ];
}