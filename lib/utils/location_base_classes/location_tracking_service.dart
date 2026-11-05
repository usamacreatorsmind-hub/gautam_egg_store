import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'location_permissions.dart';
import 'location_service.dart' as location_service;

/// Result returned by [LocationTrackingService.startTracking].
enum LocationStartResult {
  started,
  alreadyRunning,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  notLoggedIn,
}

/// Configuration for location tracking
class LocationTrackingConfig {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  final Duration updateInterval;
  final bool enableBackgroundTracking;
  final bool saveToFirebase;
  final String? userId;

  const LocationTrackingConfig({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
    this.updateInterval = const Duration(seconds: 30),
    this.enableBackgroundTracking = false,
    this.saveToFirebase = true,
    this.userId,
  });
}

/// Enhanced service for handling GPS permission checking and location tracking.
/// Supports tracking with Firebase integration while the app is active.
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final location_service.LocationService _locationService =
      location_service.LocationService();
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _firebaseUpdateTimer;
  String? _currentUserId;
  Position? _lastPosition;
  final StreamController<bool> _trackingStateController =
      StreamController<bool>.broadcast();
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  final StreamController<LocationStartResult> _statusController =
      StreamController<LocationStartResult>.broadcast();

  /// Whether location tracking is currently active
  bool get isTracking => _isTracking;

  /// Emits `true` when tracking starts and `false` when it stops.
  Stream<bool> get trackingStateStream => _trackingStateController.stream;

  /// Emits the latest tracked device position in real time.
  Stream<Position> get positionStream => _positionController.stream;

  /// Emits tracking lifecycle results such as permission failures or start success.
  Stream<LocationStartResult> get trackingStatusStream =>
      _statusController.stream;

  /// Check and request permission. Returns the result so the caller can show UI.
  Future<LocationStartResult> checkPermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LocationStartResult.notLoggedIn;

    final permissionResult = await LocationPermissions.checkPermission();

    switch (permissionResult) {
      case LocationPermissionResult.granted:
        return LocationStartResult.started;
      case LocationPermissionResult.denied:
        return LocationStartResult.permissionDenied;
      case LocationPermissionResult.deniedForever:
        return LocationStartResult.permissionPermanentlyDenied;
      case LocationPermissionResult.servicesDisabled:
        return LocationStartResult.gpsDisabled;
    }
  }

  /// Start location tracking with custom configuration
  Future<LocationStartResult> startTrackingWithConfig(
      LocationTrackingConfig config) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _statusController.add(LocationStartResult.notLoggedIn);
      return LocationStartResult.notLoggedIn;
    }

    if (_isTracking) {
      _statusController.add(LocationStartResult.alreadyRunning);
      return LocationStartResult.alreadyRunning;
    }

    _currentUserId = config.userId ?? user.uid;

    // Check permissions
    final permissionResult = await checkPermission();
    if (permissionResult != LocationStartResult.started) {
      _statusController.add(permissionResult);
      return permissionResult;
    }

    _isTracking = true;
    _trackingStateController.add(true);

    // Start the shared position stream
    _positionSubscription = _locationService
        .watchCurrentPosition(
          settings: location_service.LocationRequestSettings(
            accuracy: config.accuracy,
            distanceFilter: config.distanceFilter,
          ),
        )
        .where((position) => position != null)
        .cast<Position>()
        .listen(
      (Position position) => _handlePositionUpdate(position, config),
      onError: (error) {
        print('Location tracking error: $error');
        _stopTrackingInternal();
      },
    );

    // Start periodic Firebase updates if enabled
    if (config.saveToFirebase) {
      _startFirebaseUpdates(config.updateInterval);
    }

    _statusController.add(LocationStartResult.started);
    return LocationStartResult.started;
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    await _stopTrackingInternal();
  }

  Future<void> _stopTrackingInternal() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _firebaseUpdateTimer?.cancel();
    _firebaseUpdateTimer = null;

    _isTracking = false;
    _trackingStateController.add(false);

    // Update Firebase to mark tracking as stopped
    if (_currentUserId != null) {
      try {
        await AppConfig.firestore
            .collection('boyInfo')
            .doc(_currentUserId)
            .set({
          'isOnDelivery': false,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating tracking status: $e');
      }
    }

    _lastPosition = null;
    _currentUserId = null;
  }

  void _handlePositionUpdate(Position position, LocationTrackingConfig config) {
    if (!isTracking || _currentUserId == null) return;

    _lastPosition = position;
    _positionController.add(position);

    // Save to Firebase immediately if configured
    if (config.saveToFirebase) {
      _saveLocationToFirebase(position);
    }
  }

  Future<void> _saveLocationToFirebase(Position position) async {
    if (_currentUserId == null) return;

    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isLocationSharingEnabled': true,
      };

      await AppConfig.firestore
          .collection('boyInfo')
          .doc(_currentUserId)
          .set(locationData, SetOptions(merge: true));
    } catch (e) {
      print("Error saving location to Firebase: $e");
    }
  }

  void _startFirebaseUpdates(Duration interval) {
    _firebaseUpdateTimer?.cancel();
    _firebaseUpdateTimer = Timer.periodic(interval, (_) async {
      if (!isTracking) return;

      final position =
          _lastPosition ?? await _locationService.getLastKnownPosition();
      if (position != null) {
        await _saveLocationToFirebase(position);
      }
    });
  }

  /// Legacy alias kept for backward compatibility
  Future<LocationStartResult> startTracking() async {
    return startTrackingWithConfig(const LocationTrackingConfig());
  }

  /// Stream wrapper for callers
  Stream<LocationStartResult> startTrackingStream({
    LocationTrackingConfig config = const LocationTrackingConfig(),
  }) async* {
    yield await startTrackingWithConfig(config);
  }

  /// Stream wrapper for callers
  Stream<void> stopTrackingStream() async* {
    await stopTracking();
  }
}
