import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/data_push/catalog_seed_data.dart';
import '../constants/app_constants.dart';

class InventoryDataPush {
  final FirebaseFirestore _firestore;

  InventoryDataPush({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  Future<void> pushInventories() async {
    await clearInventories();
    debugPrint('Pushing ${CatalogSeedData.inventories.length} inventories...');

    const chunkSize = 400;
    final inventories = CatalogSeedData.inventories;

    for (var i = 0; i < inventories.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = inventories.sublist(
        i,
        (i + chunkSize > inventories.length)
            ? inventories.length
            : i + chunkSize,
      );
      for (final inventory in chunk) {
        batch.set(
          _firestore.collection(Collections.inventories).doc(inventory.id),
          inventory.toFirestore(),
        );
      }
      await batch.commit();
    }

    debugPrint('Inventories pushed successfully');
  }

  Future<void> clearInventories() async {
    final snapshot = await _firestore.collection(Collections.inventories).get();
    if (snapshot.docs.isEmpty) return;

    const chunkSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = snapshot.docs.sublist(
        i,
        i + chunkSize > snapshot.docs.length
            ? snapshot.docs.length
            : i + chunkSize,
      );

      for (final doc in chunk) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}
