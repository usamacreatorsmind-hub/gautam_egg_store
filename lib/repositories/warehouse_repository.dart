import 'package:sure_wholesaler/firebase/warehouse_firestore_ds.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';

abstract class WarehouseRepository {
  Stream<List<Warehouse>> watchWarehouses();
  Stream<List<Warehouse>> watchActiveWarehouses();
  Stream<Warehouse?> watchWarehouseById(String warehouseId);
  Future<Warehouse?> getWarehouseById(String warehouseId);
  Future<List<Warehouse>> getAllWarehouses();
  Future<String> createWarehouse(Warehouse warehouse);
  Future<void> updateWarehouse(String warehouseId, Map<String, dynamic> data);
  Future<void> deleteWarehouse(String warehouseId);
}

class WarehouseRepositoryImpl implements WarehouseRepository {
  final WarehouseFirestoreDs _ds;

  WarehouseRepositoryImpl(this._ds);

  @override
  Stream<List<Warehouse>> watchWarehouses() => _ds.watchWarehouses();

  @override
  Stream<List<Warehouse>> watchActiveWarehouses() =>
      _ds.watchActiveWarehouses();

  @override
  Stream<Warehouse?> watchWarehouseById(String warehouseId) =>
      _ds.watchWarehouseById(warehouseId);

  @override
  Future<Warehouse?> getWarehouseById(String warehouseId) =>
      _ds.getWarehouseById(warehouseId);

  @override
  Future<List<Warehouse>> getAllWarehouses() => _ds.getAllWarehouses();

  @override
  Future<String> createWarehouse(Warehouse warehouse) =>
      _ds.createWarehouse(warehouse);

  @override
  Future<void> updateWarehouse(String warehouseId, Map<String, dynamic> data) =>
      _ds.updateWarehouse(warehouseId, data);

  @override
  Future<void> deleteWarehouse(String warehouseId) =>
      _ds.deleteWarehouse(warehouseId);
}
