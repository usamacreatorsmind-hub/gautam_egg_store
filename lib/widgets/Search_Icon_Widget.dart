import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';

import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';

class SearchIconWidget extends ConsumerStatefulWidget {
  const SearchIconWidget({super.key});

  @override
  ConsumerState<SearchIconWidget> createState() => _SearchIconWidgetState();
}

class _SearchIconWidgetState extends ConsumerState<SearchIconWidget> {
  List<ProductModel> allProducts = [];
  List<ProductModel> filteredProducts = [];
  List<ProductModel> displayedProducts = [];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  final int _itemsPerPage = 12;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (_hasMoreData && !_isLoadingMore) {
        _loadMoreProducts();
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = query.isEmpty
          ? allProducts
          : allProducts.where((p) {
              final q = query.toLowerCase();
              return p.name.toLowerCase().contains(q) || (p.description?.toLowerCase().contains(q) ?? false);
            }).toList();

      _currentPage = 1;
      displayedProducts.clear();
      _hasMoreData = true;
      _displayCurrentPage();
    });
  }

  void _displayCurrentPage() {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;

    if (start >= filteredProducts.length) {
      _hasMoreData = false;
      return;
    }

    displayedProducts.addAll(
      filteredProducts.sublist(
        start,
        end > filteredProducts.length ? filteredProducts.length : end,
      ),
    );

    _hasMoreData = end < filteredProducts.length;
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _currentPage++;
      _displayCurrentPage();
      _isLoadingMore = false;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      filteredProducts = allProducts;
      displayedProducts.clear();
      _currentPage = 1;
      _hasMoreData = true;
      _displayCurrentPage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    productsAsync.whenData((products) {
      if (allProducts.isEmpty && products.isNotEmpty) {
        allProducts = products;
        filteredProducts = products;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _displayCurrentPage();
          setState(() {});
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              onChanged: _filterProducts,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                hintStyle: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: productsAsync.isLoading && displayedProducts.isEmpty
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: theme.colorScheme.primary,
                size: 60.sp,
              ),
            )
          : productsAsync.hasError && displayedProducts.isEmpty
              ? Center(
                  child: Text(
                    'Error loading products',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : displayedProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80.sp,
                            color: theme.colorScheme.outline,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _searchController.text.isEmpty ? 'No products available' : 'No results for "${_searchController.text}"',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          if (_searchController.text.isNotEmpty)
                            TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Clear search'),
                            ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Text(
                                '${displayedProducts.length}${_hasMoreData ? '+' : ''} of '
                                '${filteredProducts.length} products found',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8.w,
                              mainAxisSpacing: 12.h,
                              childAspectRatio: ProductCardWidget.gridWidth / ProductCardWidget.gridHeight,
                            ),
                            itemCount: displayedProducts.length,
                            itemBuilder: (_, index) => ProductCardWidget(
                              key: ValueKey(displayedProducts[index].id),
                              onTap: () {
                                context.push(
                                  '/product/${displayedProducts[index].id}',
                                  extra: displayedProducts[index],
                                );
                              },
                              onAddToCart: () async {
                                final product = displayedProducts[index];
                                final activeVariants = product.activePackVariants;
                                if (activeVariants.isEmpty) {
                                  AppNotifications.showError(
                                    context,
                                    title: 'Error',
                                    message: 'No pack variants available',
                                  );
                                  return;
                                }

                                final variant = activeVariants.first;
                                if (variant.stock <= 0) {
                                  AppNotifications.showError(
                                    context,
                                    title: 'Error',
                                    message: 'This product is out of stock',
                                  );
                                  return;
                                }

                                final warehouseId = variant.inventory?.warehouseId ??
                                    ref.read(cartProvider).value?.warehouseId ??
                                    ref.read(resolvedWarehouseProvider).firstOrNull ??
                                    'default';
                                final availableReachableTypes = variant.availableDeliveryTypes;

                                if (availableReachableTypes.isEmpty || warehouseId == 'default') {
                                  if (!mounted) return;
                                  AppNotifications.showError(
                                    context,
                                    title: 'Error',
                                    message: 'This product is out of reach for the selected warehouse',
                                  );
                                  return;
                                }

                                final deliveryType = availableReachableTypes.first;

                                ref.read(cartProvider.notifier).addToCart(
                                      CartItem.fromVariant(
                                        variant: variant,
                                        deliveryType: deliveryType,
                                        warehouseId: warehouseId,
                                      ),
                                    );

                                AppNotifications.showPremiumNotification(
                                  context,
                                  title: 'Success',
                                  message: '${product.name} (Pack of ${variant.packSize}) added to cart',
                                  buttonLabel: 'VIEW CART',
                                  onButtonPressed: () {
                                    final tab = deliveryType == DeliveryType.scheduled ? 1 : 0;
                                    context.push('/cart?tab=$tab');
                                  },
                                );
                              },
                              product: displayedProducts[index],
                            ),
                          ),
                          if (_isLoadingMore)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: theme.colorScheme.primary,
                                  size: 40.sp,
                                ),
                              ),
                            ),
                          if (!_hasMoreData && displayedProducts.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: Center(
                                child: Text(
                                  'All ${filteredProducts.length} products loaded',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
