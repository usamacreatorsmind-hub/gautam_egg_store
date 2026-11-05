import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';

import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:sure_wholesaler/models/product_model.dart';

// Slider click then open
class ProductsWidget extends ConsumerStatefulWidget {
  final String sliderTitle;
  final List<String> categoryIds;

  const ProductsWidget({
    super.key,
    required this.categoryIds,
    required this.sliderTitle,
  });

  @override
  ConsumerState<ProductsWidget> createState() => _ProductsWidgetState();
}

class _ProductsWidgetState extends ConsumerState<ProductsWidget> {
  List<ProductModel> allProducts = [];
  List<ProductModel> displayedProducts = [];

  int _currentPage = 1;
  final int _itemsPerPage = 12;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  final ScrollController _scrollController = ScrollController();

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

  void _displayCurrentPage() {
    if (allProducts.isEmpty) return;

    final endIndex = _currentPage * _itemsPerPage;

    displayedProducts = allProducts.sublist(
      0,
      endIndex > allProducts.length ? allProducts.length : endIndex,
    );

    _hasMoreData = endIndex < allProducts.length;
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMoreData || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _currentPage++;
      _displayCurrentPage();
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productsAsync = ref.watch(productsByCategoriesProvider(widget.categoryIds));

    productsAsync.whenData((products) {
      if (allProducts.isEmpty && products.isNotEmpty) {
        allProducts = products;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(_displayCurrentPage);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sliderTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: IconButton(
              icon: CircleAvatar(
                radius: 16.r,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 16.sp,
                  color: theme.colorScheme.primary,
                ),
              ),
              onPressed: () {
                context.push('/cart');
              },
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: theme.colorScheme.primary,
            size: 60.sp,
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error loading products',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products available',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Column(
                children: [
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
                    itemBuilder: (_, index) {
                      return ProductCardWidget(
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
                      );
                    },
                  ),
                  if (_isLoadingMore)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: theme.colorScheme.primary,
                        size: 40.sp,
                      ),
                    ),
                  if (!_hasMoreData && allProducts.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        'No more products',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
