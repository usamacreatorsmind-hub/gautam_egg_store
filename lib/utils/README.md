# Location Services Utils

This folder contains a comprehensive set of utilities for handling location services in Flutter applications, specifically designed for delivery and grocery item delivery apps.

## Files Overview

### Core Services

- **`location_manager.dart`** - Main unified interface for all location operations
- **`location_permissions.dart`** - Permission handling and GPS service checks
- **`location_service.dart`** - Current position retrieval and location streaming
- **`geocoding_service.dart`** - Address to coordinates conversion and reverse geocoding
- **`location_utils.dart`** - Distance calculations, coordinate utilities, and formatting
- **`location_tracking_service.dart`** - Background location tracking with Firebase integration
- **`location_models.dart`** - Data models for location data structures

## Quick Start

### 1. Initialize Location Services

```dart
import 'package:your_app/utils/location_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize location services
  await LocationManager().initialize();

  runApp(MyApp());
}
```

### 2. Get Current Location

```dart
import 'package:your_app/utils/location_manager.dart';

final locationManager = LocationManager();

// Get current location with address
final currentLocation = await locationManager.getCurrentLocationWithAddress();
if (currentLocation != null) {
  print('Current location: ${currentLocation.latitude}, ${currentLocation.longitude}');
  print('Address: ${currentLocation.fullAddress}');
}
```

### 3. Start Delivery Tracking

```dart
import 'package:your_app/utils/location_manager.dart';

final locationManager = LocationManager();

// Start tracking for delivery
final result = await locationManager.startDeliveryTracking();
if (result == LocationStartResult.started) {
  print('Location tracking started');
} else {
  print('Failed to start tracking: $result');
}

// Stop tracking when delivery is complete
await locationManager.stopDeliveryTracking();
```

### 4. Geocode Addresses

```dart
import 'package:your_app/utils/location_manager.dart';

final locationManager = LocationManager();

// Convert address to coordinates
final pickupLocation = await locationManager.geocodeAddress('123 Main St, City, State');
if (pickupLocation != null) {
  print('Pickup coordinates: ${pickupLocation.latitude}, ${pickupLocation.longitude}');
}

// Convert coordinates to address
final address = await locationManager.reverseGeocode(LatLng(37.7749, -122.4194));
print('Address: $address');
```

### 5. Calculate Distances

```dart
import 'package:your_app/utils/location_manager.dart';

final locationManager = LocationManager();

// Calculate distance between two locations
final distance = locationManager.calculateDistance(location1, location2);
print('Distance: ${locationManager.formatDistance(distance)}');

// Check if within radius
final isNearby = locationManager.isWithinRadius(centerLocation, targetLocation, 1000); // 1km
```

## Advanced Usage

### Custom Tracking Configuration

```dart
import 'package:your_app/utils/location_manager.dart';

final config = LocationTrackingConfig(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 5, // Update every 5 meters
  updateInterval: Duration(seconds: 15), // Firebase update interval
  enableBackgroundTracking: true,
  saveToFirebase: true,
);

await locationManager.startDeliveryTracking(config: config);
```

### Working with Delivery Locations

```dart
import 'package:your_app/utils/location_manager.dart';

// Create delivery location from order data
final deliveryLocation = locationManager.createDeliveryLocation(orderData);
if (deliveryLocation != null) {
  print('Pickup: ${deliveryLocation.pickup.fullAddress}');
  print('Drop: ${deliveryLocation.drop.fullAddress}');
  print('Distance: ${locationManager.formatDistance(deliveryLocation.distanceInKm * 1000)}');
}
```

### Route Calculations

```dart
import 'package:your_app/utils/location_manager.dart';

final routePoints = [point1, point2, point3, point4];

// Calculate total route distance
final totalDistance = locationManager.calculateRouteDistance(routePoints);

// Simplify route by removing close points
final simplifiedRoute = locationManager.simplifyRoute(routePoints, 10); // 10 meters minimum
```

## Permission Handling

The location services handle permissions automatically, but you can also check and request permissions manually:

```dart
import 'package:your_app/utils/location_manager.dart';

final locationManager = LocationManager();

// Check if location is available
final isAvailable = await locationManager.isLocationAvailable();

// Request permissions
final granted = await locationManager.requestLocationPermissions();
```

## Data Models

### LocationData
Represents a location with coordinates and address information.

```dart
final location = LocationData(
  latitude: 37.7749,
  longitude: -122.4194,
  address: '123 Main St',
  city: 'San Francisco',
  accuracy: 5.0,
);
```

### DeliveryLocation
Represents a delivery with pickup and drop locations.

```dart
final delivery = DeliveryLocation(
  pickup: pickupLocation,
  drop: dropLocation,
  distanceKm: 5.2,
);
```

### RiderLocation
Represents a rider's location with tracking information.

```dart
final riderLocation = RiderLocation(
  riderId: 'rider123',
  latitude: 37.7749,
  longitude: -122.4194,
  isOnDelivery: true,
);
```

## Dependencies Required

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^14.0.2
  geocoding: ^4.0.0
  google_maps_flutter: ^2.12.3
  permission_handler: ^11.0.1
  cloud_firestore: ^6.1.0
  firebase_auth: ^6.1.2
  flutter_foreground_task: ^8.0.0
```

## Error Handling

All methods return null or false on failure. Check the results and handle errors appropriately:

```dart
final location = await locationManager.getCurrentLocationWithAddress();
if (location == null) {
  // Handle location unavailable
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Location Required'),
      content: Text('Please enable location services to continue.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## Best Practices

1. **Initialize early**: Call `LocationManager().initialize()` in `main()` before `runApp()`
2. **Handle permissions**: Always check permission results and provide user feedback
3. **Background tracking**: Use appropriate accuracy settings to balance battery life and accuracy
4. **Error handling**: Always check for null results and handle failures gracefully
5. **Firebase integration**: Ensure Firebase is properly configured for location saving
6. **UI feedback**: Show loading indicators during geocoding operations

## Troubleshooting

### Common Issues

1. **Permissions denied**: Check device settings and request permissions again
2. **GPS disabled**: Prompt user to enable location services
3. **Geocoding failures**: Check internet connection and API key validity
4. **Background tracking not working**: Ensure foreground service permissions on Android

### Debug Logging

Enable detailed logging by setting:

```dart
// In location_service.dart, location_tracking_service.dart
print('Location update: $position');
```

## Migration from Existing Code

If migrating from existing location code:

1. Replace direct `Geolocator` calls with `LocationManager().location`
2. Replace geocoding calls with `LocationManager().geocoding`
3. Replace permission checks with `LocationManager().permissions`
4. Update tracking calls to use `LocationManager().tracking`

This modular approach makes it easy to maintain and extend location functionality across your delivery app.