import '../../domain/entities/attendance_entity.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    required super.type,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    super.isSynced = true,
    super.sessionId,
  });

  /// Convert SQLite Map -> AttendanceModel
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      type: AttendanceType.fromString(map['type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isSynced: (map['isSynced'] as int) == 1,
      sessionId: map['sessionId'] as String?,
    );
  }

  /// Convert AttendanceModel -> SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type == AttendanceType.checkIn ? 'CHECK_IN' : 'CHECK_OUT',
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'isSynced': isSynced ? 1 : 0,
      'sessionId': sessionId,
    };
  }

  /// Convert JSON (REST API) -> AttendanceModel
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      type: AttendanceType.fromString(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isSynced: json['isSynced'] as bool? ?? true,
      sessionId: json['sessionId'] as String?,
    );
  }

  /// Convert AttendanceModel -> JSON (REST API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type == AttendanceType.checkIn ? 'CHECK_IN' : 'CHECK_OUT',
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'isSynced': isSynced,
      'sessionId': sessionId,
    };
  }

  factory AttendanceModel.fromEntity(AttendanceEntity entity) {
    return AttendanceModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      type: entity.type,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isSynced: entity.isSynced,
      sessionId: entity.sessionId,
    );
  }
}