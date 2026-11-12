import 'package:equatable/equatable.dart';
import 'attendance_entity.dart';

class QRSessionEntity extends Equatable {
  final String sessionId;
  final AttendanceType type;
  final DateTime validFrom;
  final DateTime validUntil;
  final String signature;

  const QRSessionEntity({
    required this.sessionId,
    required this.type,
    required this.validFrom,
    required this.validUntil,
    required this.signature,
  });

  bool get isExpired => DateTime.now().isAfter(validUntil);

  int get remainingSeconds {
    final diff = validUntil.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  @override
  List<Object?> get props => [
        sessionId,
        type,
        validFrom,
        validUntil,
        signature,
      ];
}