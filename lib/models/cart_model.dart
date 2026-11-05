// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';

/// Represents a single item in the cart (product + pack variant + quantity)
class CartItem {
  final String productId;

  /// ID of the selected PackVariant doc in eco_variants collection
  final String packVariantId;

  /// Warehouse from which this item is being ordered
  final String warehouseId;

  /// Number of packs ordered
  int quantity;

  final bool isSelected;

  /// Which delivery type the user chose (quick / scheduled)
  final DeliveryType? selectedDeliveryType;

  /// Whether this delivery type is a subscription (from DeliveryConfig.subscription)
  final bool isSubscription;

  CartItem({
    required this.productId,
    this.packVariantId = '',
    this.warehouseId = '',
    required this.quantity,
    this.isSelected = false,
    this.selectedDeliveryType,
    this.isSubscription = false,
  });

  /// Convenience constructor — builds CartItem directly from a PackVariant + chosen DeliveryType
  factory CartItem.fromVariant({
    required PackVariant variant,
    required DeliveryType deliveryType,
    required String warehouseId,
    int quantity = 1,
  }) {
    final config = variant.deliveryConfig[deliveryType];
    return CartItem(
      productId: variant.productId,
      packVariantId: variant.id,
      warehouseId: warehouseId,
      quantity: quantity,
      selectedDeliveryType: deliveryType,
      isSubscription: config?.subscription ?? false,
    );
  }

