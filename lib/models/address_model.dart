// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_models.dart';

class UserAddressModel {
  String? id;
  String userId;

  // Display name
  String name;

  // Address text
  String address; // house no + street
  String locality; // area / locality
  String subLocality; // block / sector
  String district;
  String city;
  String state;
  String pinCode;
  String country;

  // Contact
  String phone;

  // Geo (for rider navigation)
  double latitude;
  double longitude;

  // Meta
  bool isDefault;
  DateTime createdAt;
  DateTime updatedAt;

  String fullAddress() {
    final parts = <String>[
      name,
      address,
      subLocality,
      locality,
      district,
      city,
      state,
      pinCode,
      country,
    ];

    // Remove empty or null values and join nicely
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }

  UserAddressModel({
    this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.phone,
    this.locality = '',
    this.subLocality = '',
    this.district = '',
    this.country = 'India',
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 🔹 FULL ADDRESS STRING (use anywhere in UI)
  // String get fullAddress {
  //   return [
  //     address,
  //     if (subLocality.isNotEmpty) subLocality,
  //     if (locality.isNotEmpty) locality,
  //     if (district.isNotEmpty) district,
  //     '$city - $pinCode',
  //     state,
  //     country,
  //   ].join(', ');
  // }

  // 🔹 Firestore map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'locality': locality,
      'subLocality': subLocality,
      'district': district,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'country': country,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 🔹 From Firestore map (BACKWARD COMPATIBLE)
  factory UserAddressModel.fromMap(Map<String, dynamic> map) {
    return UserAddressModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      locality: map['locality'] ?? '',
      subLocality: map['subLocality'] ?? '',
      district: map['district'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      country: map['country'] ?? 'India',
      phone: map['phone'] ?? '',
      latitude: (map['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0.0).toDouble(),
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Empty address for fallback
  factory UserAddressModel.empty() {
    return UserAddressModel(
      userId: '',
      name: '',
      address: '',
      pinCode: '',
      latitude: 0.0,
      longitude: 0.0,
      country: 'India',
      locality: '',
      subLocality: '',
      district: '',
      city: '',
      state: '',
      phone: '',
    );
  }

  // 🔹 CopyWith
  UserAddressModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    String? locality,
    String? subLocality,
    String? district,
    UserModel? user,
    String? city,
    String? state,
    String? pinCode,
    String? country,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      locality: locality ?? this.locality,
      subLocality: subLocality ?? this.subLocality,
      district: district ?? this.district,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to LocationData for GPS operations
  LocationData toLocationData() {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      address: fullAddress(),
      city: city,
      state: state,
      country: country,
      postalCode: pinCode,
    );
  }
}

class FullDeliveryAddress {
  final UserAddressModel address;
  final UserModel user;
  FullDeliveryAddress({
    required this.address,
    required this.user,
  });

  FullDeliveryAddress copyWith({
    UserAddressModel? address,
    UserModel? user,
  }) {
    return FullDeliveryAddress(
      address: address ?? this.address,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address': address.toMap(),
      'user': user.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  factory FullDeliveryAddress.fromJson(String source) =>
      FullDeliveryAddress.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'FullDeliveryAddress(address: $address, user: $user)';

  @override
  bool operator ==(covariant FullDeliveryAddress other) {
    if (identical(this, other)) return true;

    return other.address == address && other.user == user;
  }

  @override
  int get hashCode => address.hashCode ^ user.hashCode;

  factory FullDeliveryAddress.fromMap(Map<String, dynamic> map) {
    return FullDeliveryAddress(
      address: UserAddressModel.fromMap(map['address'] as Map<String, dynamic>),
      user: UserModel.fromMap(map['user'] as Map<String, dynamic>,
          FirebaseAuth.instance.currentUser!.uid),
    );
  }
}
