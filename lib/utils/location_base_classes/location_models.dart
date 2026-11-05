import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sure_wholesaler/models/address_model.dart';

/// Represents a location with coordinates and address information
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime? timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.timestamp,
  });

  /// Create from LatLng
  factory LocationData.fromLatLng(LatLng latLng) {
    return LocationData(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }

  /// Create from Firebase data
  factory LocationData.fromFirebase(Map<String, dynamic> data) {
    return LocationData(
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['district'] as String?, // Firebase uses 'district' for state
      country: data['country'] as String?,
      postalCode: data['pincode'] as String?,
      accuracy: data['accuracy']?.toDouble(),
      altitude: data['altitude']?.toDouble(),
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.tryParse(data['timestamp'])
          : null,
    );
  }

  /// Convert to LatLng
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toFirebase() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'district': state, // Firebase uses 'district'
      if (country != null) 'country': country,
      if (postalCode != null) 'pincode': postalCode,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if location is valid
  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Format coordinates for display
  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  /// Get full address string
  String get fullAddress {
    final components = [address, city, state, postalCode, country]
        .where((component) => component != null && component.isNotEmpty)
        .toList();
    return components.join(', ');
  }

  /// Convert to UserAddressModel for delivery addresses
  UserAddressModel toUserAddressModel({
    required String userId,
    String name = 'Current Location',
    String phone = '',
    bool isDefault = false,
  }) {
    return UserAddressModel(
      userId: userId,
      name: name,
      address: address ?? '',
      city: city ?? '',
      state: state ?? '',
      pinCode: postalCode ?? '',
      country: country ?? 'India',
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationData &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Represents a delivery location with pickup and drop points
class DeliveryLocation {
  final LocationData pickup;
  final LocationData drop;
  final double? distanceKm;
  final Duration? estimatedDuration;

  const DeliveryLocation({
    required this.pickup,
    required this.drop,
    this.distanceKm,
    this.estimatedDuration,
  });

  /// Calculate distance if not provided
  double get distanceInKm {
    if (distanceKm != null) return distanceKm!;
    return 0.0; // Distance should be resolved via road distance service
  }

  /// Create from Firebase order data
  factory DeliveryLocation.fromOrderData(Map<String, dynamic> orderData) {
    // Extract pickup location (vendor)
    final vendorLat = _extractCoordinate(orderData, [
      'vendorLatitude',
      'latitude',
      'vendorLocation.latitude',
      'location.latitude'
    ]);
    final vendorLng = _extractCoordinate(orderData, [
      'vendorLongitude',
      'longitude',
      'vendorLocation.longitude',
      'location.longitude'
    ]);

    // Extract drop location (user)
    final userLat = _extractCoordinate(orderData, [
      'userLatitude',
      'dropLatitude',
      'userLocation.latitude',
      'deliveryLocation.latitude',
      'addressLocation.latitude'
    ]);
    final userLng = _extractCoordinate(orderData, [
      'userLongitude',
      'dropLongitude',
      'userLocation.longitude',
      'deliveryLocation.longitude',
      'addressLocation.longitude'
    ]);

    final pickup = LocationData(
      latitude: vendorLat ?? 0.0,
      longitude: vendorLng ?? 0.0,
      address: orderData['pickupAddress'] as String?,
    );

    final drop = LocationData(
      latitude: userLat ?? 0.0,
      longitude: userLng ?? 0.0,
      address: orderData['dropAddress'] as String?,
    );

    final distanceKm = orderData['deliveryDistanceKm']?.toDouble();

    return DeliveryLocation(
      pickup: pickup,
      drop: drop,
      distanceKm: distanceKm,
    );
  }

  static double? _extractCoordinate(
      Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _getNestedValue(data, key);
      if (value != null) {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value);
      }
    }
    return null;
  }

  static dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic current = data;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current;
  }
}

/// Represents rider location with additional tracking information
class RiderLocation extends LocationData {
  final String riderId;
  final bool isOnDelivery;
  final DateTime? lastLocationUpdate;
  final double? batteryLevel;

  const RiderLocation({
    required this.riderId,
    required super.latitude,
    required super.longitude,
    super.address,
    super.city,
    super.state,
    super.country,
    super.postalCode,
    super.accuracy,
    super.altitude,
    super.speed,
    super.heading,
    super.timestamp,
    this.isOnDelivery = false,
    this.lastLocationUpdate,
    this.batteryLevel,
  });

  /// Create from Firebase boyInfo data
  factory RiderLocation.fromFirebase(
      String riderId, Map<String, dynamic> data) {
    return RiderLocation(
      riderId: riderId,
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['district'] as String?,
      country: data['country'] as String?,
      postalCode: data['pincode'] as String?,
      accuracy: data['accuracy']?.toDouble(),
      altitude: data['altitude']?.toDouble(),
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.tryParse(data['timestamp'])
          : null,
      isOnDelivery: data['isOnDelivery'] as bool? ?? false,
      lastLocationUpdate: data['lastLocationUpdate'] != null
          ? (data['lastLocationUpdate'] as Timestamp?)?.toDate()
          : null,
      batteryLevel: data['batteryLevel']?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toFirebase() {
    final baseData = super.toFirebase();
    return {
      ...baseData,
      'riderId': riderId,
      'isOnDelivery': isOnDelivery,
      if (lastLocationUpdate != null)
        'lastLocationUpdate': Timestamp.fromDate(lastLocationUpdate!),
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
    };
  }
}
