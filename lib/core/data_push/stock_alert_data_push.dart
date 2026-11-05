import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/data_push/catalog_seed_data.dart';
import '../constants/app_constants.dart';

class StockAlertDataPush {
  final FirebaseFirestore _firestore;

  StockAlertDataPush({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  Future<void> pushStockAlerts() async {
    await clearStockAlerts();
    final batch = _firestore.batch();

    for (final alert in CatalogSeedData.stockAlerts) {
      batch.set(
        _firestore.collection(Collections.stockAlerts).doc(alert.id),
        {
          'userId': alert.userId,
          'productId': alert.productId,
          'productName': alert.productName,
          'isNotified': alert.isNotified,
          'createdAt': alert.createdAt != null
              ? Timestamp.fromDate(alert.createdAt!)
              : FieldValue.serverTimestamp(),
          if (alert.notifiedAt != null)
            'notifiedAt': Timestamp.fromDate(alert.notifiedAt!),
        },
      );
    }

    await batch.commit();
    debugPrint('Stock alerts pushed successfully');
  }

  Future<void> clearStockAlerts() async {
    final snapshot = await _firestore.collection(Collections.stockAlerts).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
