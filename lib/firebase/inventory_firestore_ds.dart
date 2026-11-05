import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/inventory_model.dart';

abstract class InventoryFirestoreDs {
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

class InventoryFirestoreDsImpl implements InventoryFirestoreDs {
  final FirebaseFirestore _firestore;

  InventoryFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _col =>
      _firestore.collection(Collections.inventories);

  Inventory _fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    return Inventory.fromMap(data).copyWith(id: doc.id);
  }

  @override
  Stream<List<Inventory>> watchInventoriesByWarehouse(String warehouseId) {
    return _col
        .where('warehouseId', isEqualTo: warehouseId)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<List<Inventory>> watchInventoriesByVariant(String variantId) {
    return _col
        .where('variantId', isEqualTo: variantId)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<Inventory?> watchInventoryById(String inventoryId) {
    return _col
        .doc(inventoryId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  @override
  Future<Inventory?> getInventoryById(String inventoryId) async {
    final doc = await _col.doc(inventoryId).get();
    return doc.exists ? _fromDoc(doc) : null;
  }

  @override
  Future<List<Inventory>> getInventoriesByVariantIds(
      List<String> variantIds) async {
    if (variantIds.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < variantIds.length; i += 30) {
      chunks.add(variantIds.sublist(
          i, (i + 30 > variantIds.length) ? variantIds.length : i + 30));
    }
    final results = <Inventory>[];
    for (final chunk in chunks) {
      final snap = await _col.where('variantId', whereIn: chunk).get();
      results.addAll(snap.docs.map(_fromDoc));
    }
    return results;
  }

  @override
  Future<String> createInventory(Inventory inventory) async {
    final ref = _col.doc();
    await ref.set(inventory.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateInventory(
      String inventoryId, Map<String, dynamic> data) async {
    await _col.doc(inventoryId).update(data);
  }

  @override
  Future<void> setStock(String inventoryId, int stock) async {
    await _col.doc(inventoryId).update({
      'stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteInventory(String inventoryId) async {
    await _col.doc(inventoryId).delete();
  }
}
