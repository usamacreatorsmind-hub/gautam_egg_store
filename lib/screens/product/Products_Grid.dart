import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';

class ProductsGrid extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final DeliveryType? deliveryType;
  final String? warehouseId;
  final List<String>? warehouseIds;
  final bool subscriptionOnly;
  final int? maxItems;
  final String searchQuery;

  const ProductsGrid({
    super.key,
    this.scrollController,
    this.deliveryType,
    this.warehouseId,
    this.warehouseIds,
    this.subscriptionOnly = false,
    this.maxItems,
    this.searchQuery = '',
  });

  @override
  ConsumerState<ProductsGrid> createState() => _ProductsGridState();
}

class _ProductsGridState extends ConsumerState<ProductsGrid> {
  ProductsParams get _params => ProductsParams(
        deliveryType: widget.deliveryType,
        warehouseIds: widget.warehouseIds ??
            (widget.warehouseId != null ? [widget.warehouseId!] : null),
      );

  void _loadProducts() {
    Future.microtask(() {
      ref.read(paginatedProductsProvider(_params).notifier).loadProducts();
    });
  }

  void _scrollListener() {
    final state = ref.read(paginatedProductsProvider(_params));
    if (widget.scrollController != null &&
        widget.scrollController!.position.pixels >=
            widget.scrollController!.position.maxScrollExtent - 200 &&
        !state.isLoading &&
        state.hasMore) {
      ref.read(paginatedProductsProvider(_params).notifier).loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    widget.scrollController?.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_scrollListener);
      widget.scrollController?.addListener(_scrollListener);
    }

    if (oldWidget.deliveryType != widget.deliveryType ||
        oldWidget.warehouseId != widget.warehouseId ||
        oldWidget.warehouseIds != widget.warehouseIds) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(paginatedProductsProvider(_params));
    final allProducts = widget.subscriptionOnly
        ? state.products
            .where((product) => product.activePackVariants.any(
                  (variant) => variant.isSubscriptionAvailable,
                ))
            .toList()
        : state.products;
    final normalizedQuery = widget.searchQuery.trim().toLowerCase();
    final filteredProducts = normalizedQuery.isEmpty
        ? allProducts
        : allProducts.where((product) {
            final haystack = [
              product.name,
              product.brandName ?? '',
              product.sku,
              product.description ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(normalizedQuery);
          }).toList();
    final displayedProducts = widget.maxItems != null
        ? filteredProducts.take(widget.maxItems!).toList()
        : filteredProducts;
    final showPaginationLoader = widget.maxItems == null &&
        state.hasMore &&
        normalizedQuery.isEmpty &&
        (!widget.subscriptionOnly || displayedProducts.isNotEmpty);

    if (state.isLoading && displayedProducts.isEmpty) {
      return SizedBox(
        height: 150.h,
        child: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: theme.colorScheme.primary,
            size: 60.sp,
          ),
        ),
      );
    }

    if (state.error != null) {
      return SizedBox(
        height: 150.h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 40.sp),
              SizedBox(height: 12.h),
              Text(
                'Could not load products',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6.h),
              Text(
                state.error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(paginatedProductsProvider(_params).notifier)
                    .loadProducts(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (displayedProducts.isEmpty) {
      return SizedBox(
        height: 220.h,
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 28.h,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.18),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.03),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Icon Circle
                Container(
                  height: 78.w,
                  width: 78.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.08),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 38.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),

                SizedBox(height: 18.h),

                /// Title
                Text(
                  normalizedQuery.isEmpty
                      ? "No Products Available"
                      : "No Matching Products",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8.h),

                /// Subtitle
                Text(
                  widget.subscriptionOnly
                      ? (normalizedQuery.isEmpty
                          ? 'Subscription products are currently unavailable.'
                          : 'Try searching with a different keyword.')
                      : (normalizedQuery.isEmpty
                          ? 'Products will appear here once available.'
                          : 'We couldn’t find products matching your search.'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 18.h),

                /// Optional Action
                if (normalizedQuery.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      // clear search
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Clear Search"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: ProductCardWidget.gridWidth / ProductCardWidget.gridHeight,
      ),
      itemCount: displayedProducts.length + (showPaginationLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= displayedProducts.length) {
          return Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: theme.colorScheme.primary,
              size: 50.sp,
            ),
          );
        }

        return ProductCardWidget(
          key: ValueKey(displayedProducts[index].id),
          onTap: () {
            context.push('/product/${displayedProducts[index].id}',
                extra: displayedProducts[index]);
          },
          onAddToCart: () {
            final activeVariants = displayedProducts[index].activePackVariants;
            if (activeVariants.isEmpty) {
              AppNotifications.showError(
                context,
                title: 'Error',
                message: 'No pack variants available',
              );
              return;
            }
          },
          product: displayedProducts[index],
        );
      },
    );
  }
}
