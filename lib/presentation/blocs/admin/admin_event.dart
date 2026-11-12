import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_entity.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllRecordsEvent extends AdminEvent {
  const FetchAllRecordsEvent();
}

class GenerateQRSessionEvent extends AdminEvent {
  final AttendanceType type;

  const GenerateQRSessionEvent(this.type);

  @override
  List<Object?> get props => [type];
}

class TimerTickEvent extends AdminEvent {
  final int remainingSeconds;

  const TimerTickEvent(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}