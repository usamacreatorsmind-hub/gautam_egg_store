import 'dart:convert';
import 'dart:math';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sure_wholesaler/core/constants/app_credentials.dart';
import 'package:sure_wholesaler/utils/location_base_classes/road_distance_service.dart';

/// Result of geocoding operation
class GeocodingResult {
  final bool success;
  final LatLng? coordinates;
  final String? address;
  final String? error;

  GeocodingResult({
    required this.success,
    this.coordinates,
    this.address,
    this.error,
  });

  factory GeocodingResult.success(LatLng coordinates, String address) {
    return GeocodingResult(
      success: true,
      coordinates: coordinates,
      address: address,
    );
  }

  factory GeocodingResult.failure(String error) {
    return GeocodingResult(
      success: false,
      error: error,
    );
  }
}

/// Service for geocoding operations (address to coordinates and reverse)
///
/// this is base class
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  // Stream<GeocodingResult> watchAddressToCoordinates(String address) {
  //   return Stream.fromFuture(RoadDistanceService.addressToCoordinates(address));
  // }

  Stream<GeocodingResult> watchCoordinatesToAddress(LatLng coordinates) {
    return Stream.fromFuture(coordinatesToAddress(coordinates));
  }

  Stream<GeocodingResult> watchAddressToCoordinatesFallback(String address) {
    return Stream.fromFuture(addressToCoordinatesFallback(address));
  }

  Stream<double?> watchRoadDistanceBetweenCoordinates(
      LatLng origin, LatLng destination) {
    return Stream.fromFuture(() async {
      final roadDistance = await RoadDistanceService.distanceBetweenCoordinates(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );
      return roadDistance ??
          Geolocator.distanceBetween(origin.latitude, origin.longitude,
              destination.latitude, destination.longitude);
    }());
  }

  /// Convert coordinates to address using geocoding package
  Future<GeocodingResult> coordinatesToAddress(LatLng coordinates) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddressFromPlacemark(place);
        return GeocodingResult.success(coordinates, address);
      } else {
        return GeocodingResult.failure(
            'No address found for these coordinates');
      }
    } catch (e) {
      return GeocodingResult.failure('Reverse geocoding error: $e');
    }
  }

  /// Convert address to coordinates using geocoding package (fallback)
  Future<GeocodingResult> addressToCoordinatesFallback(String address) async {
    try {
      if (address.trim().isEmpty) {
        return GeocodingResult.failure('Address cannot be empty');
      }

      final locations = await geocoding.locationFromAddress(address.trim());

      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        // Get formatted address
        final placemarks = await geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        String formattedAddress = address;
        if (placemarks.isNotEmpty) {
          formattedAddress = _formatAddressFromPlacemark(placemarks.first);
        }

        return GeocodingResult.success(latLng, formattedAddress);
      } else {
        return GeocodingResult.failure('Location not found: $address');
      }
    } catch (e) {
      return GeocodingResult.failure('Geocoding error: $e');
    }
  }

  // /// Batch geocode multiple addresses
  // Future<List<GeocodingResult>> batchGeocode(List<String> addresses) async {
  //   final results = <GeocodingResult>[];

  //   for (final address in addresses) {
  //     final result = await RoadDistanceService.addressToCoordinates(address);
  //     results.add(result);

  //     // Add small delay to avoid rate limiting
  //     await Future.delayed(const Duration(milliseconds: 100));
  //   }

  //   return results;
  // }

  /// Format address from placemark
  String _formatAddressFromPlacemark(geocoding.Placemark place) {
    final components = [
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.postalCode,
      place.country,
    ].where((component) => component != null && component.isNotEmpty).toList();

    return components.join(', ');
  }

  /// Extract address components from placemark
  Map<String, String> extractAddressComponents(geocoding.Placemark place) {
    return {
      'street': place.street ?? '',
      'subLocality': place.subLocality ?? '',
      'locality': place.locality ?? '',
      'subAdministrativeArea': place.subAdministrativeArea ?? '',
      'administrativeArea': place.administrativeArea ?? '',
      'postalCode': place.postalCode ?? '',
      'country': place.country ?? '',
      'isoCountryCode': place.isoCountryCode ?? '',
    };
  }

  /// Validate if coordinates are within reasonable bounds
  bool areValidCoordinates(LatLng coordinates) {
    return coordinates.latitude >= -90 &&
        coordinates.latitude <= 90 &&
        coordinates.longitude >= -180 &&
        coordinates.longitude <= 180;
  }
}
