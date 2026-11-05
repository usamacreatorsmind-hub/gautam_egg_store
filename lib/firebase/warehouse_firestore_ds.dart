import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';

abstract class WarehouseFirestoreDs {
  Stream<List<Warehouse>> watchWarehouses();
  Stream<List<Warehouse>> watchActiveWarehouses();
  Stream<Warehouse?> watchWarehouseById(String warehouseId);
  Future<Warehouse?> getWarehouseById(String warehouseId);
  Future<List<Warehouse>> getAllWarehouses();
  Future<String> createWarehouse(Warehouse warehouse);
  Future<void> updateWarehouse(String warehouseId, Map<String, dynamic> data);
  Future<void> deleteWarehouse(String warehouseId);
}

class WarehouseFirestoreDsImpl implements WarehouseFirestoreDs {
  final FirebaseFirestore _firestore;

  WarehouseFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _col => _firestore.collection(Collections.warehouses);

  Warehouse _fromDoc(DocumentSnapshot doc) => Warehouse.fromFirestore(doc);

  @override
  Stream<List<Warehouse>> watchWarehouses() {
    return _col.snapshots().map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<List<Warehouse>> watchActiveWarehouses() {
    return _col
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<Warehouse?> watchWarehouseById(String warehouseId) {
    return _col
        .doc(warehouseId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  @override
  Future<Warehouse?> getWarehouseById(String warehouseId) async {
    final doc = await _col.doc(warehouseId).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<List<Warehouse>> getAllWarehouses() async {
    final snap = await _col.get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<String> createWarehouse(Warehouse warehouse) async {
    final ref = _col.doc();
    await ref.set(warehouse.toMap());
    return ref.id;
  }

  @override
  Future<void> updateWarehouse(
      String warehouseId, Map<String, dynamic> data) async {
    await _col.doc(warehouseId).update(data);
  }

  @override
  Future<void> deleteWarehouse(String warehouseId) async {
    await _col.doc(warehouseId).delete();
  }
}
