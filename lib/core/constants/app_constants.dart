class AppConstants {
  // App Name
  static const String appName = 'Attendly';

  // QR Code Security & Expiry
  static const int qrValiditySeconds = 45; // QR regenerates / expires every 45s
  static const String qrSecretKey = 'ATTENDLY_SECURE_HMAC_SECRET_KEY_2026';

  // Office Location for Geofence validation (e.g., Headquarters)
  // For testing, employees within 500m radius are accepted
  static const double officeLatitude = 37.4219983; // Example: Googleplex HQ / customizable
  static const double officeLongitude = -122.084000;
  static const double officeGeofenceRadiusMeters = 500.0;

  // Local SQLite Database Config
  static const String dbName = 'attendly.db';
  static const int dbVersion = 1;
  static const String tableAttendance = 'attendance_records';

  // Mock REST API endpoints
  static const String baseUrl = 'https://api.attendly.local/v1';
  static const String endpointLogin = '/auth/login';
  static const String endpointAttendanceMark = '/attendance/mark';
  static const String endpointAttendanceHistory = '/attendance/history';
  static const String endpointAdminAllRecords = '/admin/attendance/all';
}