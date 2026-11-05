import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sure_wholesaler/core/constants/app_credentials.dart';
import 'package:sure_wholesaler/utils/location_base_classes/geocoding_service.dart';

class RoadRouteInfo {
  RoadRouteInfo({
    this.distanceMeters,
    this.durationSeconds,
    this.distanceText,
    this.durationText,
    this.origin,
    this.destination,
    this.encodedPolyline,
    this.polylinePoints,
    this.steps,
  });

  double? distanceMeters;
  double? durationSeconds;
  String? distanceText;
  String? durationText;
  LatLng? origin;
  LatLng? destination;
  String? encodedPolyline;
  List<LatLng>? polylinePoints;
  List<dynamic>? steps;
}

class RoadDistanceService {
  static bool _hasLoggedDirectionsDenial = false;

  static String get _googleApiKey =>
      AppCredentials.defaults.googleWebServiceApiKey.isNotEmpty
          ? AppCredentials.defaults.googleWebServiceApiKey
          : AppCredentials.defaults.googleMapApiKey;

  static void _logDirectionsDeniedOnce(String? message) {
    if (_hasLoggedDirectionsDenial) return;
    _hasLoggedDirectionsDenial = true;
    debugPrint(
      '[RoadDistanceService] Directions API denied. '
              'Check `AppCredentials.googleWebServiceApiKey` or enable the Directions API. '
              '${message ?? ''}'
          .trim(),
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];

    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);

      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);

      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  // static Future<RoadRouteInfo?> routeBetweenCoordinates(
  //   LatLng origin,
  //   LatLng destination,
  // ) async {
  //   try {
  //     if (_googleApiKey.isEmpty) {
  //       debugPrint(
  //         '[RoadDistanceService] Missing Google API key. Cannot fetch directions route.',
  //       );
  //       return null;
  //     }

  //     final queryParameters = {
  //       'origin': '${origin.latitude},${origin.longitude}',
  //       'destination': '${destination.latitude},${destination.longitude}',
  //       'mode': 'driving',
  //       'alternatives': 'true',
  //       'key': _googleApiKey,
  //     };

  //     final url = Uri.https(
  //       'maps.googleapis.com',
  //       '/maps/api/directions/json',
  //       queryParameters,
  //     );

  //     final response = await http.get(url).timeout(
  //           const Duration(seconds: 15),
  //           onTimeout: () => throw Exception(
  //             'Directions API timeout - Check internet connection',
  //           ),
  //         );

  //     if (response.statusCode != 200) {
  //       debugPrint(
  //         '[RoadDistanceService] Directions API HTTP error: ${response.statusCode}',
  //       );
  //       return null;
  //     }

  //     final data = json.decode(response.body) as Map<String, dynamic>;
  //     final status = data['status'] as String?;

  //     if (status != 'OK') {
  //       if (status == 'REQUEST_DENIED') {
  //         _logDirectionsDeniedOnce(data['error_message'] as String?);
  //       } else {
  //         debugPrint(
  //           '[RoadDistanceService] Directions API error: $status - ${data['error_message'] ?? ''}',
  //         );
  //       }
  //       return null;
  //     }

  //     final routes = data['routes'] as List?;
  //     if (routes == null || routes.isEmpty) return null;

  //     Map<String, dynamic>? shortestRoute;
  //     Map<String, dynamic>? shortestLeg;
  //     double shortestDistance = double.infinity;

  //     for (final routeEntry in routes) {
  //       final route = routeEntry as Map<String, dynamic>;
  //       final legs = route['legs'] as List?;
  //       if (legs == null || legs.isEmpty) continue;

  //       final leg = legs.first as Map<String, dynamic>;
  //       final distanceMap = leg['distance'] as Map<String, dynamic>?;
  //       final durationMap = leg['duration'] as Map<String, dynamic>?;
  //       if (distanceMap == null || durationMap == null) continue;

  //       final distance = (distanceMap['value'] as num).toDouble();
  //       if (distance < shortestDistance) {
  //         shortestDistance = distance;
  //         shortestRoute = route;
  //         shortestLeg = leg;
  //       }
  //     }

  //     if (shortestRoute == null || shortestLeg == null) return null;

  //     final overviewPolyline =
  //         shortestRoute['overview_polyline'] as Map<String, dynamic>?;
  //     final encodedPolyline = overviewPolyline?['points'] as String? ?? '';
  //     final distanceMap = shortestLeg['distance'] as Map<String, dynamic>;
  //     final durationMap = shortestLeg['duration'] as Map<String, dynamic>;

  //     return RoadRouteInfo(
  //       distanceMeters: (distanceMap['value'] as num).toDouble(),
  //       durationSeconds: (durationMap['value'] as num).toDouble(),
  //       distanceText: distanceMap['text'] as String? ?? '',
  //       durationText: durationMap['text'] as String? ?? '',
  //       origin: origin,
  //       destination: destination,
  //       encodedPolyline: encodedPolyline,
  //       polylinePoints: _decodePolyline(encodedPolyline),
  //       steps: List<dynamic>.from(shortestLeg['steps'] as List? ?? const []),
  //     );
  //   } catch (e) {
  //     debugPrint('[RoadDistanceService] routeBetweenCoordinates error: $e');
  //     return null;
  //   }
  // }

  /// Calculate distance between coordinates in meters
  static Future<double?> distanceBetweenCoordinates(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) async {
    try {
      final route = await routeBetweenCoordinates(
        LatLng(lat1, lng1),
        LatLng(lat2, lng2),
      );
      if (route != null) return route.distanceMeters;

      debugPrint('[RoadDistanceService] Directions route unavailable.');
      return null;
    } catch (e) {
      debugPrint('[RoadDistanceService] distanceBetweenCoordinates error: $e');
      return null;
    }
  }

  // /// Convert address to coordinates using Google Maps API
  // static Future<GeocodingResult> addressToCoordinates(String address) async {
  //   try {
  //     if (address.trim().isEmpty) {
  //       return GeocodingResult.failure('Address cannot be empty');
  //     }

  //     final encodedAddress = Uri.encodeComponent(address.trim());
  //     final url = Uri.parse(
  //       'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$_googleApiKey',
  //     );

  //     final response = await http.get(url).timeout(
  //           const Duration(seconds: 10),
  //           onTimeout: () => throw Exception(
  //               'Geocoding timeout - Please check your internet connection'),
  //         );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       if (data['status'] == 'OK' && data['results'].isNotEmpty) {
  //         final location = data['results'][0]['geometry']['location'];
  //         final latLng = LatLng(
  //           location['lat'].toDouble(),
  //           location['lng'].toDouble(),
  //         );
  //         final formattedAddress =
  //             data['results'][0]['formatted_address'] as String;

  //         return GeocodingResult.success(latLng, formattedAddress);
  //       } else if (data['status'] == 'ZERO_RESULTS') {
  //         return GeocodingResult.failure('Location not found: $address');
  //       } else if (data['status'] == 'REQUEST_DENIED') {
  //         return GeocodingResult.failure(
  //             'API Key error - Please check your Google Maps API key and enable Geocoding API');
  //       } else if (data['status'] == 'OVER_QUERY_LIMIT') {
  //         return GeocodingResult.failure(
  //             'API quota exceeded - Please try again later');
  //       } else {
  //         return GeocodingResult.failure('Geocoding failed: ${data['status']}');
  //       }
  //     } else {
  //       return GeocodingResult.failure('Server error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     return GeocodingResult.failure('Geocoding error: $e');
  //   }
  // }

  static Future<RoadRouteInfo> routeBetweenCoordinates(
      LatLng latLng, LatLng latLng2) async {
// fetch straight line distance using Haversine formula as a fallback
    final distance = Geolocator.distanceBetween(
      latLng.latitude,
      latLng.longitude,
      latLng2.latitude,
      latLng2.longitude,
    );

    return RoadRouteInfo(
      distanceMeters: distance,
      durationSeconds: 0,
      distanceText: '',
      durationText: '',
      origin: latLng,
      destination: latLng2,
      encodedPolyline: '',
      polylinePoints: [],
      steps: [],
    );
  }
}
