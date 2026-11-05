export 'package:sure_wholesaler/models/delivery_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/models/inventory_model.dart';

/// One tier in wholesale pricing: buy >= [minQty] packs → pay [price] each.
class PricingTier {
  final int minQty;
  final double price;
  final String? label;

  const PricingTier({required this.minQty, required this.price, this.label});

  factory PricingTier.fromMap(Map<String, dynamic> map) => PricingTier(
    label: map['label'] ?? map['tierName'] ?? map['name'],
    minQty: (map['minQuantity'] ?? map['minQty'] ?? 1) is num
        ? (map['minQuantity'] ?? map['minQty']).toInt()
        : int.tryParse((map['minQuantity'] ?? map['minQty'] ?? '1').toString()) ?? 1,
    price: (map['pricePerUnit'] ?? map['price'] ?? 0.0) is num
        ? (map['pricePerUnit'] ?? map['price']).toDouble()
        : double.tryParse((map['pricePerUnit'] ?? map['price'] ?? '0.0').toString()) ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'minQty': minQty,
    'price': price,
    if (label != null) 'label': label,
  };

  @override
  String toString() => 'PricingTier(label: $label, minQty: $minQty, price: $price)';
}

class PackVariant implements FirestoreModel {
  @override
  final String id;

  final String productId;

  /// SKU — unique identifier for this variant (e.g. "NIKE-RED-M")
  final String sku;

  /// Dynamic attributes driven by category.variantAttributes
  /// e.g. {"color": "Red", "size": "M"} for Fashion
  ///      {"color": "Black", "storage": "128GB"} for Mobile
  ///      {"packSize": "400g"} for Bakery
  final Map<String, String> attributes;

  /// Per-variant image URLs (full storage paths)
  final List<String> imageUrls;

  /// Selling price PER PACK — used when no tier matches
  final double price;

  /// Optional MRP for strike-through display
  final double? mrp;

  /// Wholesale pricing tiers — sorted by minQty ascending
  /// If empty, [price] is used for all quantities
  final List<PricingTier> pricingTiers;

  /// Minimum order quantity
  final int moq;

  /// Physical weight of one pack (for shipping calculation)
  final double? weight;
  final String weightUnit;

  /// Pack size — kept for FMCG backward compatibility (e.g. pack of 12 units)
  final int packSize;

  /// Optional expiry (useful for food / pharma)
  final String? expiryDate;

  final bool isActive;

  /// Runtime inventory attached by the repository
  final Inventory? inventory;

  /// Available stock in PACKS — runtime, derived from inventory
  final int stock;

