import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/models/stock_alert_model.dart';
import 'package:sure_wholesaler/repositories/stock_alert_repository.dart';

// ─── Repository Provider ───
final stockAlertRepositoryProvider = Provider<StockAlertRepository>((ref) {
  return StockAlertRepositoryImpl();
});

// ─── User's Stock Alerts (list screen) ───
final userStockAlertsProvider = StateNotifierProvider<UserStockAlertsNotifier,
    AsyncValue<List<StockAlertModel>>>((ref) {
  final repository = ref.read(stockAlertRepositoryProvider);
  return UserStockAlertsNotifier(repository);
});

// ─── Subscription check for a specific product ───
final isSubscribedProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return false;

  final repository = ref.read(stockAlertRepositoryProvider);
  return repository.isSubscribed(userId: userId, productId: productId);
});

/// Manages the list of stock alerts for the current user
class UserStockAlertsNotifier
    extends StateNotifier<AsyncValue<List<StockAlertModel>>> {
  final StockAlertRepository _repository;
  StreamSubscription<List<StockAlertModel>>? _subscription;

  UserStockAlertsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    _subscription = _repository.getUserAlerts(userId).listen(
      (alerts) {
        state = AsyncValue.data(alerts);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  /// Subscribe to stock alert for a product
  Future<bool> subscribe({
    required String productId,
    required String productName,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final alert = StockAlertModel(
      id: '',
      userId: userId,
      productId: productId,
      productName: productName,
    );

    return await _repository.subscribeStockAlert(alert);
  }

  /// Unsubscribe from stock alert for a product
  Future<bool> unsubscribe({required String productId}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    return await _repository.unsubscribeStockAlert(
      userId: userId,
      productId: productId,
    );
  }

  /// Check if user is subscribed for a specific product
  Future<bool> isSubscribed({required String productId}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    return await _repository.isSubscribed(
      userId: userId,
      productId: productId,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
