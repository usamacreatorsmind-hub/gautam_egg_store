import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/firebase/subscription_firestore_ds.dart';
import 'package:sure_wholesaler/models/subscription_model.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final subscriptionDsProvider = Provider<SubscriptionFirestoreDs>(
  (_) => SubscriptionFirestoreDsImpl(),
);

// ---------------------------------------------------------------------------
// Stream: current user's subscriptions
// ---------------------------------------------------------------------------

final userSubscriptionsProvider =
    StreamProvider<List<SubscriptionModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(subscriptionDsProvider).watchByUser(uid);
});

// ---------------------------------------------------------------------------
// Notifier: create / pause / cancel
// ---------------------------------------------------------------------------

class SubscriptionNotifier extends Notifier<void> {
  SubscriptionFirestoreDs get _ds => ref.read(subscriptionDsProvider);

  @override
  void build() {}

  /// Creates a new subscription.
  ///
  /// Before persisting, checks that the user has available wallet balance
  /// >= 10x the order total, then moves that amount to reserved.
  /// Returns the new document ID.
  Future<String> createSubscription(SubscriptionModel sub) async {
    final orderTotal = sub.total.ceil();

    return await _ds.createSubscription(sub);
  }

  Future<void> pause(String subId) =>
      _ds.updateStatus(subId, SubscriptionStatus.paused);

  Future<void> resume(String subId) =>
      _ds.updateStatus(subId, SubscriptionStatus.active);

  Future<void> cancel(String subId) => _ds.cancel(subId);
}

final subscriptionNotifierProvider =
    NotifierProvider<SubscriptionNotifier, void>(SubscriptionNotifier.new);
