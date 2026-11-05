import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/data_push/catalog_seed_data.dart';
import '../constants/app_constants.dart';

class WarehouseDataPush {
  final FirebaseFirestore _firestore;

  WarehouseDataPush({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  Future<void> pushWarehouses() async {
    await clearWarehouses();
    final batch = _firestore.batch();

    for (final warehouse in CatalogSeedData.warehouses) {
      batch.set(
        _firestore.collection(Collections.warehouses).doc(warehouse.id),
        warehouse.toMap(),
      );
    }

    await batch.commit();
    debugPrint('Warehouses pushed successfully');
  }

  Future<void> clearWarehouses() async {
    final snapshot = await _firestore.collection(Collections.warehouses).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
