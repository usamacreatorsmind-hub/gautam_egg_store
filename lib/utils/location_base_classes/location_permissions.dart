import 'package:geolocator/geolocator.dart';

/// Result returned when checking/requesting location permissions
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  servicesDisabled,
}

/// Utility class for handling location permissions and GPS services
class LocationPermissions {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  static Future<LocationPermissionResult> checkPermission() async {
    // First check if services are enabled
    if (!await isLocationServiceEnabled()) {
      return LocationPermissionResult.servicesDisabled;
    }

    final permission = await Geolocator.checkPermission();

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionResult.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionResult.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionResult.granted;
      default:
        return LocationPermissionResult.denied;
    }
  }

  /// Request location permission
  static Future<LocationPermissionResult> requestPermission() async {
    // First check if services are enabled
    if (!await isLocationServiceEnabled()) {
      return LocationPermissionResult.servicesDisabled;
    }

    final permission = await Geolocator.requestPermission();

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionResult.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionResult.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionResult.granted;
      default:
        return LocationPermissionResult.denied;
    }
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permanently denied permissions)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Check and request permission in one call
  /// Returns true if permission is granted, false otherwise
  static Future<bool> ensurePermission() async {
    LocationPermissionResult result = await checkPermission();

    if (result == LocationPermissionResult.servicesDisabled) {
      final enabled = await Geolocator.openLocationSettings();
      if (!enabled) return false;
      result = await checkPermission();
    }

    if (result == LocationPermissionResult.granted) {
      return true;
    }

    if (result == LocationPermissionResult.denied) {
      final requestResult = await requestPermission();
      return requestResult == LocationPermissionResult.granted;
    }

    if (result == LocationPermissionResult.deniedForever) {
      // Permission is permanently denied, we cannot request it again.
      // We can only return false and let the caller decide if they want to show a message or open settings.
      return false;
    }

    return false;
  }

  /// Force open app settings if permission is permanently denied
  static Future<void> handleDeniedForever() async {
    final result = await checkPermission();
    if (result == LocationPermissionResult.deniedForever) {
      await openAppSettings();
    }
  }

  /// Get a user-friendly message for the permission result
  static String getPermissionMessage(LocationPermissionResult result) {
    switch (result) {
      case LocationPermissionResult.granted:
        return 'Location permission granted';
      case LocationPermissionResult.denied:
        return 'Location permission denied. Please grant permission to continue.';
      case LocationPermissionResult.deniedForever:
        return 'Location permission permanently denied. Please enable it in app settings.';
      case LocationPermissionResult.servicesDisabled:
        return 'Location services are disabled. Please enable GPS.';
    }
  }
}
