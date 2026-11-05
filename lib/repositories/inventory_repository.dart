import 'package:sure_wholesaler/firebase/inventory_firestore_ds.dart';
import 'package:sure_wholesaler/models/inventory_model.dart';

abstract class InventoryRepository {
  Stream<List<Inventory>> watchInventoriesByWarehouse(String warehouseId);
  Stream<List<Inventory>> watchInventoriesByVariant(String variantId);
  Stream<Inventory?> watchInventoryById(String inventoryId);
  Future<Inventory?> getInventoryById(String inventoryId);
  Future<List<Inventory>> getInventoriesByVariantIds(List<String> variantIds);
  Future<String> createInventory(Inventory inventory);
  Future<void> updateInventory(String inventoryId, Map<String, dynamic> data);
  Future<void> setStock(String inventoryId, int stock);
  Future<void> deleteInventory(String inventoryId);
}

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryFirestoreDs _ds;

  InventoryRepositoryImpl(this._ds);

  @override
  Stream<List<Inventory>> watchInventoriesByWarehouse(String warehouseId) =>
      _ds.watchInventoriesByWarehouse(warehouseId);

  @override
  Stream<List<Inventory>> watchInventoriesByVariant(String variantId) =>
      _ds.watchInventoriesByVariant(variantId);

  @override
  Stream<Inventory?> watchInventoryById(String inventoryId) =>
      _ds.watchInventoryById(inventoryId);

  @override
  Future<Inventory?> getInventoryById(String inventoryId) =>
      _ds.getInventoryById(inventoryId);

  @override
  Future<List<Inventory>> getInventoriesByVariantIds(List<String> variantIds) =>
      _ds.getInventoriesByVariantIds(variantIds);

  @override
  Future<String> createInventory(Inventory inventory) =>
      _ds.createInventory(inventory);

  @override
  Future<void> updateInventory(String inventoryId, Map<String, dynamic> data) =>
      _ds.updateInventory(inventoryId, data);

  @override
  Future<void> setStock(String inventoryId, int stock) =>
      _ds.setStock(inventoryId, stock);

  @override
  Future<void> deleteInventory(String inventoryId) =>
      _ds.deleteInventory(inventoryId);
}
