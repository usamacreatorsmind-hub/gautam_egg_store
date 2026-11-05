import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sure_wholesaler/notifiers/order_notifier.dart';
import 'package:sure_wholesaler/screens/orders/order_detail_screen.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

/// Wrapper screen that loads an order by ID and displays [OrderDetailScreen].
/// Used for notification tap navigation where only the orderId is available.
class OrderDetailByIdScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailByIdScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdStreamProvider(orderId));

    return orderAsync.when(
      loading: () => const Scaffold(
        body: Center(child: AppLoader()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load order',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 48),
                  const SizedBox(height: 16),
                  Text('Order not found',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return OrderDetailScreen(order: order);
      },
    );
  }
}
