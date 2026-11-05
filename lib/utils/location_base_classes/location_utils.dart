import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sure_wholesaler/utils/location_base_classes/road_distance_service.dart';

/// Utility class for location-related calculations and operations
class LocationUtils {
  static const double earthRadius = 6371000; // Earth radius in meters

  /// Calculate distance between two positions in meters using Haversine formula (FREE)
  static Future<double?> distanceBetweenPositions(
      Position pos1, Position pos2) async {
    return Geolocator.distanceBetween(
            pos1.latitude, pos1.longitude, pos2.latitude, pos2.longitude);
  }

  /// Calculate distance in kilometers using Haversine formula with a road-correction factor (1.3x)
  /// This makes it closer to actual road distance without requiring a paid API.
  static Future<double?> distanceInKm(
      double lat1, double lng1, double lat2, double lng2) async {
    final airDistance = Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
    // Apply 1.3x correction factor to account for road turns/routes
    return airDistance * 1.3;
  }

  /// Calculate distance between two LatLng points in meters (FREE)
  static Future<double?> distanceBetweenLatLng(LatLng start, LatLng end) async {
    return Geolocator.distanceBetween(
            start.latitude, start.longitude, end.latitude, end.longitude);
  }

  /// Calculate bearing between two points in degrees
  static double bearingBetween(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.bearingBetween(lat1, lng1, lat2, lng2);
  }

