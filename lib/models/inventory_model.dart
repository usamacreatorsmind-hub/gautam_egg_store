import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';

class Inventory {
  final String id;
  final String warehouseId;
  final String variantId;

  final int stock;
  final bool isAvailable;

  /// Low-stock alert threshold (in packs). Alerts fire when stock <= this value.
  final int minStockAlert;

  /// Which delivery types are available for this variant at this warehouse.
  final List<DeliveryType> availableDeliveryTypes;

  /// Subset of availableDeliveryTypes that support subscription orders.
  final List<DeliveryType> subscriptionDeliveryTypes;

  /// Source of truth for delivery behavior per type at this warehouse.
  final Map<DeliveryType, DeliveryConfig> deliveryConfig;

  final DateTime updatedAt;
  final DateTime? createdAt;

  Inventory({
    required this.id,
    required this.warehouseId,
    required this.variantId,
    required this.stock,
    required this.isAvailable,
    this.minStockAlert = 0,
    List<DeliveryType> availableDeliveryTypes = const [
      DeliveryType.quick,
      DeliveryType.scheduled,
    ],
    List<DeliveryType> subscriptionDeliveryTypes = const [],
    Map<DeliveryType, DeliveryConfig>? deliveryConfig,
    required this.updatedAt,
    this.createdAt,
  })  : availableDeliveryTypes = _uniqueTypes(availableDeliveryTypes),
        subscriptionDeliveryTypes = _uniqueTypes(subscriptionDeliveryTypes),
        deliveryConfig = deliveryConfig ??
            _buildDeliveryConfig(
              availableDeliveryTypes: _uniqueTypes(availableDeliveryTypes),
              subscriptionDeliveryTypes:
                  _uniqueTypes(subscriptionDeliveryTypes),
            );

  /* -------------------------------------------------------------------------- */
  /*                              DERIVED HELPERS                               */
  /* -------------------------------------------------------------------------- */

  bool get isLowStock => stock <= minStockAlert;

  bool get isOutOfStock => stock <= 0;

  bool supports(DeliveryType type) => availableDeliveryTypes.contains(type);

  bool supportsSubscriptionFor(DeliveryType type) =>
      subscriptionDeliveryTypes.contains(type);

  bool get isQuickAvailable => supports(DeliveryType.quick);

  bool get isScheduledAvailable => supports(DeliveryType.scheduled);

  bool get isSubscriptionAvailable => subscriptionDeliveryTypes.isNotEmpty;

  /* -------------------------------------------------------------------------- */
  /*                              SERIALIZATION                                 */
  /* -------------------------------------------------------------------------- */

  factory Inventory.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Inventory.fromMap(doc.data()!).copyWith(id: doc.id);
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    final rawAvailableTypes = _parseDeliveryTypeList(
      map['availableDeliveryTypes'] as List<dynamic>?,
    );
    final rawSubscriptionTypes = _parseDeliveryTypeList(
      map['subscriptionDeliveryTypes'] as List<dynamic>?,
    );

    final rawDeliveryConfig = map['deliveryConfig'];
    final parsedConfig = rawDeliveryConfig is Map
        ? rawDeliveryConfig.map(
            (key, value) => MapEntry(
              _parseDeliveryType(key),
              DeliveryConfig.fromMap(Map<String, dynamic>.from(value as Map)),
            ),
          )
        : <DeliveryType, DeliveryConfig>{};

    final availableTypes = parsedConfig.isNotEmpty
        ? parsedConfig.entries
            .where((e) => e.value.enabled)
            .map((e) => e.key)
            .toList()
        : (rawAvailableTypes.isNotEmpty
            ? rawAvailableTypes
            : const [DeliveryType.quick, DeliveryType.scheduled]);

    final subscriptionTypes = parsedConfig.isNotEmpty
        ? parsedConfig.entries
            .where((e) => e.value.enabled && e.value.subscription)
            .map((e) => e.key)
            .toList()
        : rawSubscriptionTypes;

