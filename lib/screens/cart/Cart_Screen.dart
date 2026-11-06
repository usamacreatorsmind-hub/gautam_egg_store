import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/constants/asset_constants.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
// import 'package:sure_wholesaler/features/business_kyc/models/business_kyc_model.dart';
// import 'package:sure_wholesaler/features/business_kyc/providers/business_kyc_providers.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/notifiers/variant_notifier.dart';
import 'package:sure_wholesaler/services/warehouse_service.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import '../../core/constants/app_constants.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({
    super.key,
    this.subscriptionOnly = false,
    this.embedded = false,
  });

  final bool subscriptionOnly;

  // When true, skips Scaffold/AppBar â€” for embedding inside another tab screen.
  final bool embedded;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Set<String> _itemsPendingDeletion = {};

  @override
  void initState() {
    super.initState();
  }

  /// Unique key for a cart item (warehouse + product + variant)
  String _itemKey(CartItem item) => '${item.warehouseId}_${item.productId}_${item.packVariantId}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subscriptionOnly = widget.subscriptionOnly;

    final productsAsync = ref.watch(cartItemsProvider);
    final cartAsync = ref.watch(cartProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Cart")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("Please log in to view your cart"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text("Login"),
              ),
            ],
          ),
        ),
      );
    }
    final tabContent = productsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: AppLoader()),
      error: (e, stacktrace) {
        debugPrint("Error loading products for cart: $e");
        return const Center(child: Text("Something went wrong"));
      },
      data: (products) {
        final cartItemModel = cartAsync.value;
        if (cartItemModel == null) {
          return const Center(child: AppLoader());
        }
        return _buildTabContent(
          warehouseItems: cartItemModel.warehouseItems,
          products: products,
          deliveryType: DeliveryType.quick,
          subscriptionOnly: subscriptionOnly,
          emptyTitle: subscriptionOnly ? 'No scheduled subscription items' : 'Your cart is empty',
          emptySubtitle:
              subscriptionOnly ? 'Add scheduled subscription products to see them here' : 'Add products to your cart to see them here',
        );
      },
    );

    if (widget.embedded) {
      return Column(
        children: [
          Expanded(child: tabContent),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyActions: true, // Allow back button if navigated to
        title: Text(
          subscriptionOnly ? 'Subscription Cart' : 'My Cart',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        ),
      ),
      body: productsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: AppLoader()),
        error: (e, stacktrace) => const Center(child: Text("Something went wrong")),
        data: (products) {
          final cartItemModel = cartAsync.value;
          if (cartItemModel == null) return const Center(child: AppLoader());

          // Show all items (both Standard and Scheduled) in a unified view
          return _buildUnifiedContent(
            warehouseItems: cartItemModel.warehouseItems,
            products: products,
            subscriptionOnly: subscriptionOnly,
          );
        },
      ),
    );
  }

  Widget _buildUnifiedContent({
    required Map<String, List<CartItem>> warehouseItems,
    required Map<String, ProductModel> products,
    required bool subscriptionOnly,
  }) {
    // Group by delivery type
    final quickSections = <String, List<CartItem>>{};
    final scheduledSections = <String, List<CartItem>>{};

    for (final entry in warehouseItems.entries) {
      final quick = entry.value.where((item) {
        if (_itemsPendingDeletion.contains(_itemKey(item))) return false;
        final isQuick = item.selectedDeliveryType == null || item.selectedDeliveryType == DeliveryType.quick;
        return subscriptionOnly ? (item.isSubscription && isQuick) : (!item.isSubscription && isQuick);
      }).toList();

      final scheduled = entry.value.where((item) {
        if (_itemsPendingDeletion.contains(_itemKey(item))) return false;
        final isScheduled = item.selectedDeliveryType == DeliveryType.scheduled;
        return subscriptionOnly ? (item.isSubscription && isScheduled) : (!item.isSubscription && isScheduled);
      }).toList();

      if (quick.isNotEmpty) quickSections[entry.key] = quick;
      if (scheduled.isNotEmpty) scheduledSections[entry.key] = scheduled;
    }

    if (quickSections.isEmpty && scheduledSections.isEmpty) {
      return _EmptyCartState(
        title: subscriptionOnly ? 'No subscriptions' : 'Your cart is empty',
        subtitle: 'Add products to your cart to see them here',
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h), // Extra bottom padding for FAB
      children: [
        if (quickSections.isNotEmpty) ...[
          _buildDeliveryHeader('Standard Delivery', Icons.bolt_rounded, Colors.orange),
          ...quickSections.entries.map((e) => _WarehouseSection(
                warehouseId: e.key,
                items: e.value,
                products: products,
                deliveryType: DeliveryType.quick,
                subscriptionOnly: subscriptionOnly,
                onRemove: _onRemoveItem,
                embedded: widget.embedded,
              )),
        ],
        if (scheduledSections.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _buildDeliveryHeader('Scheduled Delivery', Icons.calendar_today_rounded, Colors.blue),
          ...scheduledSections.entries.map((e) => _WarehouseSection(
                warehouseId: e.key,
                items: e.value,
                products: products,
                deliveryType: DeliveryType.scheduled,
                subscriptionOnly: subscriptionOnly,
                onRemove: _onRemoveItem,
                embedded: widget.embedded,
              )),
        ],
      ],
    );
  }

  Widget _buildDeliveryHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({
    required Map<String, List<CartItem>> warehouseItems,
    required Map<String, ProductModel> products,
    required DeliveryType deliveryType,
    required bool subscriptionOnly,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    final sections = <String, List<CartItem>>{};
    for (final entry in warehouseItems.entries) {
      final filtered = entry.value.where((item) {
        if (!_itemsPendingDeletion.contains(_itemKey(item))) {
          final matchesDelivery = deliveryType == DeliveryType.quick
              ? item.selectedDeliveryType == null || item.selectedDeliveryType == DeliveryType.quick
              : item.selectedDeliveryType == DeliveryType.scheduled;

          if (subscriptionOnly) {
            return item.isSubscription && matchesDelivery;
          }
          return !item.isSubscription && matchesDelivery;
        }
        return false;
      }).toList();
      if (filtered.isNotEmpty) sections[entry.key] = filtered;
    }

    if (sections.isEmpty) {
      return _EmptyCartState(title: emptyTitle, subtitle: emptySubtitle);
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      children: sections.entries
          .map((e) => _WarehouseSection(
                warehouseId: e.key,
                items: e.value,
                products: products,
                deliveryType: deliveryType,
                subscriptionOnly: subscriptionOnly,
                onRemove: _onRemoveItem,
                embedded: widget.embedded,
              ))
          .toList(),
    );
  }

  void _onRemoveItem(CartItem item) {
    final key = _itemKey(item);
    debugPrint('Removing item immediately: $key');

    // Delete immediately from Firestore via Notifier
    ref.read(cartProvider.notifier).removeFromCart(item);

    AppNotifications.showSuccess(
      context,
      title: 'Success',
      message: 'Item removed from your cart',
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState({
    this.title = 'Your cart is empty',
    this.subtitle = 'Add items to get started',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 26.w,
            vertical: 32.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AssetConstants.illuShoppingCart,
                height: 140.w,
                fit: BoxFit.contain,
              ),

              SizedBox(height: 24.h),

              /// Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10.h),

              /// Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),

              SizedBox(height: 28.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarehouseSection extends ConsumerWidget {
  const _WarehouseSection({
    required this.warehouseId,
    required this.items,
    required this.products,
    required this.deliveryType,
    required this.subscriptionOnly,
    required this.onRemove,
    required this.embedded,
  });

  final String warehouseId;
  final List<CartItem> items;
  final Map<String, ProductModel> products;
  final DeliveryType deliveryType;
  final bool subscriptionOnly;
  final void Function(CartItem) onRemove;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final warehouses = ref.watch(activeWarehousesProvider).asData?.value ?? [];
    final warehouse = warehouses.where((w) => w.id == warehouseId).firstOrNull;
    final label = warehouse?.name ??
        (warehouseId == 'default'
            ? 'Main Store'
            : 'Store #${warehouseId.length > 6 ? warehouseId.substring(warehouseId.length - 6) : warehouseId}');

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : scheme.shadow).withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : scheme.shadow).withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: isDark ? 0.14 : 0.06),
                  scheme.primary.withValues(alpha: isDark ? 0.05 : 0.015),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(9.w),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.12),
                        blurRadius: 10.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warehouse_rounded,
                    size: 17.sp,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          fontSize: 15.5.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${items.length} item${items.length == 1 ? '' : 's'} in this order',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5.sp,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    '${items.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final product = products[item.productId];
                if (product == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    _CartItemTile(
                      item: item,
                      product: product,
                      onRemove: () => onRemove(item),
                    ),
                    if (index < items.length - 1)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Checkout
          Builder(
            builder: (context) {
              double total = 0;
              final checkoutProducts = <ProductModel>[];
              for (final item in items) {
                final product = products[item.productId];
                if (product == null) continue;
                final variant = product.getPackVariant(item.packVariantId);
                final price = variant != null ? variant.priceForQuantity(item.quantity) : product.price;
                total += price * item.quantity;
                if (!checkoutProducts.any((p) => p.id == product.id)) {
                  checkoutProducts.add(product);
                }
              }

              if (checkoutProducts.isEmpty) return const SizedBox.shrink();

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: _CheckoutBar(
                  total: total,
                  products: checkoutProducts,
                  warehouseId: warehouseId,
                  deliveryType: deliveryType,
                  subscriptionOnly: subscriptionOnly,
                  embedded: embedded,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({
    required this.item,
    required this.product,
    required this.onRemove,
  });

  final CartItem item;
  final ProductModel product;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final cartNotifier = ref.read(cartProvider.notifier);
    final variantsAsync = ref.watch(
      variantsByWarehouseProvider(
        (productId: item.productId, warehouseId: item.warehouseId),
      ),
    );
    final warehouseVariant = variantsAsync.asData?.value.firstWhereOrNull(
          (variant) => variant.id == item.packVariantId,
        ) ??
        product.getPackVariant(item.packVariantId);

    // Ensure we don't show 0.00 if possible
    final variant = warehouseVariant;

    final stock = variant?.stock ?? 0;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ProductCardWidget(
        product: product,
        layout: ProductCardLayout.list,
        removeButton: InkWell(
          borderRadius: BorderRadius.circular(999.r),
          onTap: onRemove,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 16.sp,
              color: scheme.error,
            ),
          ),
        ),
        variant: variant,
        quantity: item.quantity,
        heroTag: product.id,
        showDeliveryChips: false,
        onTierSelected: (tier) {
          // Set quantity to the minimum required for this tier
          cartNotifier.updateQuantity(item.copyWith(quantity: tier.minQty));
        },
        footer: item.isSubscription
            ? Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      size: 14.sp,
                      color: scheme.onPrimaryContainer,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Subscription Item',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999.r),
                onTap: item.quantity == 1 ? null : () => cartNotifier.decrementQuantity(item),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18.sp,
                    color: item.quantity == 1 ? scheme.outline : scheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                item.quantity.toString(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(width: 4.w),
              InkWell(
                borderRadius: BorderRadius.circular(999.r),
                onTap: () {
                  if (item.quantity < stock) {
                    cartNotifier.incrementQuantity(item);
                  } else {
                    AppNotifications.showError(
                      context,
                      title: 'Error',
                      message: 'Only available stock can be added',
                    );
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.add_circle_rounded,
                    size: 18.sp,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({
    required this.total,
    required this.products,
    required this.warehouseId,
    required this.deliveryType,
    required this.subscriptionOnly,
    required this.embedded,
  });

  final double total;
  final List<ProductModel> products;
  final String warehouseId;
  final DeliveryType deliveryType;
  final bool subscriptionOnly;
  final bool embedded;

  void _onCheckoutPressed(BuildContext context, WidgetRef ref) {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please log in to continue.',
      );
      return;
    }

    // final kycAsync = ref.read(businessKycByUserIdProvider(uid));
    //
    // // Handle provider states synchronously in this callback.
    // if (kycAsync.isLoading) {
    //   print("KYC status is still loading for user $uid. Please wait before checking out.");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Checking KYC status...')),
    //   );
    //   return;
    // }
    //
    // if (kycAsync.hasError) {
    //   print("Error loading KYC status for user $uid: ${kycAsync.error}");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error loading KYC status: ${kycAsync.error}')),
    //   );
    //   return;
    // }
    //
    // final kyc = kycAsync.asData?.value;
    // final status = kyc?.verification.kycStatus;
    // if (status != KycStatus.approved) {
    //   showDialog(
    //     context: context,
    //     builder: (ctx) => AlertDialog(
    //       title: const Text('KYC Verification Required'),
    //       content: Text(
    //         status == KycStatus.pending
    //             ? 'Your KYC is under review. You can place orders once it is approved.'
    //             : status == KycStatus.rejected
    //                 ? 'Your KYC was rejected. Please resubmit your documents to continue.'
    //                 : 'Please complete your KYC verification before placing an order.',
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(ctx).pop(),
    //           child: const Text('Cancel'),
    //         ),
    //         TextButton(
    //           onPressed: () {
    //             Navigator.of(ctx).pop();
    //             final user = ref.read(userProvider).value;
    //             if (kyc == null || status == KycStatus.draft) {
    //               context.pushNamed(RouteNames.kycStepper);
    //             } else {
    //               context.pushNamed(RouteNames.kycStatus, extra: user);
    //             }
    //           },
    //           child: const Text('Go to KYC'),
    //         ),
    //       ],
    //     ),
    //   );
    //   return;
    // }

    context.pushNamed(
      RouteNames.checkoutScreen,
      queryParameters: {
        'warehouseId': warehouseId,
        'deliveryType': deliveryType.name,
        'isSubscription': subscriptionOnly.toString(),
      },
      extra: products,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Pre-subscribe so the stream is loaded before the user taps checkout.
    // final uid = ref.watch(currentUserIdProvider);
    // if (uid != null) ref.watch(businessKycByUserIdProvider(uid));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER TOTAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  AppConfig.formatPrice(total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          ElevatedButton(
            onPressed: () => _onCheckoutPressed(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'CHECKOUT',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
