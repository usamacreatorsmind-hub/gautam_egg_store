// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sure_wholesaler/models/product_model.dart';

import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';

/// Holds per-product order info: which pack variant, how many packs, and price snapshot
class OrderProductDetail {
  final String packVariantId;
  final String name;
  final String unit;
  final String? imageUrl; // Added for images in orders
  final int packSize;
  final double pricePerPack;
  final double? mrpPerPack;
  final int quantity;
  final double finalAmount;

  OrderProductDetail({
    required this.packVariantId,
    this.name = '',
    this.unit = '',
    this.imageUrl,
    required this.packSize,
    required this.pricePerPack,
    this.mrpPerPack,
    required this.quantity,
    required this.finalAmount,
  });

  int get totalUnits => quantity * packSize;
  double get lineTotal => pricePerPack * quantity;
  double get mrpLineTotal => (mrpPerPack ?? pricePerPack) * quantity;

  Map<String, dynamic> toMap() => {
        'productId': packVariantId,
        'packVariantId': packVariantId,
        'name': name,
        'unit': unit,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'quantity': quantity,
        'unitPrice': pricePerPack,
        'pricePerPack': pricePerPack,
        if (mrpPerPack != null) 'mrpPerPack': mrpPerPack,
        'packSize': packSize,
        'lineTotal': finalAmount,
        'finalAmount': finalAmount,
      };

