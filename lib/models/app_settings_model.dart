class DeliverySlab {
  final double charge;
  final double upToKm;

  DeliverySlab({required this.charge, required this.upToKm});

  factory DeliverySlab.fromMap(Map<String, dynamic> map) {
    return DeliverySlab(
      // Converting Rupee to Paisa immediately
      charge: (map['charge'] as num? ?? 0).toDouble() * 100,
      upToKm: (map['upToKm'] as num? ?? 0).toDouble(),
    );
  }
}

class OrderSurcharge {
  final double aboveSubtotal;
  final double charge;

  OrderSurcharge({required this.aboveSubtotal, required this.charge});

  factory OrderSurcharge.fromMap(Map<String, dynamic> map) {
    return OrderSurcharge(
      aboveSubtotal: (map['aboveSubtotal'] as num? ?? 0).toDouble() * 100,
      charge: (map['charge'] as num? ?? 0).toDouble() * 100,
    );
  }
}

class AppSettingsModel {
  final bool allowCod;
  final String businessAddress;
  final String defaultCurrency;
  final List<DeliverySlab> deliveryDistanceSlabs;
  final bool enableSlot1;
  final bool enableSlot2;
  final bool enableSlot3;
  final double flatDeliveryCharge;
  final String gstin;
  final double handlingCharge; // Packing Fee
  final double latitude;
  final double longitude;
  final int lowStockAlertThreshold;
  final bool maintenanceMode;
  final double maxDeliveryRadiusKm;
  final int minBulkOrderQty;
  final double minOrderForFreeDelivery;
  final List<String> operatingDays;
  final bool orderEmailAlerts;
  final List<OrderSurcharge> orderValueSurcharges;
  final double platformFee;
  final bool sendSmsNotifications;
  final String storeEmail;
  final String storeName;
  final String supportPhone;
  final double taxRate;

  AppSettingsModel({
    required this.allowCod,
    required this.businessAddress,
    required this.defaultCurrency,
    required this.deliveryDistanceSlabs,
    required this.enableSlot1,
    required this.enableSlot2,
    required this.enableSlot3,
    required this.flatDeliveryCharge,
    required this.gstin,
    required this.handlingCharge,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.lowStockAlertThreshold,
    required this.maintenanceMode,
    required this.maxDeliveryRadiusKm,
    required this.minBulkOrderQty,
    required this.minOrderForFreeDelivery,
    required this.operatingDays,
    required this.orderEmailAlerts,
    required this.orderValueSurcharges,
    required this.platformFee,
    required this.sendSmsNotifications,
    required this.storeEmail,
    required this.storeName,
    required this.supportPhone,
    required this.taxRate,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Factory to convert Firestore JSON to Model with Paisa conversion for Charges
  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      allowCod: map['allowCod'] as bool? ?? true,
      businessAddress: map['businessAddress'] as String? ?? '',
      defaultCurrency: map['defaultCurrency'] as String? ?? 'inr',
      deliveryDistanceSlabs: (map['deliveryDistanceSlabs'] as List? ?? [])
          .map((e) => DeliverySlab.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      enableSlot1: map['enableSlot1'] as bool? ?? true,
      enableSlot2: map['enableSlot2'] as bool? ?? true,
      enableSlot3: map['enableSlot3'] as bool? ?? true,
      flatDeliveryCharge: (map['flatDeliveryCharge'] as num? ?? 0).toDouble(),
      gstin: map['gstin'] as String? ?? '',
      // Converting Rupee values from Firebase to Paisa for internal app logic
      handlingCharge: (map['handlingCharge'] as num? ?? 0).toDouble() * 100,
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      lowStockAlertThreshold: (map['lowStockAlertThreshold'] as num? ?? 10).toInt(),
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      maxDeliveryRadiusKm: (map['maxDeliveryRadiusKm'] as num? ?? 10).toDouble(),
      minBulkOrderQty: (map['minBulkOrderQty'] as num? ?? 5).toInt(),
      minOrderForFreeDelivery: (map['minOrderForFreeDelivery'] as num? ?? 0).toDouble() * 100,
      operatingDays: List<String>.from(map['operatingDays'] ?? []),
      orderEmailAlerts: map['orderEmailAlerts'] as bool? ?? true,
      orderValueSurcharges: (map['orderValueSurcharges'] as List? ?? [])
          .map((e) => OrderSurcharge.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      platformFee: (map['platformFee'] as num? ?? 0).toDouble() * 100,
      sendSmsNotifications: map['sendSmsNotifications'] as bool? ?? true,
      storeEmail: map['storeEmail'] as String? ?? '',
      storeName: map['storeName'] as String? ?? 'Gautam Egg Store',
      supportPhone: map['supportPhone'] as String? ?? '',
      taxRate: (map['taxRate'] as num? ?? 0).toDouble(),
    );
  }

  /// Default configuration for safety
  static AppSettingsModel get defaults => AppSettingsModel(
        allowCod: true,
        businessAddress: '',
        defaultCurrency: 'inr',
        deliveryDistanceSlabs: [],
        enableSlot1: true,
        enableSlot2: true,
        enableSlot3: true,
        flatDeliveryCharge: 2000,
        gstin: '',
        handlingCharge: 500,
        latitude: 25.3915667,
        longitude: 84.8564986,
        lowStockAlertThreshold: 10,
        maintenanceMode: false,
        maxDeliveryRadiusKm: 10,
        minBulkOrderQty: 5,
        minOrderForFreeDelivery: 200000,
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        orderEmailAlerts: true,
        orderValueSurcharges: [],
        platformFee: 500,
        sendSmsNotifications: true,
        storeEmail: '',
        storeName: 'Gautam Egg Store',
        supportPhone: '',
        taxRate: 5,
      );
}
