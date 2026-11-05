import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/order_notifier.dart';

class BuyAgainItem {
  final ProductModel product;
  final OrderProductDetail detail;
  final DateTime lastOrderedAt;

  const BuyAgainItem({
    required this.product,
    required this.detail,
    required this.lastOrderedAt,
  });
}

/// Up to 10 unique products from delivered orders, most recently ordered first.
final buyAgainProvider = Provider<List<BuyAgainItem>>((ref) {
  final orders = ref.watch(deliveredOrdersProvider);

  final sorted = [...orders]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final seen = <String>{};
  final result = <BuyAgainItem>[];

  for (final order in sorted) {
    for (final product in order.products) {
      final id = product.id;
      if (id == null || !seen.add(id)) continue;

      final detail = order.productDetails[id];
      if (detail == null) continue;

      result.add(BuyAgainItem(
        product: product,
        detail: detail,
        lastOrderedAt: order.createdAt,
      ));

      if (result.length >= 10) return result;
    }
  }

  return result;
});
