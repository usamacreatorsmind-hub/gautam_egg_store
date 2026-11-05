import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/firebase/order_firestore_ds.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/repositories/order_repository.dart';

import '../core/constants/app_status.dart';

/// Repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(OrderFirestoreDsImpl());
});

/// Main orders provider (AsyncNotifier)
final orderProvider = AsyncNotifierProvider<OrderNotifier, List<OrderModel>>(
  OrderNotifier.new,
);

// Subscription order toggle disabled project-wide.
// final showSubscriptionOrdersProvider = StateProvider<bool>((ref) => false);

/// Base list for regular orders only.
final _ordersBaseProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderProvider).value ?? [];
  return orders.where((o) => !o.isSubscriptionOrder).toList();
});

/// Only regular (non-subscription) orders — used by the Orders tab.
final regularOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderProvider).value ?? [];
  return orders.where((o) => !o.isSubscriptionOrder).toList();
});

final pendingOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => o.isPending).toList();
});

final confirmedOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => o.isConfirmed).toList();
});

final processingOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => o.status == OrderStatus.packed).toList();
});

final shippedOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => o.status == OrderStatus.outForDelivery).toList();
});

final deliveredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => o.isDelivered).toList();
});

final cancelledOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => o.isCancelled).toList();
});

final activeOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(_ordersBaseProvider);
  return orders.where((o) => !o.isDelivered && !o.isCancelled).toList();
});

/// Real-time stream of orders created by the Cloud Function for a specific subscription.
final ordersForSubscriptionProvider = StreamProvider.family<List<OrderModel>, String>((ref, subscriptionId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return AppConfig.firestore
      .collection(Collections.orders)
      .where('subscriptionId', isEqualTo: subscriptionId)
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
    final list = snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final orderByIdProvider = Provider.family<OrderModel?, String>((ref, orderId) {
  final orders = ref.watch(orderProvider).value ?? [];
  return orders.cast<OrderModel?>().firstWhere(
        (o) => o!.id == orderId,
        orElse: () => null,
      );
});

final orderByIdStreamProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final repository = ref.read(orderRepositoryProvider);
  return repository.watchOrderById(orderId);
});

final orderCreatingProvider = StateProvider<bool>((ref) => false);

final orderStatusFilterProvider = StateProvider<String?>((ref) => null);

enum OrderDeliveryFilter { all, quick, scheduled }

final orderDeliveryFilterProvider = StateProvider<OrderDeliveryFilter>((ref) => OrderDeliveryFilter.all);

final filteredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderProvider).value ?? [];
  final statusFilter = ref.watch(orderStatusFilterProvider);

  if (statusFilter == null || statusFilter.isEmpty) {
    return orders;
  }

  return orders.where((o) => o.status == statusFilter).toList();
});

class OrderNotifier extends AsyncNotifier<List<OrderModel>> {
  OrderRepository get _repository => ref.read(orderRepositoryProvider);

  @override
  Future<List<OrderModel>> build() async {
    final repository = _repository;
    final completer = Completer<List<OrderModel>>();

    final subscription = repository.watchOrders().listen(
      (orders) {
        if (!completer.isCompleted) completer.complete(orders);
        state = AsyncValue.data(orders);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
        state = AsyncValue.error(error, stackTrace);
      },
    );

    ref.onDispose(() => subscription.cancel());

    return completer.future;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getOrders().first,
    );
  }

  Future<String?> createOrder(OrderModel order) async {
    try {
      return await _repository.createOrder(order);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      return await _repository.updateOrderStatus(orderId, status);
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      return await _repository.cancelOrder(orderId);
    } catch (_) {
      return false;
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    return await _repository.getOrderById(orderId).first;
  }

  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    return await _repository.getOrdersByStatus(status).first;
  }

  Future<String> generateOrderNumber() async {
    return await _repository.generateOrderNumber();
  }
}
