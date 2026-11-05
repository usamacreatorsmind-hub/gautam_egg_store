import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/favorites_notifier.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class FavoriteProductsScreen extends ConsumerWidget {
  const FavoriteProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using favoriteProductsProvider ensures variants and prices are loaded
    final favoriteProductsAsync = ref.watch(favoriteProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        centerTitle: true,
      ),
      body: favoriteProductsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildFavoritesGrid(products);
        },
        loading: () => Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: theme.colorScheme.primary,
            size: 50,
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80.sp, color: AppColors.grey500),
          SizedBox(height: 16.h),
          Text(
            'No favorites yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8.h),
          Text(
            'Start adding items you love!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.goToHome(),
            child: const Text('Go Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid(List<ProductModel> products) {
    return Consumer(
      builder: (context, ref, child) {
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 20.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCardWidget(
              product: product,
              onAddToCart: () => _onAddToCart(context, ref, product),
            );
          },
        );
      },
    );
  }

  void _onAddToCart(BuildContext context, WidgetRef ref, ProductModel product) {
    final activeVariants = product.activePackVariants;
    if (activeVariants.isEmpty) return;

    final variant = activeVariants.first;
    if (variant.stock <= 0) return;

    final deliveryType = variant.availableDeliveryTypes.isNotEmpty ? variant.availableDeliveryTypes.first : DeliveryType.quick;

    final warehouseId = variant.inventory?.warehouseId ??
        ref.read(cartProvider).value?.warehouseId ??
        ref.read(resolvedWarehouseProvider).firstOrNull ??
        'default';

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
      message: '${product.name} added to cart',
      buttonLabel: 'VIEW CART',
      onButtonPressed: () => context.goToCart(),
    );
  }
}

/// ---------------- WIDGETS ----------------

class FavoriteButton extends ConsumerWidget {
  final String productId;
  final double? size;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.productId,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);

    return favoriteIdsAsync.when(
      data: (ids) {
        final isFav = ids.contains(productId);
        return InkWell(
          onTap: () async {
            final wasFav = ids.contains(productId);
            await ref.read(favoritesNotifierProvider.notifier).toggle(productId);
            
            AppNotifications.showPremiumNotification(
              context,
              title: wasFav ? 'Removed' : 'Success',
              message: wasFav ? 'Removed from favorites' : 'Added to favorites',
            );
          },
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppColors.error : AppColors.grey500,
              size: size ?? 24.sp,
            ),
          ),
        );
      },
      loading: () => SizedBox(
        width: size ?? 24,
        height: size ?? 24,
        child: const AppLoader(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.favorite_border),
    );
  }
}
