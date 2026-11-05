import 'dart:async';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:sure_wholesaler/utils/location_base_classes/road_distance_service.dart';
import 'location_permissions.dart';
import 'location_utils.dart';

/// Configuration for location requests
class LocationRequestSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  final Duration timeLimit;
  final int? intervalDuration;

  const LocationRequestSettings({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
    this.timeLimit = const Duration(seconds: 30),
    this.intervalDuration,
  });

  LocationRequestSettings copyWith({
    LocationAccuracy? accuracy,
    int? distanceFilter,
    Duration? timeLimit,
    int? intervalDuration,
  }) {
    return LocationRequestSettings(
      accuracy: accuracy ?? this.accuracy,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      timeLimit: timeLimit ?? this.timeLimit,
      intervalDuration: intervalDuration ?? this.intervalDuration,
    );
  }
}

/// Service for handling location operations like getting current position and streaming
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;

  /// Watch the current position in real time.
  Stream<Position?> watchCurrentPosition({
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) async* {
    // We use a loop to allow retrying if permission is granted later or services are enabled
    while (true) {
      final hasPermission = await LocationPermissions.ensurePermission();
      if (!hasPermission) {
        yield null;
        // Wait before retrying to avoid tight loop
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      final lastKnown = await getLastKnownPosition();
      if (lastKnown != null) {
        yield lastKnown;
      }

      try {
        // yield* will stay active until startPositionStream ends or is cancelled
        yield* startPositionStream(settings: settings).map((position) => position);
        // If it ends (e.g. service disabled), the loop will retry
      } catch (e) {
        print('Error in position stream: $e');
        yield null;
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  /// Get current position with specified settings
  Future<Position?> getCurrentPosition({
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) async {
    try {
      // Ensure permissions first
      final hasPermission = await LocationPermissions.ensurePermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: settings.accuracy,
          distanceFilter: settings.distanceFilter,
          timeLimit: settings.timeLimit,
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  /// Start location streaming
  Stream<Position> startPositionStream({
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: settings.accuracy,
        distanceFilter: settings.distanceFilter,
        timeLimit: settings.timeLimit,
      ),
    );
  }

  /// Start listening to position updates
  void startPositionUpdates({
    required Function(Position) onPositionUpdate,
    required Function(Object) onError,
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) {
    stopPositionUpdates(); // Cancel any existing subscription

    _positionStreamSubscription = startPositionStream(settings: settings)
        .listen(onPositionUpdate, onError: onError);
  }

  /// Stop position updates
  void stopPositionUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Check if position updates are active
  bool get isTracking => _positionStreamSubscription != null;

  /// Get position with timeout and error handling
  Future<Position?> getPositionWithTimeout({
    Duration timeout = const Duration(seconds: 10),
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) async {
    try {
      return await getCurrentPosition(settings: settings).timeout(timeout);
    } catch (e) {
      print('Timeout or error getting position: $e');
      return null;
    }
  }

  /// Calculate distance between two positions
  Future<double?> distanceBetween(Position start, Position end) async {
    return await LocationUtils.distanceBetweenPositions(start, end);
  }

  /// Calculate distance between coordinates
  Future<double?> distanceBetweenCoordinates(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return await RoadDistanceService.distanceBetweenCoordinates(
      startLat,
      startLng,
      endLat,
      endLng,
    );
  }

  /// Calculate bearing between two positions
  double bearingBetween(Position start, Position end) {
    return LocationUtils.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Check if device is moving based on speed
  bool isMoving(Position position, {double minSpeed = 0.5}) {
    return position.speed >= minSpeed;
  }

  /// Format position for display
  String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Get location accuracy description
  String getAccuracyDescription(Position position) {
    if (position.accuracy < 10) return 'High';
    if (position.accuracy < 50) return 'Medium';
    if (position.accuracy < 100) return 'Low';
    return 'Poor';
  }

  // ── Static legacy helpers for current location and reverse geocoding ──

  static final loc.Location _location = loc.Location();
  static const Duration _locationTimeout = Duration(seconds: 15);

  /// Get GPS coordinates with timeout to prevent ANR.
  static Future<loc.LocationData> getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location service is disabled');
      }
    }

    loc.PermissionStatus permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    if (permission != loc.PermissionStatus.granted) {
      throw Exception('Location permission denied');
    }

    return await _location.getLocation().timeout(
      _locationTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Location request timed out. Please try again.',
          _locationTimeout,
        );
      },
    );
  }

  /// Reverse geocode to full address with timeout.
  static Future<Placemark> getFullAddress(
      double latitude, double longitude) async {
    final placemarks =
        await placemarkFromCoordinates(latitude, longitude).timeout(
      _locationTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Geocoding request timed out. Please try again.',
          _locationTimeout,
        );
      },
    );
    return placemarks.first;
  }
}