    return Inventory(
      id: map['id'] as String? ?? '',
      warehouseId: map['warehouseId'] as String,
      variantId: map['variantId'] as String,
      stock: (map['stock'] as num? ?? 0).toInt(),
      isAvailable: map['isAvailable'] as bool? ?? false,
      minStockAlert: (map['minStockAlert'] as num?)?.toInt() ?? 0,
      availableDeliveryTypes: availableTypes,
      subscriptionDeliveryTypes: subscriptionTypes,
      deliveryConfig: parsedConfig.isNotEmpty
          ? parsedConfig
          : _buildDeliveryConfig(
              availableDeliveryTypes: availableTypes,
              subscriptionDeliveryTypes: subscriptionTypes,
            ),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Generic map — safe for local storage, JSON, etc.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'warehouseId': warehouseId,
      'variantId': variantId,
      'stock': stock,
      'isAvailable': isAvailable,
      'minStockAlert': minStockAlert,
      'availableDeliveryTypes':
          availableDeliveryTypes.map((e) => e.name).toList(),
      'subscriptionDeliveryTypes':
          subscriptionDeliveryTypes.map((e) => e.name).toList(),
      'deliveryConfig': deliveryConfig.map(
        (key, value) => MapEntry(key.name, value.toMap()),
      ),
      'updatedAt': updatedAt.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Firestore write — uses server timestamp for updatedAt.
  Map<String, dynamic> toFirestore() {
    return {
      'warehouseId': warehouseId,
      'variantId': variantId,
      'stock': stock,
      'isAvailable': isAvailable,
      'minStockAlert': minStockAlert,
      'availableDeliveryTypes':
          availableDeliveryTypes.map((e) => e.name).toList(),
      'subscriptionDeliveryTypes':
          subscriptionDeliveryTypes.map((e) => e.name).toList(),
      'deliveryConfig': deliveryConfig.map(
        (key, value) => MapEntry(key.name, value.toMap()),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /* -------------------------------------------------------------------------- */
  /*                                  COPY                                      */
  /* -------------------------------------------------------------------------- */

  Inventory copyWith({
    String? id,
    String? warehouseId,
    String? variantId,
    int? stock,
    bool? isAvailable,
    int? minStockAlert,
    List<DeliveryType>? availableDeliveryTypes,
    List<DeliveryType>? subscriptionDeliveryTypes,
    Map<DeliveryType, DeliveryConfig>? deliveryConfig,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Inventory(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      variantId: variantId ?? this.variantId,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      availableDeliveryTypes:
          availableDeliveryTypes ?? this.availableDeliveryTypes,
      subscriptionDeliveryTypes:
          subscriptionDeliveryTypes ?? this.subscriptionDeliveryTypes,
      deliveryConfig: deliveryConfig ?? this.deliveryConfig,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                OVERRIDES                                   */
  /* -------------------------------------------------------------------------- */

  @override
  String toString() {
    return 'Inventory(id: $id, warehouseId: $warehouseId, variantId: $variantId, '
        'stock: $stock, isAvailable: $isAvailable, minStockAlert: $minStockAlert, '
        'availableDeliveryTypes: $availableDeliveryTypes, updatedAt: $updatedAt)';
  }

  /* -------------------------------------------------------------------------- */
  /*                              PRIVATE HELPERS                               */
  /* -------------------------------------------------------------------------- */

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static DeliveryType _parseDeliveryType(dynamic value) {
    final normalized = value.toString().toLowerCase();
    return DeliveryType.values.firstWhere(
      (t) => t.name == normalized,
      orElse: () => DeliveryType.quick,
    );
  }

  static List<DeliveryType> _parseDeliveryTypeList(List<dynamic>? values) {
    if (values == null || values.isEmpty) return const [];
    final types = <DeliveryType>[];
    for (final value in values) {
      final normalized = value.toString().toLowerCase();
      if (normalized == 'subscription') continue;
      types.add(_parseDeliveryType(normalized));
    }
    return _uniqueTypes(types);
  }

  static List<DeliveryType> _uniqueTypes(List<DeliveryType> values) {
    final seen = <DeliveryType>{};
    return [
      for (final v in values)
        if (seen.add(v)) v
    ];
  }

  static Map<DeliveryType, DeliveryConfig> _buildDeliveryConfig({
    required List<DeliveryType> availableDeliveryTypes,
    required List<DeliveryType> subscriptionDeliveryTypes,
  }) {
    return {
      for (final type in availableDeliveryTypes)
        type: DeliveryConfig(
          enabled: true,
          subscription: subscriptionDeliveryTypes.contains(type),
        ),
    };
  }
}
