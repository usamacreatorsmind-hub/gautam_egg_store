import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/cart_model.dart';

abstract class CartFirestoreDs {
  Future<void> addToCart(CartItem cartItem);
  Future<void> removeFromCart(CartItem cartItem);
  Future<void> updateQuantity(CartItem cartItem);
  Future<bool> updateDeliveryType(CartItem cartItem);
  Future<void> updateWarehouseId(String? warehouseId);
  Future<void> incrementQuantity(CartItem cartItem);
  Future<void> decrementQuantity(CartItem cartItem);
  Future<void> clearCart();
  Stream<CartItemModel?> getCart();
}

class CartFirestoreDsImpl implements CartFirestoreDs {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CartFirestoreDsImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? AppConfig.firestore,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _cartRef {
    final uid = _userId;
    if (uid == null) return null;
    // Explicitly using 'carts' to match the rules
    return _firestore.collection('carts').doc(uid);
  }

  @override
  Future<void> addToCart(CartItem cartItem) async {
    final cartRef = _cartRef;
    if (cartRef == null) throw Exception('User not logged in');

    try {
      final doc = await cartRef.get();
      if (!doc.exists) {
        await cartRef.set({
          'uid': _userId,
          'items': [cartItem.toMap()],
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        final data = doc.data()!;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        final index = items.indexWhere((it) => it['productId'] == cartItem.productId && it['packVariantId'] == cartItem.packVariantId);

        if (index != -1) {
          items[index]['quantity'] = (items[index]['quantity'] as int) + cartItem.quantity;
        } else {
          items.add(cartItem.toMap());
        }

        await cartRef.update({
          'items': items,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Firestore Cart Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateQuantity(CartItem cartItem) async {
    final cartRef = _cartRef;
    if (cartRef == null) return;

    final doc = await cartRef.get();
    if (!doc.exists) return;

    final items = List<Map<String, dynamic>>.from(doc.data()!['items'] ?? []);
    final index = items.indexWhere((it) => it['productId'] == cartItem.productId);

    if (index != -1) {
      if (cartItem.quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index]['quantity'] = cartItem.quantity;
      }
      await cartRef.update({
        'items': items,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> incrementQuantity(CartItem cartItem) async {
    final cartRef = _cartRef;
    if (cartRef == null) return;

    final doc = await cartRef.get();
    if (!doc.exists) return;

    final items = List<Map<String, dynamic>>.from(doc.data()!['items'] ?? []);
    final index = items.indexWhere((it) => it['productId'] == cartItem.productId);

    if (index != -1) {
      items[index]['quantity'] = (items[index]['quantity'] as int) + 1;
      await cartRef.update({
        'items': items,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> decrementQuantity(CartItem cartItem) async {
    final cartRef = _cartRef;
    if (cartRef == null) return;

    final doc = await cartRef.get();
    if (!doc.exists) return;

    final items = List<Map<String, dynamic>>.from(doc.data()!['items'] ?? []);
    final index = items.indexWhere((it) => it['productId'] == cartItem.productId);

    if (index != -1) {
      final currentQty = items[index]['quantity'] as int;
      if (currentQty <= 1) {
        items.removeAt(index);
      } else {
        items[index]['quantity'] = currentQty - 1;
      }
      await cartRef.update({
        'items': items,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> removeFromCart(CartItem cartItem) async {
    final cartRef = _cartRef;
    final uid = _userId;
    debugPrint('🛒 ATTEMPT DELETE: User=$uid, DocPath=${cartRef?.path}');
    
    if (cartRef == null) {
      debugPrint('❌ DELETE FAILED: Cart Reference is NULL');
      return;
    }

    try {
      final doc = await cartRef.get();
      if (!doc.exists) {
        debugPrint('❌ DELETE FAILED: Cart document does not exist');
        return;
      }

      final items = List<Map<String, dynamic>>.from(doc.data()!['items'] ?? []);
      items.removeWhere((it) => it['productId'] == cartItem.productId && it['packVariantId'] == cartItem.packVariantId);

      await cartRef.update({
        'items': items,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ DELETE SUCCESS');
    } catch (e) {
      debugPrint('❌ DELETE ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCart() async {
    final cartRef = _cartRef;
    if (cartRef == null) return;
    await cartRef.update({
      'items': [],
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Stream<CartItemModel?> getCart() {
    final cartRef = _cartRef;
    if (cartRef == null) return Stream.value(null);

    return cartRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return CartItemModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<bool> updateDeliveryType(CartItem cartItem) async => true; // Simplified

  @override
  Future<void> updateWarehouseId(String? warehouseId) async {} // Simplified
}
