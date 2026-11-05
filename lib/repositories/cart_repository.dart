import 'package:sure_wholesaler/firebase/cart_firestore_ds.dart';
import 'package:sure_wholesaler/models/cart_model.dart';

abstract class CartRepository {
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

class CartRepositoryImpl implements CartRepository {
  final CartFirestoreDs _cartFirestoreDs;

  CartRepositoryImpl(this._cartFirestoreDs);

  @override
  Future<void> addToCart(CartItem cartItem) {
    return _cartFirestoreDs.addToCart(cartItem);
  }

  @override
  Future<void> removeFromCart(CartItem cartItem) {
    return _cartFirestoreDs.removeFromCart(cartItem);
  }

  @override
  Future<void> updateQuantity(CartItem cartItem) {
    return _cartFirestoreDs.updateQuantity(cartItem);
  }

  @override
  Future<bool> updateDeliveryType(CartItem cartItem) {
    return _cartFirestoreDs.updateDeliveryType(cartItem);
  }

  @override
  Future<void> updateWarehouseId(String? warehouseId) {
    return _cartFirestoreDs.updateWarehouseId(warehouseId);
  }

  @override
  Future<void> incrementQuantity(CartItem cartItem) {
    return _cartFirestoreDs.incrementQuantity(cartItem);
  }

  @override
  Future<void> decrementQuantity(CartItem cartItem) {
    return _cartFirestoreDs.decrementQuantity(cartItem);
  }

  @override
  Future<void> clearCart() {
    return _cartFirestoreDs.clearCart();
  }

  @override
  Stream<CartItemModel?> getCart() {
    return _cartFirestoreDs.getCart();
  }
}
