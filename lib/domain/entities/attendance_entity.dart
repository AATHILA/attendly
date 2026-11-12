import 'package:equatable/equatable.dart';

enum AttendanceType {
  checkIn,
  checkOut;

  static AttendanceType fromString(String type) {
    return type.toUpperCase() == 'CHECK_OUT'
        ? AttendanceType.checkOut
        : AttendanceType.checkIn;
  }

  String toDisplayString() {
    return this == AttendanceType.checkIn ? 'Check-In' : 'Check-Out';
  }
}

class AttendanceEntity extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final AttendanceType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool isSynced;
  final String? sessionId;

  const AttendanceEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.isSynced = true,
    this.sessionId,
  });

  @override
  List<Object?> get props => [
        id,
        employeeId,
        employeeName,
        type,
        timestamp,
        latitude,
        longitude,
        isSynced,
        sessionId,
      ];
}