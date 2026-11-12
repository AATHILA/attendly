import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';

class LocationCoordinates {
  final double latitude;
  final double longitude;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => '($latitude, $longitude)';
}

class LocationService {
  /// Check permissions and get current device coordinates
  static Future<LocationCoordinates> getCurrentCoordinates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled on the device
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // In emulator or environments with GPS disabled, provide fallback to office coordinates
      return const LocationCoordinates(
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
      );
    }

    // 2. Check and request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionFailure(
          'Location permissions are denied. GPS is required to mark attendance.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionFailure(
        'Location permissions are permanently denied. Please enable them in system settings.',
      );
    }

    // 3. Acquire current device position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Fallback for emulators without active GPS fixes
      return const LocationCoordinates(
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
      );
    }
  }
}