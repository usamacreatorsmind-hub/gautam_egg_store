import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/subscription_model.dart';

abstract class SubscriptionFirestoreDs {
  Future<String> createSubscription(SubscriptionModel sub);
  Stream<List<SubscriptionModel>> watchByUser(String userId);
  Future<bool> updateStatus(String subId, String status);
  Future<bool> cancel(String subId);
  Stream<SubscriptionModel?> watchById(String subId);
}

class SubscriptionFirestoreDsImpl implements SubscriptionFirestoreDs {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  SubscriptionFirestoreDsImpl({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? AppConfig.firestore,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _col => _db.collection(Collections.subscriptions);

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('User not authenticated.');
    return u.uid;
  }

  /// Writes the subscription to eco_subscriptions.
  /// Stock is NOT touched here — the Cloud Function handles that when each
  /// recurring order is created after admin activation.
  @override
  Future<String> createSubscription(SubscriptionModel sub) async {
    final ref = _col.doc();
    final map = sub.toMap();
    map['id'] = ref.id;
    map['userId'] = _uid;
    await ref.set(map);
    return ref.id;
  }

  /// Real-time stream of all subscriptions for the current user.
  @override
  Stream<List<SubscriptionModel>> watchByUser(String userId) {
    return _col.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) =>
              SubscriptionModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Update status (pause / cancel / reactivate — admin sets active).
  @override
  Future<bool> updateStatus(String subId, String status) async {
    await _col.doc(subId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Convenience: cancel a subscription and restore nothing
  /// (stock was never decremented on subscription creation).
  @override
  Future<bool> cancel(String subId) =>
      updateStatus(subId, SubscriptionStatus.cancelled);

  @override
  Stream<SubscriptionModel?> watchById(String subId) {
    return _col.doc(subId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SubscriptionModel.fromMap(
          snap.data() as Map<String, dynamic>, snap.id);
    });
  }
}

/// Provider for the subscription data source
final subscriptionFirestoreDsProvider =
    Provider<SubscriptionFirestoreDs>((ref) {
  return SubscriptionFirestoreDsImpl();
});

/// Family provider to fetch a single subscription by its ID in real-time
final subscriptionByIdProvider =
    StreamProvider.family<SubscriptionModel?, String>((ref, subId) {
  return ref.watch(subscriptionFirestoreDsProvider).watchById(subId);
});
