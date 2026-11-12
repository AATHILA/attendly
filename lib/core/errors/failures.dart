import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred. Please try again later.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection. Operation saved locally.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local database records.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class QRExpiredFailure extends Failure {
  const QRExpiredFailure([super.message = 'This QR code session has expired.']);
}

class QRTamperedFailure extends Failure {
  const QRTamperedFailure([super.message = 'Invalid or tampered QR code.']);
}

class DuplicateAttendanceFailure extends Failure {
  const DuplicateAttendanceFailure([super.message = 'Attendance already recorded for this session.']);
}

class LocationOutsideOfficeFailure extends Failure {
  const LocationOutsideOfficeFailure([super.message = 'You are outside the permitted office location.']);
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure([super.message = 'Location permission is required to mark attendance.']);
}