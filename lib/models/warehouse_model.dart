import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';

class DeliveryChargeProfile {
  final String deliveryTypeApplied;
  final double baseDeliveryCharge;
  final double deliveryChargePerKm;
  final double fixedDeliveryCharge;
  final double fixedDeliveryChargeForKm;
  final double freeDeliveryThreshold;
  final int freeDeliveryDays;

  const DeliveryChargeProfile({
    this.deliveryTypeApplied = 'KM',
    this.baseDeliveryCharge = 0,
    this.deliveryChargePerKm = 0,
    this.fixedDeliveryCharge = 0,
    this.fixedDeliveryChargeForKm = 0,
    this.freeDeliveryThreshold = 0,
    this.freeDeliveryDays = 0,
  });

  factory DeliveryChargeProfile.fromMap(Map<String, dynamic> map) {
    return DeliveryChargeProfile(
      deliveryTypeApplied: map['deliveryTypeApplied'] as String? ?? 'KM',
      baseDeliveryCharge: (map['baseDeliveryCharge'] as num?)?.toDouble() ?? 0,
      deliveryChargePerKm:
          (map['deliveryChargePerKm'] as num?)?.toDouble() ?? 0,
      fixedDeliveryCharge:
          (map['fixedDeliveryCharge'] as num?)?.toDouble() ?? 0,
      fixedDeliveryChargeForKm:
          (map['fixedDeliveryChargeForKm'] as num?)?.toDouble() ??
              (map['fixedDeliveryChargeforKm'] as num?)?.toDouble() ??
              0,
      freeDeliveryThreshold:
          (map['freeDeliveryThreshold'] as num?)?.toDouble() ?? 0,
      freeDeliveryDays: (map['freeDeliveryDays'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryTypeApplied': deliveryTypeApplied,
      'baseDeliveryCharge': baseDeliveryCharge,
      'deliveryChargePerKm': deliveryChargePerKm,
      'fixedDeliveryCharge': fixedDeliveryCharge,
      'fixedDeliveryChargeForKm': fixedDeliveryChargeForKm,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'freeDeliveryDays': freeDeliveryDays,
    };
  }
}

class DeliveryBoyChargeProfile {
  final double baseDeliveryCharge;
  final double deliveryChargePerKm;
  final double fixedDeliveryCharge;
  final double fixedDeliveryChargeForKm;
  final double deliveryCharge;
  final double estimatedDeliveryBoyPayout;

  const DeliveryBoyChargeProfile({
    this.baseDeliveryCharge = 0,
    this.deliveryChargePerKm = 0,
    this.fixedDeliveryCharge = 0,
    this.fixedDeliveryChargeForKm = 0,
    this.deliveryCharge = 0,
    this.estimatedDeliveryBoyPayout = 0,
  });

  factory DeliveryBoyChargeProfile.fromMap(Map<String, dynamic> map) {
    return DeliveryBoyChargeProfile(
      baseDeliveryCharge: (map['baseDeliveryCharge'] as num?)?.toDouble() ?? 0,
      deliveryChargePerKm:
          (map['deliveryChargePerKm'] as num?)?.toDouble() ?? 0,
      fixedDeliveryCharge:
          (map['fixedDeliveryCharge'] as num?)?.toDouble() ?? 0,
      fixedDeliveryChargeForKm:
          (map['fixedDeliveryChargeForKm'] as num?)?.toDouble() ??
              (map['fixedDeliveryChargeforKm'] as num?)?.toDouble() ??
              0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      estimatedDeliveryBoyPayout:
          (map['estimatedDeliveryBoyPayout'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseDeliveryCharge': baseDeliveryCharge,
      'deliveryChargePerKm': deliveryChargePerKm,
      'fixedDeliveryCharge': fixedDeliveryCharge,
      'fixedDeliveryChargeForKm': fixedDeliveryChargeForKm,
      'deliveryCharge': deliveryCharge,
      'estimatedDeliveryBoyPayout': estimatedDeliveryBoyPayout,
    };
  }
}

class WarehouseDeliveryConfig {
  final DeliveryChargeProfile quick;
  final DeliveryChargeProfile scheduled;

  const WarehouseDeliveryConfig({
    this.quick = const DeliveryChargeProfile(),
    this.scheduled = const DeliveryChargeProfile(),
  });

  factory WarehouseDeliveryConfig.fromMap(Map<String, dynamic> map) {
    return WarehouseDeliveryConfig(
      quick: DeliveryChargeProfile.fromMap(
        Map<String, dynamic>.from(map['quick'] ?? const {}),
      ),
      scheduled: DeliveryChargeProfile.fromMap(
        Map<String, dynamic>.from(map['scheduled'] ?? const {}),
      ),
    );
  }

  DeliveryChargeProfile profileFor(DeliveryType deliveryType) {
    return deliveryType == DeliveryType.scheduled ? scheduled : quick;
  }

  Map<String, dynamic> toMap() {
    return {
      'quick': quick.toMap(),
      'scheduled': scheduled.toMap(),
    };
  }
}

class WarehouseDeliveryBoyConfig {
  final DeliveryBoyChargeProfile quick;
  final DeliveryBoyChargeProfile scheduled;

  const WarehouseDeliveryBoyConfig({
    this.quick = const DeliveryBoyChargeProfile(),
    this.scheduled = const DeliveryBoyChargeProfile(),
  });

  factory WarehouseDeliveryBoyConfig.fromMap(Map<String, dynamic> map) {
    return WarehouseDeliveryBoyConfig(
      quick: DeliveryBoyChargeProfile.fromMap(
        Map<String, dynamic>.from(map['quick'] ?? const {}),
      ),
      scheduled: DeliveryBoyChargeProfile.fromMap(
        Map<String, dynamic>.from(map['scheduled'] ?? const {}),
      ),
    );
  }

  DeliveryBoyChargeProfile profileFor(DeliveryType deliveryType) {
    return deliveryType == DeliveryType.scheduled ? scheduled : quick;
  }

  Map<String, dynamic> toMap() {
    return {
      'quick': quick.toMap(),
      'scheduled': scheduled.toMap(),
    };
  }
}

class WarehouseTaxConfig {
  final double gstPercentage;
  final double handlingCharge;
  final double paymentGatewayChargePercentage;
  final double platformCharge;

  const WarehouseTaxConfig({
    this.gstPercentage = 0,
    this.handlingCharge = 0,
    this.paymentGatewayChargePercentage = 0,
    this.platformCharge = 0,
  });

  factory WarehouseTaxConfig.fromMap(Map<String, dynamic> map) {
    return WarehouseTaxConfig(
      gstPercentage: (map['gstPercentage'] as num?)?.toDouble() ?? 0,
      handlingCharge: (map['handlingCharge'] as num?)?.toDouble() ?? 0,
      paymentGatewayChargePercentage:
          (map['paymentGatewayChargePercentage'] as num?)?.toDouble() ?? 0,
      platformCharge: (map['platformCharge'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gstPercentage': gstPercentage,
      'handlingCharge': handlingCharge,
      'paymentGatewayChargePercentage': paymentGatewayChargePercentage,
      'platformCharge': platformCharge,
    };
  }
}

class Warehouse implements FirestoreModel {
  @override
  final String? id;
  final String name;
  final String? imageUrl;
  final String updatedBy;
  final double latitude;
  final double longitude;
  final double quickdeliveryRadiusKm;
  final double scheduledDeliveryRadius;
  final bool isActive;
  final String openingTime;
  final String closingTime;
  final int minimumOrderValue;
  final int maximumOrderValue;
  final int maxItemsPerOrder;
  final bool autoAcceptOrders;
  final int orderAutoCancelTimeMinutes;
  final WarehouseDeliveryConfig deliveryConfig;
  final WarehouseDeliveryBoyConfig deliveryBoyConfig;
  final WarehouseTaxConfig taxConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Warehouse({
    this.id,
    required this.name,
    this.imageUrl,
    this.updatedBy = '',
    required this.latitude,
    required this.longitude,
    this.quickdeliveryRadiusKm = 5150,
    this.scheduledDeliveryRadius = 50500,
    this.isActive = false,
    this.openingTime = '05:00',
    this.closingTime = '23:30',
    this.minimumOrderValue = 0,
    this.maximumOrderValue = 0,
    this.maxItemsPerOrder = 50,
    this.autoAcceptOrders = false,
    this.orderAutoCancelTimeMinutes = 30,
    this.deliveryConfig = const WarehouseDeliveryConfig(),
    this.deliveryBoyConfig = const WarehouseDeliveryBoyConfig(),
    this.taxConfig = const WarehouseTaxConfig(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory Warehouse.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Warehouse(
      id: doc.id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      updatedBy: map['updatedBy'] ?? '',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      scheduledDeliveryRadius: parseDouble(map['scheduledDeliveryRadius'] ?? 3),
      quickdeliveryRadiusKm: parseDouble(map['quickdeliveryRadiusKm'] ?? 20),
      isActive: map['isActive'] ?? false,
      openingTime: map['openingTime'] ?? '05:00',
      closingTime: map['closingTime'] ?? '23:30',
      minimumOrderValue: (map['minimumOrderValue'] as num?)?.toInt() ?? 0,
      maximumOrderValue: (map['maximumOrderValue'] as num?)?.toInt() ?? 0,
      maxItemsPerOrder: (map['maxItemsPerOrder'] as num?)?.toInt() ?? 50,
      autoAcceptOrders: map['autoAcceptOrders'] ?? false,
      orderAutoCancelTimeMinutes: (map['orderAutoCancelTimeMinutes'] as num?)?.toInt() ?? 30,
      deliveryConfig: WarehouseDeliveryConfig.fromMap(
        Map<String, dynamic>.from(map['deliveryConfig'] ?? const {}),
      ),
      deliveryBoyConfig: WarehouseDeliveryBoyConfig.fromMap(
        Map<String, dynamic>.from(map['deliveryBoyConfig'] ?? const {}),
      ),
      taxConfig: WarehouseTaxConfig.fromMap(
        Map<String, dynamic>.from(map['taxConfig'] ?? const {}),
      ),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  DeliveryChargeProfile deliveryProfileFor(DeliveryType deliveryType) {
    return deliveryConfig.profileFor(deliveryType);
  }

  DeliveryBoyChargeProfile deliveryBoyProfileFor(DeliveryType deliveryType) {
    return deliveryBoyConfig.profileFor(deliveryType);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'minimumOrderValue': minimumOrderValue,
      'maximumOrderValue': maximumOrderValue,
      'maxItemsPerOrder': maxItemsPerOrder,
      'quickdeliveryRadiusKm': quickdeliveryRadiusKm,
      'scheduledDeliveryRadius': scheduledDeliveryRadius,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'autoAcceptOrders': autoAcceptOrders,
      'orderAutoCancelTimeMinutes': orderAutoCancelTimeMinutes,
      'isActive': isActive,
      'deliveryConfig': deliveryConfig.toMap(),
      'deliveryBoyConfig': deliveryBoyConfig.toMap(),
      'taxConfig': taxConfig.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }
}

DateTime _parseTimestamp(dynamic raw) {
  if (raw is Timestamp) {
    return raw.toDate();
  }

  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  if (raw is Map) {
    final seconds = raw['_seconds'] ?? raw['seconds'];
    if (seconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
  }

  return DateTime.now();
}
