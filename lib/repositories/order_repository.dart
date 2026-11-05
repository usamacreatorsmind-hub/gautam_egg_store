import 'package:sure_wholesaler/firebase/order_firestore_ds.dart';
import 'package:sure_wholesaler/models/order_model.dart';

abstract class OrderRepository {
  /// Create a new order and return document ID
  Future<String> createOrder(OrderModel order);

  /// Get order by ID
  Stream<OrderModel?> getOrderById(String orderId);

  /// Get all orders for current user
  Stream<List<OrderModel>> getOrders();

  /// Get orders with a specific status
  Stream<List<OrderModel>> getOrdersByStatus(String status);

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status);

  /// Update order data
  Future<bool> updateOrder(String orderId, OrderModel order);

  /// Watch order by ID (real-time updates)
  Stream<OrderModel?> watchOrderById(String orderId);

  /// Watch orders for current user (real-time updates)
  Stream<List<OrderModel>> watchOrders();

  /// Cancel an order
  Future<bool> cancelOrder(String orderId);

  /// Get current authenticated user ID
  String? getCurrentUserId();

  /// Generate unique order number
  Future<String> generateOrderNumber();
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderFirestoreDs _firestoreDs;

  OrderRepositoryImpl(this._firestoreDs);

  String get _userId {
    final userId = _firestoreDs.getCurrentUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  @override
  Future<String> createOrder(OrderModel order) async {
    try {
      return await _firestoreDs.createOrder(order);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Stream<OrderModel?> getOrderById(String orderId) {
    return _firestoreDs.getOrderById(orderId).map((data) {
      if (data != null) {
        return OrderModel.fromMap(data, orderId);
      }
      return null;
    });
  }

  @override
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      return await _firestoreDs.updateOrderStatus(orderId, status);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  @override
  Future<bool> updateOrder(String orderId, OrderModel order) async {
    try {
      return await _firestoreDs.updateOrder(orderId, order.toMap());
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  @override
  Stream<OrderModel?> watchOrderById(String orderId) {
    try {
      return _firestoreDs.watchOrderById(orderId).map((data) {
        if (data != null) {
          return OrderModel.fromMap(data, orderId);
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to watch order: $e');
    }
  }

  @override
  Stream<List<OrderModel>> watchOrders() {
    try {
      return _firestoreDs.watchOrdersByUser(_userId).map(
            (dataList) => dataList
                .map((map) => OrderModel.fromMap(map, map['id'] ?? ''))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to watch orders: $e');
    }
  }

  @override
  Future<bool> cancelOrder(String orderId) async {
    try {
      return await _firestoreDs.cancelOrder(orderId);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  @override
  String? getCurrentUserId() {
    return _firestoreDs.getCurrentUserId();
  }

  @override
  Future<String> generateOrderNumber() async {
    try {
      return await _firestoreDs.generateOrderNumber();
    } catch (e) {
      throw Exception('Failed to generate order number: $e');
    }
  }

  @override
  Stream<List<OrderModel>> getOrders() {
    try {
      return _firestoreDs.getOrdersByUser(_userId).map(
            (dataList) => dataList
                .map((map) => OrderModel.fromMap(map, map['id'] ?? ''))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  @override
  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    try {
      return _firestoreDs.getOrdersByStatus(_userId, status).map(
            (dataList) => dataList
                .map((map) => OrderModel.fromMap(map, map['id'] ?? ''))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }
}
