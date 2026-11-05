import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/data_push/catalog_seed_data.dart';
import '../constants/app_constants.dart';

class ProductDataPush {
  final FirebaseFirestore _firestore;

  ProductDataPush({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  Future<void> pushData() async {
    await clearData();
    debugPrint('Pushing products, variants, warehouses, and inventories...');
    await _pushWarehouses();
    await _pushVariants();
    await _pushProducts();
    await _pushInventories();
    debugPrint('Catalog data pushed successfully');
  }

  /// Push only products and pack variants (no warehouses / inventories).
  Future<void> pushProductsAndVariants() async {
    await _pushVariants();
    await _pushProducts();
    debugPrint('Products and pack variants pushed successfully');
  }

  /// Clear only the products and pack variants collections.
  Future<void> clearProductsAndVariants() async {
    await _deleteCollection(Collections.variants);
    await _deleteCollection(Collections.products);
  }

  Future<void> _pushProducts() async {
    final batch = _firestore.batch();

    for (final product in CatalogSeedData.products) {
      final productId = product.id;
      if (productId == null || productId.isEmpty) continue;

      batch.set(
        _firestore.collection(Collections.products).doc(productId),
        {
          ...product.toFirestore(),
          'createdAt': Timestamp.fromDate(
            product.createdAt ?? CatalogSeedData.now,
          ),
          'updatedAt': Timestamp.fromDate(
            product.updatedAt ?? CatalogSeedData.now,
          ),
        },
      );
    }

    await batch.commit();
  }

  Future<void> _pushVariants() async {
    final now = CatalogSeedData.now;
    const chunkSize = 400;

    for (var i = 0; i < CatalogSeedData.variants.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = CatalogSeedData.variants.sublist(
        i,
        (i + chunkSize > CatalogSeedData.variants.length)
            ? CatalogSeedData.variants.length
            : i + chunkSize,
      );
      for (final variant in chunk) {
        batch.set(
          _firestore.collection(Collections.variants).doc(variant.id),
          {
            ...variant.toFirestore(),
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          },
        );
      }
      await batch.commit();
    }
  }

  Future<void> _pushWarehouses() async {
    final batch = _firestore.batch();

    for (final warehouse in CatalogSeedData.warehouses) {
      batch.set(
        _firestore.collection(Collections.warehouses).doc(warehouse.id),
        warehouse.toMap(),
      );
    }

    await batch.commit();
  }

  Future<void> _pushInventories() async {
    final batch = _firestore.batch();

    for (final inventory in CatalogSeedData.inventories) {
      batch.set(
        _firestore.collection(Collections.inventories).doc(inventory.id),
        inventory.toMap(),
      );
    }

    await batch.commit();
  }

  Future<void> clearData() async {
    await _deleteCollection(Collections.products);
    await _deleteCollection(Collections.variants);
    await _deleteCollection(Collections.inventories);
    await _deleteCollection(Collections.warehouses);
  }

  Future<void> _deleteCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
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