  /// Low-stock alert threshold — runtime, derived from inventory
  final int minStockAlert;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  PackVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.attributes,
    required this.imageUrls,
    required this.price,
    required this.mrp,
    required this.pricingTiers,
    required this.moq,
    this.weight,
    required this.weightUnit,
    required this.packSize,
    this.expiryDate,
    required this.isActive,
    required this.inventory,
    required this.stock,
    required this.minStockAlert,
    this.createdAt,
    this.updatedAt,
  });

  factory PackVariant.placeholder(String productId) => PackVariant(
    id: '',
    productId: productId,
    sku: '',
    attributes: const {},
    imageUrls: const [],
    mrp: 0.0,
    pricingTiers: const [],
    moq: 1,
    weight: 0.0,
    weightUnit: 'g',
    packSize: 1,
    inventory: null,
    price: 0.0,
    stock: 0,
    minStockAlert: 0,
    isActive: false,
  );

  /* -------------------------------------------------------------------------- */
  /*                              PRICING HELPERS                               */
  /* -------------------------------------------------------------------------- */

  /// Returns the correct price for a given quantity (applies tier pricing)
  double priceForQuantity(int qty) {
    if (pricingTiers.isEmpty) return price;
    final sorted = [...pricingTiers]
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    for (final tier in sorted) {
      if (qty >= tier.minQty) return tier.price;
    }
    return price;
  }

  /* -------------------------------------------------------------------------- */
  /*                              ATTRIBUTE HELPERS                             */
  /* -------------------------------------------------------------------------- */

  /// Display label built from attributes map e.g. "Red / M" or "128GB / Black"
  String get attributeLabel {
    if (attributes.isEmpty) {
      return packSize > 1 ? 'Pack of $packSize' : 'Default';
    }
    return attributes.values.join(' / ');
  }

  /* -------------------------------------------------------------------------- */
  /*                              STOCK HELPERS                                 */
  /* -------------------------------------------------------------------------- */

  bool get isLowStock => stock <= minStockAlert;
  bool get isOutOfStock => stock <= 0;
  bool get hasDiscount => mrp != null && mrp! > price;
  double? get discountAmount => hasDiscount ? (mrp! - price) : null;
  double? get discountPercent =>
      hasDiscount ? ((mrp! - price) / mrp!) * 100 : null;

  /* -------------------------------------------------------------------------- */
  /*                             DELIVERY HELPERS                               */
  /* -------------------------------------------------------------------------- */

  List<DeliveryType> get availableDeliveryTypes =>
      inventory?.availableDeliveryTypes ?? const <DeliveryType>[];

  List<DeliveryType> get subscriptionDeliveryTypes =>
      inventory?.subscriptionDeliveryTypes ?? const <DeliveryType>[];

  Map<DeliveryType, DeliveryConfig> get deliveryConfig =>
      inventory?.deliveryConfig ?? const <DeliveryType, DeliveryConfig>{};

  bool supports(DeliveryType type) => availableDeliveryTypes.contains(type);
  bool supportsSubscriptionFor(DeliveryType type) =>
      subscriptionDeliveryTypes.contains(type);
  bool get isQuickAvailable => supports(DeliveryType.quick);
  bool get isScheduledAvailable => supports(DeliveryType.scheduled);
  bool get isSubscriptionAvailable => subscriptionDeliveryTypes.isNotEmpty;

  /* -------------------------------------------------------------------------- */
  /*                              SERIALIZATION                                 */
  /* -------------------------------------------------------------------------- */

  factory PackVariant.fromMap(Map<String, dynamic> map, {String? productId}) {
    final rawPackSize = map['packSize'] ?? map['packQuantity'];

    return PackVariant(
      inventory: map['inventory'],
      id: map['id'] as String? ?? '',
      productId: productId ?? map['productId'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      attributes: () {
        Map<String, String> attrs = map['attributes'] != null
            ? Map<String, String>.from(
          (map['attributes'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        )
            : {};
        if (attrs.isEmpty && rawPackSize is String && rawPackSize.isNotEmpty && int.tryParse(rawPackSize) == null) {
          attrs = {'Size': rawPackSize};
        }
        return attrs;
      }(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      price: (map['sellingPrice'] ?? map['price'] ?? 0.0) is num
          ? (map['sellingPrice'] ?? map['price']).toDouble()
          : double.tryParse((map['sellingPrice'] ?? map['price'] ?? '0.0').toString()) ?? 0.0,
      mrp: (map['mrp'] ?? 0.0) is num
          ? (map['mrp']).toDouble()
          : double.tryParse((map['mrp'] ?? '0.0').toString()) ?? 0.0,
      pricingTiers: map['pricingTiers'] != null
          ? (map['pricingTiers'] as List)
          .map((e) => PricingTier.fromMap(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
      moq: (map['moq'] as num?)?.toInt() ?? 1,
      weight: (map['weight'] as num?)?.toDouble(),
      weightUnit: map['weightUnit'] as String? ?? 'g',
      packSize: () {
        if (rawPackSize is int) return rawPackSize;
        if (rawPackSize is num) return rawPackSize.toInt();
        if (rawPackSize is String) {
          final p = int.tryParse(rawPackSize);
          if (p != null) return p;
          final match = RegExp(r'(\d+)').firstMatch(rawPackSize);
          if (match != null) return int.tryParse(match.group(1)!) ?? 0;
        }
        return 1;
      }(),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      minStockAlert: (map['minStockAlert'] as num?)?.toInt() ?? 0,
      expiryDate: map['expiryDate'] as String?,
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory PackVariant.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return PackVariant.fromMap(
      doc.data()!,
      productId: doc.data()!['productId'] as String? ?? '',
    ).copyWith(id: doc.id);
  }

  /// Full in-memory map including runtime stock fields.
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sku': sku,
      'attributes': attributes,
      'imageUrls': imageUrls,
      'price': price,
      if (mrp != null) 'mrp': mrp,
      'pricingTiers': pricingTiers.map((t) => t.toMap()).toList(),
      'moq': moq,
      if (weight != null) 'weight': weight,
      'weightUnit': weightUnit,
      'packSize': packSize,
      'stock': stock,
      'minStockAlert': minStockAlert,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Serialize for the top-level variants collection in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'sku': sku,
      'attributes': attributes,
      'imageUrls': imageUrls,
      'price': price,
      if (mrp != null) 'mrp': mrp,
      'pricingTiers': pricingTiers.map((t) => t.toMap()).toList(),
      'moq': moq,
      if (weight != null) 'weight': weight,
      'weightUnit': weightUnit,
      'packSize': packSize,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /* -------------------------------------------------------------------------- */
  /*                              COPY / WITH                                   */
  /* -------------------------------------------------------------------------- */

  PackVariant withInventoryData(Inventory? inventory) {
    return copyWith(
      inventory: inventory,
      stock: inventory?.stock ?? stock,
      minStockAlert: inventory?.minStockAlert ?? minStockAlert,
    );
  }

  PackVariant copyWith({
    String? id,
    String? productId,
    String? sku,
    Map<String, String>? attributes,
    List<String>? imageUrls,
    double? price,
    double? mrp,
    List<PricingTier>? pricingTiers,
    int? moq,
    double? weight,
    String? weightUnit,
    int? packSize,
    int? stock,
    int? minStockAlert,
    String? expiryDate,
    bool? isActive,
    Inventory? inventory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      attributes: attributes ?? this.attributes,
      imageUrls: imageUrls ?? this.imageUrls,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      moq: moq ?? this.moq,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      packSize: packSize ?? this.packSize,
      stock: stock ?? this.stock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      inventory: inventory ?? this.inventory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  @override
  String toString() {
    return 'PackVariant(id: $id, productId: $productId, sku: $sku, '
        'attributes: $attributes, price: $price, mrp: $mrp, '
        'pricingTiers: $pricingTiers, moq: $moq, stock: $stock, '
        'isActive: $isActive)';
  }
}
