import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/cart_firestore_ds.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/repositories/cart_repository.dart';

typedef WarehouseReader = String? Function();

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(CartFirestoreDsImpl());
});

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<CartItemModel>>((ref) {
  return CartNotifier(
    ref.read(cartRepositoryProvider),
    getSelectedWarehouse: () =>
        ref.read(selectedWarehousesProvider).firstOrNull,
  );
});

final cartItemsProvider =
    FutureProvider<Map<String, ProductModel>>((ref) async {
  final cartState = ref.watch(cartProvider);
  final cart = cartState.value;

  if (cart == null || cart.items.isEmpty) return {};

  final firestore = AppConfig.firestore;
  final variantDs = VariantFirestoreDsImpl();
  final productIds = cart.items.map((e) => e.productId).toSet().toList();

  if (productIds.isEmpty) return {};

  // Fetch products in parallel
  final snapshots = await Future.wait(
    productIds
        .map((id) => firestore.collection(Collections.products).doc(id).get()),
  );

  final Map<String, ProductModel> products = {};
  for (var doc in snapshots) {
    if (doc.exists && doc.data() != null) {
      products[doc.id] = ProductModel.fromFirestore(doc);
    }
  }

  return products;
});

final cartTotalProvider = Provider<double>((ref) {
  final cartState = ref.watch(cartProvider);
  final productsState = ref.watch(cartItemsProvider);

  final cart = cartState.value;
  final products = productsState.value;

  if (cart == null || products == null) return 0.0;

  double total = 0.0;
  for (var item in cart.items) {
    final product = products[item.productId];
    if (product != null) {
      final variant = product.getPackVariant(item.packVariantId);
      final price = variant != null
          ? variant.priceForQuantity(item.quantity)
          : product.price;
      total += price * item.quantity;
    }
  }
  return total;
});

class CartNotifier extends StateNotifier<AsyncValue<CartItemModel>> {
  final CartRepository _repository;
  final WarehouseReader _getSelectedWarehouse;
  StreamSubscription<CartItemModel?>? _cartSubscription;

  CartNotifier(
    this._repository, {
    required WarehouseReader getSelectedWarehouse,
  })  : _getSelectedWarehouse = getSelectedWarehouse,
        super(const AsyncValue.loading()) {
    _init();
  }

  bool get selectionMode =>
      state.value?.items.any((item) => item.isSelected) ?? false;

  List<CartItem> get selectedItems =>
      state.value?.items.where((i) => i.isSelected).toList() ?? [];

  void enterSelectionMode(CartItem item) {
    final current = state.value;
    if (current == null) return;
    final updatedWarehouseItems =
        current.warehouseItems.map((warehouseId, items) {
      return MapEntry(
          warehouseId,
          items.map((i) {
            if (i.productId == item.productId &&
                i.packVariantId == item.packVariantId &&
                i.warehouseId == item.warehouseId) {
              return i.copyWith(isSelected: true);
            }
            return i;
          }).toList());
    });
    state = AsyncValue.data(
        current.copyWith(warehouseItems: updatedWarehouseItems));
  }

  void toggleSelection(CartItem item) {
    final current = state.value;
    if (current == null) return;
    final updatedWarehouseItems =
        current.warehouseItems.map((warehouseId, items) {
      return MapEntry(
          warehouseId,
          items.map((i) {
            if (i.productId == item.productId &&
                i.packVariantId == item.packVariantId &&
                i.warehouseId == item.warehouseId) {
              return i.copyWith(isSelected: !i.isSelected);
            }
            return i;
          }).toList());
    });
    state = AsyncValue.data(
        current.copyWith(warehouseItems: updatedWarehouseItems));
  }

  void clearSelection() {
    final current = state.value;
    if (current == null) return;
    final updatedWarehouseItems =
        current.warehouseItems.map((warehouseId, items) {
      return MapEntry(warehouseId,
          items.map((i) => i.copyWith(isSelected: false)).toList());
    });
    state = AsyncValue.data(
        current.copyWith(warehouseItems: updatedWarehouseItems));
  }

  void _init() {
    _cartSubscription = _repository.getCart().listen(
      (cart) {
        if (cart != null) {
          state = AsyncValue.data(cart);
        } else {
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          state = AsyncValue.data(CartItemModel.empty(userId).copyWith(
            warehouseId: _getSelectedWarehouse(),
          ));
        }
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<void> addToCart(CartItem item) async {
    await _repository.addToCart(item);
  }

  Future<void> setActiveWarehouse(String? warehouseId) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(warehouseId: warehouseId));
    }
    await _repository.updateWarehouseId(warehouseId);
  }

  Future<void> removeFromCart(CartItem item) async {
    await _repository.removeFromCart(item);
  }

  Future<void> updateQuantity(CartItem item) async {
    await _repository.updateQuantity(item);
  }

  Future<bool> updateDeliveryType(CartItem item) async {
    final success = await _repository.updateDeliveryType(item);
    if (success) {
      final current = state.value;
      if (current != null) {
        final updatedWarehouseItems =
            current.warehouseItems.map((warehouseId, items) {
          if (warehouseId == item.warehouseId) {
            return MapEntry(
                warehouseId,
                items.map((i) {
                  if (i.productId == item.productId &&
                      i.packVariantId == item.packVariantId) {
                    return item;
                  }
                  return i;
                }).toList());
          }
          return MapEntry(warehouseId, items);
        });
        state = AsyncValue.data(
            current.copyWith(warehouseItems: updatedWarehouseItems));
      }
    }
    return success;
  }

  Future<void> incrementQuantity(CartItem item) async {
    await _repository.incrementQuantity(item);
  }

  Future<void> decrementQuantity(CartItem item) async {
    await _repository.decrementQuantity(item);
  }

  Future<void> clearCart() async {
    await _repository.clearCart();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