  CartItem copyWith({
    String? productId,
    String? packVariantId,
    String? warehouseId,
    int? quantity,
    bool? isSelected,
    DeliveryType? selectedDeliveryType,
    bool? isSubscription,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      packVariantId: packVariantId ?? this.packVariantId,
      warehouseId: warehouseId ?? this.warehouseId,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
      selectedDeliveryType: selectedDeliveryType ?? this.selectedDeliveryType,
      isSubscription: isSubscription ?? this.isSubscription,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'packVariantId': packVariantId,
      'quantity': quantity,
      'warehouseId': warehouseId,
      'selectedDeliveryType': selectedDeliveryType?.name,
      'isSubscription': isSubscription,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String? ?? '',
      packVariantId: map['packVariantId'] as String? ?? map['productId'] as String? ?? '',
      warehouseId: map['warehouseId'] as String? ?? '',
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      selectedDeliveryType: map['selectedDeliveryType'] != null
          ? DeliveryType.values.firstWhere(
              (e) => e.name == map['selectedDeliveryType'],
              orElse: () => DeliveryType.quick,
            )
          : null,
      isSubscription: map['isSubscription'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItem.fromJson(String source) =>
      CartItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CartItem(productId: $productId, packVariantId: $packVariantId, warehouseId: $warehouseId, '
        'quantity: $quantity, isSelected: $isSelected, '
        'selectedDeliveryType: $selectedDeliveryType, isSubscription: $isSubscription)';
  }

  @override
  bool operator ==(covariant CartItem other) {
    if (identical(this, other)) return true;
    return other.productId == productId &&
        other.packVariantId == packVariantId &&
        other.warehouseId == warehouseId;
  }

  @override
  int get hashCode =>
      productId.hashCode ^ packVariantId.hashCode ^ warehouseId.hashCode;
}

/// Represents the user's cart
class CartItemModel {
  final String userId;
  final String? warehouseId;

  final Map<String, List<CartItem>> warehouseItems;
  final String? appliedCouponCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItemModel({
    required this.userId,
    this.warehouseId,
    required this.warehouseItems,
    this.appliedCouponCode,
    this.createdAt,
    this.updatedAt,
  });

  /// Empty cart factory
  factory CartItemModel.empty(String userId) {
    return CartItemModel(
      userId: userId,
      warehouseItems: {},
      appliedCouponCode: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// All items across all warehouses
  List<CartItem> get items =>
      warehouseItems.values.expand((items) => items).toList();

  /// Total quantity of all items (total packs)
  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  /// Total items count (unique product + variant combinations)
  int get itemCount => items.length;

  /// Check if cart is empty
  bool get isEmpty => warehouseItems.isEmpty || items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => !isEmpty;

  /// Get items for a specific warehouse
  List<CartItem> getWarehouseItems(String warehouseId) {
    return warehouseItems[warehouseId] ?? [];
  }

  /// Check if product with a specific pack variant is in cart for a specific warehouse
  bool containsProduct(String productId,
      {String? packVariantId, String? warehouseId}) {
    if (warehouseId != null) {
      final warehouseCart = warehouseItems[warehouseId];
      if (warehouseCart == null) return false;

      if (packVariantId != null) {
        return warehouseCart.any((item) =>
            item.productId == productId && item.packVariantId == packVariantId);
      }
      return warehouseCart.any((item) => item.productId == productId);
    }

    // Check across all warehouses
    return items.any((item) =>
        item.productId == productId &&
        (packVariantId == null || item.packVariantId == packVariantId));
  }

  /// Get quantity of a specific product + variant in cart for a specific warehouse
  int getProductQuantity(String productId,
      {String? packVariantId, String? warehouseId}) {
    if (warehouseId != null) {
      final warehouseCart = warehouseItems[warehouseId];
      if (warehouseCart == null) return 0;

      if (packVariantId != null) {
        final index = warehouseCart.indexWhere((item) =>
            item.productId == productId && item.packVariantId == packVariantId);
        if (index != -1) {
          return warehouseCart[index].quantity;
        }
        return 0;
      }
      final index =
          warehouseCart.indexWhere((item) => item.productId == productId);
      if (index != -1) {
        return warehouseCart[index].quantity;
      }
      return 0;
    }

    // Sum across all warehouses
    return items
        .where((item) =>
            item.productId == productId &&
            (packVariantId == null || item.packVariantId == packVariantId))
        .fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get cart item by product id and optional pack variant id and warehouse id
  CartItem? getItem(String productId,
      {String? packVariantId, String? warehouseId}) {
    if (warehouseId != null) {
      final warehouseCart = warehouseItems[warehouseId];
      if (warehouseCart == null) return null;

      if (packVariantId != null) {
        final index = warehouseCart.indexWhere((item) =>
            item.productId == productId && item.packVariantId == packVariantId);
        if (index != -1) {
          return warehouseCart[index];
        }
        return null;
      }
      final index =
          warehouseCart.indexWhere((item) => item.productId == productId);
      if (index != -1) {
        return warehouseCart[index];
      }
      return null;
    }

    // Find in any warehouse
    return items.cast<CartItem?>().firstWhere(
          (item) =>
              item!.productId == productId &&
              (packVariantId == null || item.packVariantId == packVariantId),
          orElse: () => null,
        );
  }

  CartItemModel copyWith({
    String? userId,
    Object? warehouseId = _sentinel,
    Map<String, List<CartItem>>? warehouseItems,
    Object? appliedCouponCode = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      userId: userId ?? this.userId,
      warehouseId:
          warehouseId == _sentinel ? this.warehouseId : warehouseId as String?,
      warehouseItems: warehouseItems ?? Map.from(this.warehouseItems),
      appliedCouponCode: appliedCouponCode == _sentinel
          ? this.appliedCouponCode
          : appliedCouponCode as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const Object _sentinel = Object();

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    final List<dynamic> itemsList = map['items'] as List<dynamic>? ?? [];
    final List<CartItem> items = itemsList
        .map((x) => CartItem.fromMap(Map<String, dynamic>.from(x as Map)))
        .toList();

    // Reconstruct warehouseItems grouped by their saved warehouseId
    final Map<String, List<CartItem>> warehouseItems = {};
    for (var item in items) {
      final wId = item.warehouseId.isEmpty ? 'default' : item.warehouseId;
      warehouseItems.putIfAbsent(wId, () => []).add(item);
    }

    return CartItemModel(
      userId: map['uid'] as String? ?? map['userId'] as String? ?? '',
      warehouseItems: warehouseItems,
      appliedCouponCode: map['appliedCouponCode'] as String?,
      updatedAt: _parseTimestamp(map['updatedAt']),
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  factory CartItemModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CartItemModel.fromMap(doc.data()!);
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String toJson() => json.encode(toMap());

  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CartItemModel(userId: $userId, warehouseId: $warehouseId, warehouseItems: $warehouseItems, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant CartItemModel other) {
    if (identical(this, other)) return true;
    return other.userId == userId &&
        const MapEquality<String, List<CartItem>>()
            .equals(other.warehouseItems, warehouseItems);
  }

  @override
  int get hashCode =>
      userId.hashCode ^
      const MapEquality<String, List<CartItem>>().hash(warehouseItems);
}
