import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/order_model.dart';

abstract class OrderFirestoreDs {
  /// Create a new order and return document ID
  Future<String> createOrder(OrderModel orderData);

  /// Get order by ID
  Stream<Map<String, dynamic>?> getOrderById(String orderId);

  /// Get all orders for a user
  Stream<List<Map<String, dynamic>>> getOrdersByUser(String userId);

  /// Get orders with a specific status
  Stream<List<Map<String, dynamic>>> getOrdersByStatus(String userId, String status);

  /// Update order status to cancel order
  Future<bool> updateOrderStatus(String orderId, String status);

  /// Update order data
  Future<bool> updateOrder(String orderId, Map<String, dynamic> data);

  /// Watch order by ID (real-time updates)
  Stream<Map<String, dynamic>?> watchOrderById(String orderId);

  /// Watch orders for a user (real-time updates)
  Stream<List<Map<String, dynamic>>> watchOrdersByUser(String userId);

  /// Cancel an order
  Future<bool> cancelOrder(String orderId);

  /// Get current authenticated user ID
  String? getCurrentUserId();

  /// Generate unique order number
  Future<String> generateOrderNumber();
}

class OrderFirestoreDsImpl implements OrderFirestoreDs {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _collectionName = Collections.orders;

  OrderFirestoreDsImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? AppConfig.firestore,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _orderCollection => _firestore.collection(_collectionName);
  @override
  Future<String> createOrder(OrderModel orderData) async {
    try {
      if (kDebugMode == true) print(orderData.toString());

      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated to create an order.');
      }

      final docId = orderData.orderNumber.isNotEmpty ? orderData.orderNumber : _firestore.collection(Collections.orders).doc().id;
      final orderRef = _firestore.collection(Collections.orders).doc(docId);

      await _firestore.runTransaction((transaction) async {
        /// 1. Read all inventory docs and validate stock
        final inventorySnapshots = <String, DocumentSnapshot>{};

        for (final entry in orderData.productDetails.entries) {
          final detail = entry.value;
          final packVariantId = detail.packVariantId;
          if (packVariantId.isEmpty) continue;

          // Query inventory for this specific variant and warehouse
          var inventoryQuery = await _firestore
              .collection(Collections.inventories)
              .where('variantId', isEqualTo: packVariantId)
              .where('warehouseId', isEqualTo: orderData.warehouseId)
              .limit(1)
              .get();

          // Fallback: If not found in specific warehouse, check for any inventory of this variant
          if (inventoryQuery.docs.isEmpty) {
            inventoryQuery =
                await _firestore.collection(Collections.inventories).where('variantId', isEqualTo: packVariantId).limit(1).get();
          }

          if (inventoryQuery.docs.isNotEmpty) {
            final inventorySnap = inventoryQuery.docs.first;
            final inventoryData = inventorySnap.data() as Map<String, dynamic>;
            final availableStock = (inventoryData['stock'] as num? ?? 0).toInt();

            if (availableStock < detail.quantity) {
              throw Exception(
                'Not enough stock for variant "$packVariantId". '
                'Available: $availableStock packs, Requested: ${detail.quantity} packs',
              );
            }
            inventorySnapshots[packVariantId] = inventorySnap;
          } else {
            // Log warning but allow order creation for now since we're in bypass mode
            if (kDebugMode) {
              debugPrint('⚠️ Warning: No inventory record found for variant "$packVariantId". Skipping stock validation.');
            }
          }
        }

        /// 2. Decrement stock on each inventory doc (if found)
        for (final entry in orderData.productDetails.entries) {
          final detail = entry.value;
          final packVariantId = detail.packVariantId;
          if (packVariantId.isEmpty || !inventorySnapshots.containsKey(packVariantId)) continue;

          final inventorySnap = inventorySnapshots[packVariantId]!;
          final currentStock = (inventorySnap.data() as Map<String, dynamic>)['stock'] as int;

          transaction.update(inventorySnap.reference, {
            'stock': currentStock - detail.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        /// 3. Create order document
        final orderMap = orderData.toMap();
        orderMap['id'] = orderRef.id;
        orderMap['userId'] = userId;
        orderMap['createdAt'] = FieldValue.serverTimestamp();
        orderMap['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(orderRef, orderMap);

        /// 4. Increment coupon usage count if coupon was applied
        final couponCode = orderData.appliedCouponCode?.trim();
        if (couponCode != null && couponCode.isNotEmpty) {
          final couponRef = _firestore.collection(Collections.coupon).doc(couponCode);
          transaction.update(couponRef, {
            'usedCount': FieldValue.increment(1),
            'usageCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          final userRef = _firestore.collection(Collections.users).doc(userId);
          transaction.set(
            userRef,
            {
              'usedCoupons': {
                couponCode: FieldValue.increment(1),
              },
            },
            SetOptions(merge: true),
          );
        }
      });

      return orderRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> getOrderById(String orderId) async* {
    try {
      final docSnapshot = await _orderCollection.doc(orderId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        yield data;
      }
      yield null;
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getOrdersByUser(String userId) async* {
    try {
      final querySnapshot = await _orderCollection
          .where('customerId', isEqualTo: userId) // Updated to customerId
          .orderBy('createdAt', descending: true)
          .get();
      yield querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getOrdersByStatus(String userId, String status) async* {
    try {
      final querySnapshot = await _orderCollection
          .where('customerId', isEqualTo: userId) // Updated to customerId
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      yield querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  @override
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _orderCollection.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  @override
  Future<bool> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _orderCollection.doc(orderId).update(data);
      return true;
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchOrderById(String orderId) {
    try {
      return _orderCollection.doc(orderId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          data['id'] = snapshot.id;
          return data;
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to watch order: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOrdersByUser(String userId) {
    try {
      return _orderCollection
          .where('customerId', isEqualTo: userId) // Fixed: Changed userId to customerId
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to watch user orders: $e');
    }
  }

  @override
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Get the order document
        final orderRef = _orderCollection.doc(orderId);
        final orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception('Order with ID $orderId not found.');
        }

        final orderData = orderSnapshot.data() as Map<String, dynamic>;

        // 2. Check if order is already cancelled
        if (orderData['status'] == OrderStatus.cancelled) {
          return; // No action needed
        }

        // 3. Restore stock to correct inventory doc
        if (orderData['productDetails'] != null && orderData['productDetails'] is Map) {
          final details = Map<String, dynamic>.from(orderData['productDetails']);
          final warehouseId = orderData['storeId'] as String? ?? 'default'; // Fixed: Changed warehouseId to storeId

          for (final entry in details.entries) {
            final detail = Map<String, dynamic>.from(entry.value as Map);
            final qty = (detail['quantity'] as num?)?.toInt() ?? 1;
            final packVariantId = detail['productId'] as String? ?? ''; // Fixed: Changed packVariantId to productId

            if (qty <= 0 || packVariantId.isEmpty) continue;

            // Find the inventory doc for this variant
            var inventoryQuery = await _firestore
                .collection(Collections.inventories)
                .where('productId', isEqualTo: packVariantId)
                .where('warehouseId', isEqualTo: warehouseId)
                .limit(1)
                .get();

            if (inventoryQuery.docs.isEmpty) {
              inventoryQuery =
                  await _firestore.collection(Collections.inventories).where('productId', isEqualTo: packVariantId).limit(1).get();
            }

            if (inventoryQuery.docs.isEmpty) {
              if (kDebugMode) {
                debugPrint('Warning: Inventory not found for $packVariantId when cancelling order $orderId.');
              }
              continue;
            }

            final inventorySnap = inventoryQuery.docs.first;
            final currentStock = (inventorySnap.data()['stock'] as num? ?? 0).toInt();

            transaction.update(inventorySnap.reference, {
              'stock': currentStock + qty,
              'updatedAt': DateTime.now().toIso8601String(), // Fixed: Changed to ISO String
            });
          }
        }

        // 4. Update the order status to 'cancelled'
        transaction.update(orderRef, {
          'status': OrderStatus.cancelled,
          'updatedAt': DateTime.now().toIso8601String(), // Fixed: Changed to ISO String
        });
      });
      return true;
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  @override
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  @override
  Future<String> generateOrderNumber() async {
    try {
      final now = DateTime.now();
      // Format: GES-# + DDMMYY + 4 digit random
      final datePart = "${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}";
      final randomPart = (Random().nextInt(9000) + 1000).toString();
      return 'GES-#$datePart$randomPart';
    } catch (e) {
      throw Exception('Failed to generate order number: $e');
    }
  }
}