  /// Calculate bearing between two positions in degrees
  static double bearingBetweenPositions(Position start, Position end) {
    return bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Check if a point is within a certain radius of another point
  static Future<bool> isWithinRadius(
    double centerLat,
    double centerLng,
    double pointLat,
    double pointLng,
    double radiusMeters,
  ) async {
    final distance = await RoadDistanceService.distanceBetweenCoordinates(
        centerLat, centerLng, pointLat, pointLng);
    if (distance == null) return false;
    return distance <= radiusMeters;
  }

  /// Calculate the midpoint between two coordinates
  static LatLng midpoint(double lat1, double lng1, double lat2, double lng2) {
    final lat1Rad = lat1 * (pi / 180);
    final lat2Rad = lat2 * (pi / 180);
    final lng1Rad = lng1 * (pi / 180);
    final lng2Rad = lng2 * (pi / 180);

    final bx = cos(lat2Rad) * cos(lng2Rad - lng1Rad);
    final by = cos(lat2Rad) * sin(lng2Rad - lng1Rad);

    final lat3Rad = atan2(sin(lat1Rad) + sin(lat2Rad),
        sqrt((cos(lat1Rad) + bx) * (cos(lat1Rad) + bx) + by * by));
    final lng3Rad = lng1Rad + atan2(by, cos(lat1Rad) + bx);

    return LatLng(lat3Rad * (180 / pi), lng3Rad * (180 / pi));
  }

  /// Format distance for display
  static String formatDistance(double meters, {bool useKm = true}) {
    if (useKm) {
      final km = meters / 1000;
      if (km < 1) {
        return '${meters.toStringAsFixed(0)} m';
      } else if (km < 10) {
        return '${km.toStringAsFixed(1)} km';
      } else {
        return '${km.toStringAsFixed(0)} km';
      }
    } else {
      if (meters < 1000) {
        return '${meters.toStringAsFixed(0)} m';
      } else {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
    }
  }

  /// Format speed for display
  static String formatSpeed(double speedMps) {
    final kmh = speedMps * 3.6;
    if (kmh < 1) {
      return '0 km/h';
    } else if (kmh < 10) {
      return '${kmh.toStringAsFixed(1)} km/h';
    } else {
      return '${kmh.toStringAsFixed(0)} km/h';
    }
  }

  /// Calculate estimated travel time based on distance and average speed
  static Duration estimateTravelTime(
      double distanceMeters, double avgSpeedKmh) {
    if (avgSpeedKmh <= 0) return Duration.zero;
    final timeHours = distanceMeters / (avgSpeedKmh * 1000);
    return Duration(seconds: (timeHours * 3600).round());
  }

  /// Check if coordinates are valid
  static bool areValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Check if a LatLng object contains valid coordinates
  static bool areValidLatLng(LatLng coordinates) {
    return areValidCoordinates(coordinates.latitude, coordinates.longitude);
  }

  /// Normalize coordinates to valid ranges
  static LatLng normalizeCoordinates(double latitude, double longitude) {
    double normalizedLat = latitude;
    double normalizedLng = longitude;

    // Normalize latitude
    while (normalizedLat > 90) {
      normalizedLat -= 180;
    }
    while (normalizedLat < -90) {
      normalizedLat += 180;
    }

    // Normalize longitude
    while (normalizedLng > 180) {
      normalizedLng -= 360;
    }
    while (normalizedLng < -180) {
      normalizedLng += 360;
    }

    return LatLng(normalizedLat, normalizedLng);
  }

  /// Calculate the area of a bounding box
  static double boundingBoxArea(LatLngBounds bounds) {
    final latDiff = bounds.northeast.latitude - bounds.southwest.latitude;
    final lngDiff = bounds.northeast.longitude - bounds.southwest.longitude;
    return latDiff * lngDiff;
  }

  /// Check if a point is inside a bounding box
  static bool isPointInBounds(LatLng point, LatLngBounds bounds) {
    return point.latitude >= bounds.southwest.latitude &&
        point.latitude <= bounds.northeast.latitude &&
        point.longitude >= bounds.southwest.longitude &&
        point.longitude <= bounds.northeast.longitude;
  }

  /// Create a bounding box around a point with given radius
  static LatLngBounds createBoundingBox(
      double centerLat, double centerLng, double radiusMeters) {
    final latChange = (radiusMeters / earthRadius) * (180 / pi);
    final lngChange =
        (radiusMeters / earthRadius) * (180 / pi) / cos(centerLat * pi / 180);

    final southWest = LatLng(centerLat - latChange, centerLng - lngChange);
    final northEast = LatLng(centerLat + latChange, centerLng + lngChange);

    return LatLngBounds(southwest: southWest, northeast: northEast);
  }

  /// Calculate the center of multiple coordinates
  static LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  /// Sort points by distance from a reference point
  static Future<List<LatLng>> sortByDistance(
      LatLng reference, List<LatLng> points) async {
    final pointsWithDistance = <MapEntry<LatLng, double>>[];

    for (final point in points) {
      final distance = await RoadDistanceService.distanceBetweenCoordinates(
        reference.latitude,
        reference.longitude,
        point.latitude,
        point.longitude,
      );
      pointsWithDistance.add(MapEntry(point, distance ?? double.infinity));
    }

    pointsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    return pointsWithDistance.map((e) => e.key).toList();
  }

  /// Filter points within a certain radius
  static Future<List<LatLng>> filterByRadius(
    LatLng center,
    List<LatLng> points,
    double radiusMeters,
  ) async {
    final filtered = <LatLng>[];
    for (final point in points) {
      final isWithin = await isWithinRadius(
        center.latitude,
        center.longitude,
        point.latitude,
        point.longitude,
        radiusMeters,
      );
      if (isWithin) filtered.add(point);
    }
    return filtered;
  }

  /// Calculate the total distance of a route
  static Future<double> calculateRouteDistance(List<LatLng> route) async {
    if (route.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < route.length - 1; i++) {
      final segment = await RoadDistanceService.distanceBetweenCoordinates(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
      totalDistance += segment ?? 0;
    }
    return totalDistance;
  }

  /// Simplify a route by removing points that are too close together
  static Future<List<LatLng>> simplifyRoute(
      List<LatLng> route, double minDistance) async {
    if (route.length < 2) return route;

    final simplified = <LatLng>[route.first];

    for (int i = 1; i < route.length; i++) {
      final last = simplified.last;
      final current = route[i];
      final distance = await RoadDistanceService.distanceBetweenCoordinates(
        last.latitude,
        last.longitude,
        current.latitude,
        current.longitude,
      );

      if (distance != null && distance >= minDistance) {
        simplified.add(current);
      }
    }

    return simplified;
  }

  /// Get a human-readable location accuracy description
  static String accuracyDescription(double accuracy) {
    if (accuracy < 10) return 'High';
    if (accuracy < 50) return 'Medium';
    if (accuracy < 100) return 'Low';
    return 'Poor';
  }
}