  factory OrderProductDetail.fromMap(Map<String, dynamic> map) {
    return OrderProductDetail(
      packVariantId: map['packVariantId'] ?? map['productId'] ?? '',
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      imageUrl: map['imageUrl'] as String?,
      packSize: (map['packSize'] as num?)?.toInt() ?? 1,
      finalAmount: (map['lineTotal'] as num? ?? map['finalAmount'] as num? ?? 0.0).toDouble(),
      pricePerPack: (map['unitPrice'] as num? ?? map['pricePerPack'] as num? ?? 0.0).toDouble(),
      mrpPerPack: (map['mrpPerPack'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderModel {
  final String? id;

  // User
  final String userId;
  final UserModel user;

  // Address
  final dynamic deliveryAddress; // Can be String or UserAddressModel

  // Order info
  final DeliveryType deliveryType;
  final String orderNumber;
  final List<ProductModel> products;
  final Map<String, OrderProductDetail> productDetails; // productId -> order detail

  // Coupon
  final String? appliedCouponCode;

  // Pricing
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double total;
  final double platformFee;
  final double packingFee;
  final double extraOrderCharge;

  // Status & payment
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? notes;

  final DeliveryChargeProfile deliveryConfig;
  final DeliveryBoyChargeProfile deliveryBoyConfig;
  final WarehouseTaxConfig taxConfig;

  final String? deliveryAgentId;

  // Set by Cloud Function when this order was auto-created from a subscription
  final String? subscriptionId;

  // Meta

  final DateTime createdAt;
  final DateTime updatedAt;
  final String warehouseId;

// time slot to get the order

// to repeat cycle this will be daily , weekly , mid-weekly, monthly
  final RepeatSchedule? repeatSchedule;

  OrderModel({
    this.repeatSchedule,
    required this.warehouseId,
    required this.deliveryConfig,
    required this.deliveryBoyConfig,
    required this.taxConfig,
    required this.deliveryType,
    this.id,
    required this.userId,
    this.deliveryAgentId,
    this.subscriptionId,
    required this.user,
    required this.deliveryAddress,
    required this.orderNumber,
    required this.products,
    this.productDetails = const {},
    this.appliedCouponCode,
    required this.subtotal,
    this.discount = 0,
    this.deliveryCharge = 0,
    required this.total,
    this.platformFee = 5.0,
    this.packingFee = 5.0,
    this.extraOrderCharge = 0.0,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'storeId': warehouseId,
      'customerId': userId,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'amountPaid': 0, // Default for new project
      'subtotal': subtotal,
      'total': total,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'platformFee': platformFee,
      'parkingFee': packingFee,
      'extraOrderCharge': extraOrderCharge,
      'deliveryAddress': deliveryAddress is UserAddressModel ? deliveryAddress.toMap() : deliveryAddress,
      'items': productDetails.values.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deliveryType': deliveryType.name,
      'deliveryConfig': deliveryConfig.toMap(),
      'deliveryBoyConfig': deliveryBoyConfig.toMap(),
      'taxConfig': taxConfig.toMap(),
      if (deliveryAgentId != null) 'assignedDeliveryPersonId': deliveryAgentId,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    // Parse timestamps safely (Naye project mein String format hai)
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();

    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        createdAt = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      } else if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      }
    }
    if (map['updatedAt'] != null) {
      if (map['updatedAt'] is String) {
        updatedAt = DateTime.tryParse(map['updatedAt']) ?? DateTime.now();
      } else if (map['updatedAt'] is Timestamp) {
        updatedAt = (map['updatedAt'] as Timestamp).toDate();
      }
    }

    // Parse items into productDetails
    Map<String, OrderProductDetail> productDetails = {};
    if (map['items'] != null && map['items'] is List) {
      for (var item in map['items']) {
        final iMap = Map<String, dynamic>.from(item as Map);
        final productId = iMap['productId']?.toString() ?? '';
        productDetails[productId] = OrderProductDetail.fromMap(iMap);
      }
    }

    // Address handling
    dynamic address = map['deliveryAddress'];
    if (address is Map) {
      address = UserAddressModel.fromMap(Map<String, dynamic>.from(address));
    }

    return OrderModel(
      id: docId ?? map['id'],
      userId: map['customerId'] ?? map['userId'] ?? '',
      warehouseId: map['storeId'] ?? map['warehouseId'] ?? '',
      deliveryType: map['deliveryType'] != null
          ? DeliveryType.values.firstWhere(
              (e) => e.name == map['deliveryType'],
              orElse: () => DeliveryType.quick,
            )
          : DeliveryType.quick,
      user: map['user'] != null ? UserModel.fromMap(Map<String, dynamic>.from(map['user']), '') : UserModel.empty(),
      deliveryAddress: address ?? UserAddressModel.empty(),
      orderNumber: map['orderNumber']?.toString() ?? map['id']?.toString() ?? docId,
      products: [], // Loaded separately if needed
      productDetails: productDetails,
      subtotal: (map['subtotal'] as num? ?? 0).toDouble(),
      total: (map['total'] as num? ?? 0).toDouble(),
      deliveryCharge: (map['deliveryCharge'] as num? ?? 0.0).toDouble(),
      discount: (map['discount'] as num? ?? 0.0).toDouble(),
      platformFee: (map['platformFee'] as num? ?? 5.0).toDouble(),
      packingFee: (map['parkingFee'] as num? ?? 5.0).toDouble(),
      extraOrderCharge: (map['extraOrderCharge'] as num? ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'],
      paymentStatus: map['paymentStatus'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      deliveryConfig: map['deliveryConfig'] != null
          ? DeliveryChargeProfile.fromMap(Map<String, dynamic>.from(map['deliveryConfig']))
          : const DeliveryChargeProfile(),
      deliveryBoyConfig: map['deliveryBoyConfig'] != null
          ? DeliveryBoyChargeProfile.fromMap(Map<String, dynamic>.from(map['deliveryBoyConfig']))
          : const DeliveryBoyChargeProfile(),
      taxConfig:
          map['taxConfig'] != null ? WarehouseTaxConfig.fromMap(Map<String, dynamic>.from(map['taxConfig'])) : const WarehouseTaxConfig(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    UserModel? user,
    UserAddressModel? deliveryAddress,
    String? warehouseId,
    String? orderNumber,
    List<ProductModel>? products,
    Map<String, OrderProductDetail>? productDetails,
    Object? appliedCouponCode = _sentinel,
    RepeatSchedule? repeatSchedule,
    DeliveryChargeProfile? deliveryConfig,
    DeliveryBoyChargeProfile? deliveryBoyConfig,
    WarehouseTaxConfig? taxConfig,
    double? subtotal,
    String? deliveryAgentId,
    double? discount,
    double? deliveryCharge,
    double? total,
    double? platformFee,
    double? packingFee,
    double? extraOrderCharge,
    String? status,
    String? paymentMethod,
    DeliveryType? deliveryType,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      warehouseId: warehouseId ?? this.warehouseId,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deliveryAgentId: deliveryAgentId ?? this.deliveryAgentId,
      user: user ?? this.user,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      repeatSchedule: repeatSchedule ?? this.repeatSchedule,
      deliveryConfig: deliveryConfig ?? this.deliveryConfig,
      deliveryBoyConfig: deliveryBoyConfig ?? this.deliveryBoyConfig,
      taxConfig: taxConfig ?? this.taxConfig,
      orderNumber: orderNumber ?? this.orderNumber,
      products: products ?? this.products,
      productDetails: productDetails ?? this.productDetails,
      appliedCouponCode: appliedCouponCode == _sentinel ? this.appliedCouponCode : appliedCouponCode as String?,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      total: total ?? this.total,
      platformFee: platformFee ?? this.platformFee,
      packingFee: packingFee ?? this.packingFee,
      extraOrderCharge: extraOrderCharge ?? this.extraOrderCharge,
      deliveryType: deliveryType ?? this.deliveryType,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const Object _sentinel = Object();

  bool get isSubscriptionOrder => subscriptionId != null && subscriptionId!.isNotEmpty;

  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isProcessing => status == OrderStatus.packed;

  bool get isShipped => status == OrderStatus.outForDelivery;
  bool get isOutForDelivery => status == OrderStatus.outForDelivery;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;

  double get computedTotal {
    final double totalMrp = productDetails.values.fold(0.0, (sum, d) => sum + d.mrpLineTotal);
    final calcMrpDiscount = (totalMrp - subtotal).clamp(0.0, double.infinity);
    final calcCouponDiscount = (discount - calcMrpDiscount).clamp(0.0, double.infinity);
    final netProductAmount = (subtotal - calcCouponDiscount).clamp(0.0, double.infinity);
    final baseTotal = netProductAmount + deliveryCharge + platformFee + packingFee + extraOrderCharge;

    final gatewayFee = (paymentMethod != null &&
            paymentMethod!.toLowerCase() != 'cod' &&
            paymentMethod!.toLowerCase() != 'cash on delivery')
        ? baseTotal * taxConfig.paymentGatewayChargePercentage / 100
        : 0.0;

    final finalCalc = baseTotal + gatewayFee;
    return finalCalc > 0 ? finalCalc : total;
  }

  @override
  String toString() {
    return '''OrderModel(id: $id, userId: $userId, warehouseId: $warehouseId,    user: $user, deliveryAddress: $deliveryAddress, orderNumber: $orderNumber, products: $products, subtotal: $subtotal, discount: $discount, deliveryCharge: $deliveryCharge, total: $total, status: $status, deliveryAgentId: $deliveryAgentId, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, notes: $notes,createdAt: $createdAt, updatedAt: $updatedAt, deliveryConfig: $deliveryConfig, deliveryBoyConfig: $deliveryBoyConfig, taxConfig: $taxConfig,  repeatSchedule: $repeatSchedule, deliveryType: $deliveryType
    )''';
  }
}
