import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_manager.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_models.dart';
import 'package:tuple/tuple.dart';

export 'package:sure_wholesaler/utils/location_base_classes/location_permissions.dart';
export 'package:sure_wholesaler/utils/location_base_classes/location_models.dart';
export 'package:sure_wholesaler/utils/location_base_classes/location_manager.dart';

final locationInitlializerProvider = FutureProvider<void>((ref) async {
  final locationManager = LocationManager();
  await locationManager.initialize().first;
});

final currentLocationProvider = StreamProvider<LocationData?>((ref) {
  final locationManager = LocationManager();
  return locationManager.getCurrentLocationWithAddress();
});

/// Provider for a manually selected location by the user.
final manualLocationProvider = StateProvider<LocationData?>((ref) => null);

/// The effective location that the app should use, prioritizing manual selection.
final effectiveLocationProvider = Provider<LocationData?>((ref) {
  final manualLocation = ref.watch(manualLocationProvider);
  if (manualLocation != null) return manualLocation;

  return ref.watch(currentLocationProvider).asData?.value;
});

final watchCurrentLocationProvider = StreamProvider<LocationData?>((ref) {
  final locationManager = LocationManager();
  return locationManager.watchCurrentLocationWithAddress();
});

// road distance between coordinates using Google Maps API
final roadDistanceBetweenCoordinatesProvider =
    StreamProvider.family<double?, Tuple2<LatLng, LatLng>>((ref, coordinates) {
  final locationManager = LocationManager();
  return locationManager.geocoding.watchRoadDistanceBetweenCoordinates(
      coordinates.item1, coordinates.item2);
});
