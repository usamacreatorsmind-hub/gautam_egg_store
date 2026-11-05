import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/models/stock_alert_model.dart';

abstract class StockAlertRepository {
  /// Subscribe user for stock alert
  Future<bool> subscribeStockAlert(StockAlertModel stockAlertModel);

  /// Unsubscribe stock alert
  Future<bool> unsubscribeStockAlert({
    required String userId,
    required String productId,
  });

  /// Check subscription
  Future<bool> isSubscribed({
    required String userId,
    required String productId,
  });

  /// Get all alerts for a user (active/pending)
  Stream<List<StockAlertModel>> getUserAlerts(String userId);

  /// Get alerts waiting for notification
  Stream<List<Map<String, dynamic>>> getPendingAlertsByProduct(
    String productId,
  );

  /// Mark alert as notified
  Future<bool> markAsNotified(String alertId);
}

class StockAlertRepositoryImpl implements StockAlertRepository {
  final FirebaseFirestore firestore = AppConfig.firestore;

  static const String _collection = 'stock_alerts';

  /// Get all pending (not notified) alerts for a product
  @override
  Stream<List<Map<String, dynamic>>> getPendingAlertsByProduct(String productId) {
    try {
      return firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .where('isNotified', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            'alertId': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      if (kDebugMode == true) debugPrint('Stream setup failed: $e');
      return Stream.value([]);
    }
  }

  /// Get all alerts for a user (real-time stream)
  @override
  Stream<List<StockAlertModel>> getUserAlerts(String userId) {
    try {
      return firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isNotified', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => StockAlertModel.fromFirestore(doc)).toList();
      });
    } catch (e) {
      if (kDebugMode == true) debugPrint('Get user alerts failed: $e');
      return Stream.value([]);
    }
  }

  /// Check if user already subscribed
  @override
  Future<bool> isSubscribed({
    required String userId,
    required String productId,
  }) async {
    try {
      final query = await firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('isNotified', isEqualTo: false)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode == true) debugPrint('Check subscription failed: $e');
      return false;
    }
  }

  /// Subscribe user for stock alert
  @override
  Future<bool> subscribeStockAlert(StockAlertModel stockAlertModel) async {
    try {
      await firestore.collection(_collection).add(stockAlertModel.toFirestore());

      return true;
    } catch (e) {
      if (kDebugMode == true) debugPrint('Subscribe stock alert failed: $e');
      return false;
    }
  }

  /// Unsubscribe stock alert
  @override
  Future<bool> unsubscribeStockAlert({
    required String userId,
    required String productId,
  }) async {
    try {
      final query = await firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('isNotified', isEqualTo: false)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      if (kDebugMode == true) debugPrint('Unsubscribe stock alert failed: $e');
      return false;
    }
  }

  /// Mark alert as notified (called by backend / cloud function)
  @override
  Future<bool> markAsNotified(String alertId) async {
    try {
      await firestore.collection(_collection).doc(alertId).update({
        'isNotified': true,
        'notifiedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode == true) debugPrint('Mark stock alert notified failed: $e');
      return false;
    }
  }
}
