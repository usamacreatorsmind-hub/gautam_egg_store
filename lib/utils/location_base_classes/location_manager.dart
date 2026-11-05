import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sure_wholesaler/utils/location_base_classes/geocoding_service.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_models.dart';
import 'location_permissions.dart';
import 'location_service.dart';
import 'location_utils.dart';
import 'location_tracking_service.dart';

/// Main location manager that provides a unified interface for all location operations
class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  final LocationPermissions _permissions = LocationPermissions();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  final LocationTrackingService _trackingService = LocationTrackingService();

  // Getters for individual services
  LocationPermissions get permissions => _permissions;
  LocationService get location => _locationService;
  GeocodingService get geocoding => _geocodingService;
  LocationTrackingService get tracking => _trackingService;

  /// Initialize location services - call this once at app startup
  Stream<void> initialize() {
    return Stream.fromFuture(LocationPermissions.ensurePermission());
  }

  /// Get current location with full address information
  Stream<LocationData?> getCurrentLocationWithAddress({
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) {
    return _locationService.watchCurrentPosition(settings: settings).asyncMap(
      (position) async {
        if (position == null) return null;

        final coordinates = LatLng(position.latitude, position.longitude);
        final geocodeResult =
            await _geocodingService.coordinatesToAddress(coordinates);

        return LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          address: geocodeResult.success ? geocodeResult.address : null,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
        );
      },
    );
  }

  /// Watch current location with address updates in real time.
  Stream<LocationData?> watchCurrentLocationWithAddress({
    LocationRequestSettings settings = const LocationRequestSettings(),
  }) {
    return getCurrentLocationWithAddress(settings: settings);
  }

  // /// Geocode an address to coordinates
  // Stream<LocationData?> geocodeAddress(String address) {
  //   return _geocodingService.watchAddressToCoordinates(address).map((result) {
  //     if (!result.success || result.coordinates == null) return null;

  //     return LocationData(
  //       latitude: result.coordinates!.latitude,
  //       longitude: result.coordinates!.longitude,
  //       address: result.address ?? address,
  //     );
  //   });
  // }

  // Stream<LocationData?> watchGeocodeAddress(String address) {
  //   return geocodeAddress(address);
  // }

  /// Reverse geocode coordinates to address
  Stream<String?> reverseGeocode(LatLng coordinates) {
    return _geocodingService
        .watchCoordinatesToAddress(coordinates)
        .map((result) => result.success ? result.address : null);
  }

  Stream<String?> watchReverseGeocode(LatLng coordinates) {
    return reverseGeocode(coordinates);
  }

  /// Check if a location is within radius of another
  Stream<bool> isWithinRadius(
      LocationData center, LocationData point, double radiusMeters) {
    return Stream.fromFuture(LocationUtils.isWithinRadius(center.latitude,
        center.longitude, point.latitude, point.longitude, radiusMeters));
  }

  /// Start location tracking for delivery
  Stream<LocationStartResult> startDeliveryTracking({
    LocationTrackingConfig config = const LocationTrackingConfig(),
  }) {
    return _trackingService.startTrackingStream(config: config);
  }

  /// Stop location tracking
  Stream<void> stopDeliveryTracking() {
    return _trackingService.stopTrackingStream();
  }

  /// Get formatted distance string
  Stream<String> formatDistance(double meters) {
    return Stream.value(LocationUtils.formatDistance(meters));
  }

  /// Get formatted speed string
  Stream<String> formatSpeed(double speedMps) {
    return Stream.value(LocationUtils.formatSpeed(speedMps));
  }

  /// Check if location services are available and permissions granted
  Stream<bool> isLocationAvailable() {
    return Stream.fromFuture(LocationPermissions.checkPermission()).map(
        (permissionResult) =>
            permissionResult == LocationPermissionResult.granted);
  }

  /// Request location permissions with user-friendly messaging
  Stream<bool> requestLocationPermissions() {
    return Stream.fromFuture(LocationPermissions.requestPermission())
        .map((result) => result == LocationPermissionResult.granted);
  }

  /// Create delivery location from order data
  Stream<DeliveryLocation?> createDeliveryLocation(
      Map<String, dynamic> orderData) {
    try {
      return Stream.value(DeliveryLocation.fromOrderData(orderData));
    } catch (e) {
      print('Error creating delivery location: $e');
      return Stream.value(null);
    }
  }

  /// Calculate route distance for multiple points
  Stream<double> calculateRouteDistance(List<LatLng> route) {
    return Stream.fromFuture(LocationUtils.calculateRouteDistance(route));
  }

  /// Simplify route by removing close points
  Stream<List<LatLng>> simplifyRoute(List<LatLng> route, double minDistance) {
    return Stream.fromFuture(LocationUtils.simplifyRoute(route, minDistance));
  }

  /// Get location accuracy description
  Stream<String> getAccuracyDescription(double accuracy) {
    if (accuracy < 10) return Stream.value('High');
    if (accuracy < 50) return Stream.value('Medium');
    if (accuracy < 100) return Stream.value('Low');
    return Stream.value('Poor');
  }

  /// Validate coordinates
  Stream<bool> areValidCoordinates(double latitude, double longitude) {
    return Stream.value(LocationUtils.areValidCoordinates(latitude, longitude));
  }

  /// Normalize coordinates to valid ranges
  Stream<LatLng> normalizeCoordinates(double latitude, double longitude) {
    return Stream.value(
        LocationUtils.normalizeCoordinates(latitude, longitude));
  }

  /// Create bounding box around a point
  Stream<LatLngBounds> createBoundingBox(
      double centerLat, double centerLng, double radiusMeters) {
    return Stream.value(
        LocationUtils.createBoundingBox(centerLat, centerLng, radiusMeters));
  }

  /// Check if point is in bounds
  Stream<bool> isPointInBounds(LatLng point, LatLngBounds bounds) {
    return Stream.value(LocationUtils.isPointInBounds(point, bounds));
  }

  /// Calculate center of multiple points
  Stream<LatLng> calculateCenter(List<LatLng> points) {
    return Stream.value(LocationUtils.calculateCenter(points));
  }

  /// Sort locations by distance from reference point
  Stream<List<LatLng>> sortByDistance(LatLng reference, List<LatLng> points) {
    return Stream.fromFuture(LocationUtils.sortByDistance(reference, points));
  }

  /// Filter locations within radius
  Stream<List<LatLng>> filterByRadius(
      LatLng center, List<LatLng> points, double radiusMeters) {
    return Stream.fromFuture(
        LocationUtils.filterByRadius(center, points, radiusMeters));
  }
}
