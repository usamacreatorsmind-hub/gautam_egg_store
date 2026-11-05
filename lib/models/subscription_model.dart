import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';

/// A subscription document stored in eco_subscriptions.
///
/// Stock is NOT decremented on creation. The Cloud Function creates an
/// eco_orders document (and decrements stock) each time the schedule fires
/// while status == SubscriptionStatus.active.
class SubscriptionModel {
  final String? id;

  // User
  final String userId;
  final UserModel user;

  // Delivery
  final UserAddressModel deliveryAddress;
  final String warehouseId;

  // Products — same shape as OrderModel so the Cloud Function can clone them
  final List<ProductModel> products;
  final Map<String, OrderProductDetail> productDetails;

  // Schedule
  final RepeatSchedule repeatSchedule;

  // Lifecycle — pending → active → paused | cancelled
  final String status;

  /// Set by admin when activating. Cloud Function fires when nextDeliveryAt <= now.
  final DateTime? nextDeliveryAt;

  /// ID of the last eco_orders document created for this subscription.
  final String? lastOrderId;
  final DateTime? lastOrderCreatedAt;

  // Pricing snapshot (used by Cloud Function to rebuild order totals)
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double total;
  final String? appliedCouponCode;

  final DeliveryChargeProfile deliveryConfig;
  final DeliveryBoyChargeProfile deliveryBoyConfig;
  final WarehouseTaxConfig taxConfig;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String pauseReason;

  SubscriptionModel({
    this.id,
    required this.userId,
    required this.user,
    required this.pauseReason,
    required this.deliveryAddress,
    required this.warehouseId,
    required this.products,
    required this.productDetails,
    required this.repeatSchedule,
    this.status = SubscriptionStatus.pending,
    this.nextDeliveryAt,
    this.lastOrderId,
    this.lastOrderCreatedAt,
    required this.subtotal,
    this.discount = 0,
    this.deliveryCharge = 0,
    required this.total,
    this.appliedCouponCode,
    required this.deliveryConfig,
    required this.deliveryBoyConfig,
    required this.taxConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'user': user.toMap(),
      'deliveryAddress': deliveryAddress.toMap(),
      'warehouseId': warehouseId,
      'products': products.map((p) {
        final m = p.toFirestore();
        if (p.id != null) m['id'] = p.id;
        return m;
      }).toList(),
      'productDetails': productDetails.map((k, v) => MapEntry(k, v.toMap())),
      'repeatSchedule': repeatSchedule.toMap(),
      'status': status,
      if (nextDeliveryAt != null)
        'nextDeliveryAt': Timestamp.fromDate(nextDeliveryAt!),
      if (lastOrderId != null) 'lastOrderId': lastOrderId,
      if (lastOrderCreatedAt != null)
        'lastOrderCreatedAt': Timestamp.fromDate(lastOrderCreatedAt!),
      'subtotal': subtotal,
      'discount': discount,
      'deliveryCharge': deliveryCharge,
      'total': total,
      if (appliedCouponCode != null) 'appliedCouponCode': appliedCouponCode,
      'deliveryConfig': deliveryConfig.toMap(),
      'deliveryBoyConfig': deliveryBoyConfig.toMap(),
      'taxConfig': taxConfig.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    final repeatMap =
        Map<String, dynamic>.from(map['repeatSchedule'] as Map? ?? {});
    final detailsRaw =
        Map<String, dynamic>.from(map['productDetails'] as Map? ?? {});

    return SubscriptionModel(
      pauseReason: map['pauseReason'] as String? ?? '',
      id: docId,
      userId: map['userId'] as String? ?? '',
      user: map['user'] != null
          ? UserModel.fromMap(
              Map<String, dynamic>.from(map['user'] as Map),
              (map['user'] as Map)['userId']?.toString() ?? docId,
            )
          : UserModel.empty(),
      deliveryAddress: UserAddressModel.fromMap(
          Map<String, dynamic>.from(map['deliveryAddress'] as Map? ?? {})),
      warehouseId: map['warehouseId'] as String? ?? '',
      products: ((map['products'] as List?) ?? []).map((e) {
        final d = Map<String, dynamic>.from(e as Map);
        return ProductModel.fromMap(d, d['id'] as String? ?? '');
      }).toList(),
      productDetails: detailsRaw.map(
        (k, v) => MapEntry(
            k, OrderProductDetail.fromMap(Map<String, dynamic>.from(v as Map))),
      ),
      repeatSchedule: RepeatSchedule.fromMap(repeatMap),
      status: map['status'] as String? ?? SubscriptionStatus.pending,
      nextDeliveryAt: parseTs(map['nextDeliveryAt']),
      lastOrderId: map['lastOrderId'] as String?,
      lastOrderCreatedAt: parseTs(map['lastOrderCreatedAt']),
      subtotal: (map['subtotal'] as num? ?? 0).toDouble(),
      discount: (map['discount'] as num? ?? 0).toDouble(),
      deliveryCharge: (map['deliveryCharge'] as num? ?? 0).toDouble(),
      total: (map['total'] as num? ?? 0).toDouble(),
      appliedCouponCode: map['appliedCouponCode'] as String?,
      deliveryConfig: DeliveryChargeProfile.fromMap(
        map['deliveryConfig'] != null
            ? Map<String, dynamic>.from(map['deliveryConfig'] as Map)
            : {},
      ),
      deliveryBoyConfig: DeliveryBoyChargeProfile.fromMap(
        map['deliveryBoyConfig'] != null
            ? Map<String, dynamic>.from(map['deliveryBoyConfig'] as Map)
            : {},
      ),
      taxConfig: WarehouseTaxConfig.fromMap(
        map['taxConfig'] != null
            ? Map<String, dynamic>.from(map['taxConfig'] as Map)
            : {},
      ),
      createdAt: parseTs(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseTs(map['updatedAt']) ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  SubscriptionModel copyWith({
    String? status,
    DateTime? nextDeliveryAt,
    String? lastOrderId,
    DateTime? lastOrderCreatedAt,
  }) {
    return SubscriptionModel(
      id: id,
      userId: userId,
      user: user,
      deliveryAddress: deliveryAddress,
      warehouseId: warehouseId,
      products: products,
      pauseReason: pauseReason,
      productDetails: productDetails,
      repeatSchedule: repeatSchedule,
      status: status ?? this.status,
      nextDeliveryAt: nextDeliveryAt ?? this.nextDeliveryAt,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      lastOrderCreatedAt: lastOrderCreatedAt ?? this.lastOrderCreatedAt,
      subtotal: subtotal,
      discount: discount,
      deliveryCharge: deliveryCharge,
      total: total,
      appliedCouponCode: appliedCouponCode,
      deliveryConfig: deliveryConfig,
      deliveryBoyConfig: deliveryBoyConfig,
      taxConfig: taxConfig,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isPending => status == SubscriptionStatus.pending;
  bool get isActive => status == SubscriptionStatus.active;
  bool get isPaused => status == SubscriptionStatus.paused;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
}
