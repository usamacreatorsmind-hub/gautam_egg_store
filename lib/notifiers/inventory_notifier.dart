import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/inventory_firestore_ds.dart';
import 'package:sure_wholesaler/models/inventory_model.dart';
import 'package:sure_wholesaler/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(InventoryFirestoreDsImpl());
});

/// Real-time inventories for a warehouse.
final inventoriesByWarehouseProvider = StateNotifierProvider.family<
    InventoriesByWarehouseNotifier, AsyncValue<List<Inventory>>, String>(
  (ref, warehouseId) => InventoriesByWarehouseNotifier(
      ref.read(inventoryRepositoryProvider), warehouseId),
);

/// Real-time inventories across all warehouses for a single variant.
final inventoriesByVariantProvider =
    StreamProvider.family<List<Inventory>, String>((ref, variantId) {
  return ref
      .read(inventoryRepositoryProvider)
      .watchInventoriesByVariant(variantId);
});

/// Single inventory doc by ID.
final inventoryByIdProvider =
    StreamProvider.family<Inventory?, String>((ref, inventoryId) {
  return ref.read(inventoryRepositoryProvider).watchInventoryById(inventoryId);
});

class InventoriesByWarehouseNotifier
    extends StateNotifier<AsyncValue<List<Inventory>>> {
  final InventoryRepository _repository;
  final String warehouseId;
  StreamSubscription<List<Inventory>>? _subscription;

  InventoriesByWarehouseNotifier(this._repository, this.warehouseId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchInventoriesByWarehouse(warehouseId).listen(
          (inventories) => state = AsyncValue.data(inventories),
          onError: (e, st) => state = AsyncValue.error(e, st),
        );
  }

  Future<void> setStock(String inventoryId, int stock) =>
      _repository.setStock(inventoryId, stock);

  Future<void> updateInventory(String inventoryId, Map<String, dynamic> data) =>
      _repository.updateInventory(inventoryId, data);

  Future<String> createInventory(Inventory inventory) =>
      _repository.createInventory(inventory);

  Future<void> deleteInventory(String inventoryId) =>
      _repository.deleteInventory(inventoryId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
