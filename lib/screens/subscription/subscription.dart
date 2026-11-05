import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/screens/product/Products_Grid.dart';
import 'package:sure_wholesaler/widgets/components.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

final subscriptionProductsProvider =
    Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  return productsAsync.whenData(
    (products) => products
        .where((product) => product.activePackVariants.any(
              (variant) => variant.isSubscriptionAvailable,
            ))
        .toList(),
  );
});

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(subscriptionProductsProvider);
    final selectedWarehouses = ref.watch(resolvedWarehouseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text('Unable to load subscription products: $error'),
          ),
        ),
        data: (products) {
          debugPrint(
              'SubscriptionScreen: Active warehouse IDs are $selectedWarehouses');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppSearchField(
                    controller: _searchController,
                    hintText: 'Search subscription products...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                ProductsGrid(
                  warehouseIds: selectedWarehouses,
                  subscriptionOnly: true,
                  searchQuery: _searchQuery,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
