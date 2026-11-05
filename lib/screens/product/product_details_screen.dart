import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/coupon_notifier.dart';
import 'package:sure_wholesaler/notifiers/favorites_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/notifiers/stock_alert_notifier.dart';
import 'package:sure_wholesaler/screens/favorite_products/favorite_products.dart';
import 'package:sure_wholesaler/screens/product/product_review_widget.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:sure_wholesaler/widgets/product_image_slider.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

final isExpandedProvider = StateProvider<bool>((ref) => false);
final productWithVariantsProvider = FutureProvider.family<ProductModel, ProductModel>((ref, product) async {
  if (product.id == null) return product;
  if (product.packVariants.isNotEmpty) {
    return product;
  }

  try {
    final variants = await VariantFirestoreDsImpl().getVariantsByProduct(product.id!).first;
    if (variants.isEmpty) return product;
    return product.withVariants(variants);
  } catch (e) {
    debugPrint('Variant load error: $e');
    return product;
  }
});

class ProductSelectionState {
  final PackVariant? selectedVariant;
  final DeliveryType? selectedDeliveryType;

  const ProductSelectionState({
    this.selectedVariant,
    this.selectedDeliveryType,
  });

  ProductSelectionState copyWith({
    PackVariant? selectedVariant,
    DeliveryType? selectedDeliveryType,
  }) {
    return ProductSelectionState(
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedDeliveryType: selectedDeliveryType ?? this.selectedDeliveryType,
    );
  }
}

class ProductSelectionNotifier extends StateNotifier<ProductSelectionState> {
  ProductSelectionNotifier() : super(const ProductSelectionState());

  /// Select variant
  void selectVariant(PackVariant variant) {
    // 🔥 auto reset delivery
    DeliveryType? autoDelivery;

    if (variant.availableDeliveryTypes.length == 1) {
      autoDelivery = variant.availableDeliveryTypes.first;
    }

    state = ProductSelectionState(
      selectedVariant: variant,
      selectedDeliveryType: autoDelivery,
    );
  }

  /// Select delivery
  void selectDelivery(DeliveryType type) {
    state = state.copyWith(selectedDeliveryType: type);
  }
}

class ProductDetails extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetails({super.key, required this.product});

  @override
  ConsumerState<ProductDetails> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetails> {
  PackVariant? _selectedVariant;
  Map<String, String> _selectedAttributes = {};
  DeliveryType? _selectedDeliveryType;
  String? _initializedForId;
  int _quantity = 1;

  void _initVariants(ProductModel product) {
    final id = product.id;
    final activeVariants = product.activePackVariants;

    // Use a unique key for initialization, considering both product ID and variant availability
    final initKey = '${id}_${activeVariants.length}';

    if (id != null && initKey != _initializedForId && activeVariants.isNotEmpty) {
      _initializedForId = initKey;

      // Prefer the first in-stock variant to ensure attributes are visually active by default
      _selectedVariant = activeVariants.firstWhere(
            (v) => v.stock > 0,
        orElse: () => activeVariants.first,
      );

      _selectedAttributes = Map<String, String>.from(_selectedVariant!.attributes);
      _quantity = 1;
      _autoSelectDelivery(_selectedVariant!);
    }
  }

  void _autoSelectDelivery(PackVariant variant) {
    final types = variant.availableDeliveryTypes;
    _selectedDeliveryType = types.length == 1 ? types.first : null;
  }

  void _onAttributeTap(String key, String value, List<PackVariant> variants) {
    setState(() {
      _selectedAttributes[key] = value;
      final match = _findBestMatch(variants, requiredKey: key, requiredValue: value);
      if (match != null) {
        _selectedVariant = match;
        // Always reset to 1 for standard variant selection
        _quantity = 1;
        _selectedAttributes = Map<String, String>.from(match.attributes);
        _autoSelectDelivery(match);
      }
    });
  }

  /// Returns the variant that must have [requiredKey]==[requiredValue] and
  /// soft-matches as many other currently selected attributes as possible.
  /// Falls back to any in-stock candidate, then any active candidate.
  PackVariant? _findBestMatch(
      List<PackVariant> variants, {
        required String requiredKey,
        required String requiredValue,
      }) {
    // Hard filter: must match the tapped key.
    var candidates = variants.where((v) => v.attributes[requiredKey] == requiredValue).toList();
    if (candidates.isEmpty) return null;

    // Prefer in-stock variants.
    final inStock = candidates.where((v) => v.stock > 0).toList();
    if (inStock.isNotEmpty) candidates = inStock;

    // Among candidates, pick the one matching the most other selected attributes.
    PackVariant? best;
    int bestScore = -1;
    for (final v in candidates) {
      final score = _selectedAttributes.entries.where((e) => e.key != requiredKey && v.attributes[e.key] == e.value).length;
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    return best ?? candidates.first;
  }

  void _addSelectedVariantToCart(ProductModel product) {
    if (_selectedVariant == null) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please select a pack size',
      );
      return;
    }

    if (_selectedVariant!.stock <= 0) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'This item is currently out of stock',
      );
      return;
    }

    if (_quantity < _selectedVariant!.moq) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Minimum order quantity for this item is ${_selectedVariant!.moq} packs',
      );
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'Adding ${product.name} (Pack of ${_selectedVariant!.packSize} x $_quantity) to cart',
      );
    }

    final types = _selectedVariant!.availableDeliveryTypes;
    if (types.length > 1 && _selectedDeliveryType == null) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please select a delivery type',
      );
      return;
    }
    final deliveryType = _selectedDeliveryType ?? (types.isNotEmpty ? types.first : DeliveryType.quick);
    final warehouseId = _selectedVariant?.inventory?.warehouseId ??
        ref.read(cartProvider).value?.warehouseId ??
        ref.read(resolvedWarehouseProvider).firstOrNull ??
        'default';
    final cartItem = CartItem.fromVariant(
      variant: _selectedVariant!,
      deliveryType: deliveryType,
      warehouseId: warehouseId,
      quantity: _quantity,
    );

    ref.read(cartProvider.notifier).addToCart(
      cartItem,
    );

    AppNotifications.showPremiumNotification(
      context,
      title: 'Success',
      message: '${product.name} added to cart',
      buttonLabel: 'VIEW CART',
      onButtonPressed: () {
        final tab = deliveryType == DeliveryType.scheduled ? 1 : 0;
        context.pushReplacement('${AppRoutes.cart}?tab=$tab');
      },
    );
  }

  void _onAddToCart(ProductModel product) {
    _addSelectedVariantToCart(product);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productWithVariantsProvider(widget.product));

    return productAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(theme),
        body: const Center(child: AppLoader()),
      ),
      error: (e, _) => Scaffold(
        appBar: _buildAppBar(theme),
        body: Center(child: Text('Failed to load product: $e')),
      ),
      data: (product) {
        _initVariants(product);

        return Scaffold(
          appBar: _buildAppBar(theme),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(theme, product),
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPrimaryInfo(theme, product),
                            _buildVariantSelector(theme, product),
                            WholesaleSection(
                              product: product,
                              currentVariant: _selectedVariant,
                              currentQuantity: _quantity,
                              onDealSelected: (variant, qty) {
                                setState(() {
                                  _selectedVariant = variant;
                                  _selectedAttributes = Map<String, String>.from(variant.attributes);
                                  _quantity = qty;
                                  _autoSelectDelivery(variant);
                                });
                              },
                            ),
                            _buildDescription(theme, product),
                            _buildTagsWidget(theme, product),
                            _buildSpecificationsTile(theme, product),
                            _buildDetailTable(theme, product),
                            const SizedBox(height: 24),
                            ProductReviewWidget(productId: product.id!, onlyMyReview: false),
                          ],
                        ),
                      ),
                      RelatedProductsSection(product: product),
                    ],
                  ),
                ),
              ),
              _buildBottomActionPanel(theme, product),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection(ThemeData theme, ProductModel product) {
    // Use images from the loaded product instance
    final productImages = product.imageUrls;
    final variantImages = _selectedVariant?.imageUrls ?? [];

    // Prepend variant images so they appear first in the slider
    final allImages = {
      ...variantImages,
      ...productImages,
    }.toList();

    return SizedBox(
      height: 320.h,
      child: Stack(
        children: [
          ProductImageSlider(
            // The key forces the slider to reset to index 0 when the variant changes
            key: ValueKey(_selectedVariant?.id ?? product.id),
            imageUrls: allImages,
            height: 320, // Passed explicit height to match SizedBox
          ),
          if (product.offerBadgeText != null && product.offerBadgeText!.isNotEmpty)
            Positioned(
              top: 16.h,
              left: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  product.offerBadgeText!.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryInfo(ThemeData theme, ProductModel product) {
    final displayPrice = _selectedVariant != null ? _selectedVariant!.priceForQuantity(_quantity) : product.price;
    final displayMrp = _selectedVariant?.mrp ?? product.mrp;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.brandName?.toUpperCase() ?? '',
            style: theme.textTheme.labelSmall,
          ),
          Text(
            '${product.name} ${_selectedVariant?.attributes['Size'] ?? ''}',
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppConfig.formatPrice(displayPrice),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              if (displayMrp != null && displayMrp > displayPrice)
                Text(
                  AppConfig.formatPrice(displayMrp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              SizedBox(width: 8.w),
              _buildDiscountBadge(theme, product),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _selectedVariant?.attributes['Size'] ?? 'Unit: ${product.unit}',
            style: theme.textTheme.bodySmall,
          ),
          if (product.offerTitle != null && product.offerTitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 16.sp, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.offerTitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockStatus(ThemeData theme, ProductModel product) {
    final stock = _selectedVariant?.stock ?? product.currentStock;
    final minAlert = _selectedVariant?.minStockAlert ?? product.minStockAlert;
    final isLowStock = stock <= minAlert;
    final isOutOfStock = stock <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2,
                size: 16.sp,
                color: isOutOfStock
                    ? theme.colorScheme.error
                    : isLowStock
                    ? AppColors.warningDark
                    : theme.colorScheme.surface,
              ),
              SizedBox(width: 8.w),
              Text(
                isOutOfStock
                    ? 'Out of Stock'
                    : isLowStock
                    ? 'Only $stock packs left'
                    : 'In Stock ($stock packs)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  color: isOutOfStock
                      ? theme.colorScheme.error
                      : isLowStock
                      ? AppColors.warningDark
                      : theme.colorScheme.surface,
                ),
              ),
            ],
          ),
        ),
        if (isOutOfStock) ...[
          SizedBox(height: 12.h),
          _buildStockAlertButton(theme, product),
        ],
      ],
    );
  }

  Widget _buildStockAlertButton(ThemeData theme, ProductModel product) {
    final productId = product.id ?? '';
    final subscriptionState = ref.watch(isSubscribedProvider(productId));

    return subscriptionState.when(
      loading: () => SizedBox(
        height: 40.h,
        child: const Center(child: AppLoader(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (isSubscribed) {
        return SizedBox(
          width: double.infinity,
          height: 44.h,
          child: OutlinedButton.icon(
            onPressed: () => _toggleStockAlert(
              isSubscribed,
              productId: productId,
              productName: product.name,
            ),
            icon: Icon(
              isSubscribed ? Icons.notifications_active : Icons.notifications_none,
              size: 20.sp,
            ),
            label: Text(
              isSubscribed ? 'Alert Set - Tap to Remove' : 'Notify When Available',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isSubscribed ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              side: BorderSide(
                color: isSubscribed ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleStockAlert(
      bool isCurrentlySubscribed, {
        required String productId,
        required String productName,
      }) async {
    final notifier = ref.read(userStockAlertsProvider.notifier);

    bool success;
    if (isCurrentlySubscribed) {
      success = await notifier.unsubscribe(productId: productId);
    } else {
      success = await notifier.subscribe(
        productId: productId,
        productName: productName,
      );
    }

    // Refresh the subscription state
    ref.invalidate(isSubscribedProvider(productId));

    if (mounted) {
      if (success) {
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: isCurrentlySubscribed
              ? 'Stock alert removed'
              : 'You\'ll be notified when $productName is back in stock',
        );
      } else {
        AppNotifications.showError(
          context,
          title: 'Error',
          message: 'Something went wrong. Please try again.',
        );
      }
    }
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Divider(
        height: 1,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildDetailTable(
      ThemeData theme,
      ProductModel product,
      ) {
    final variant = _selectedVariant;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(
            horizontal: 16.w,
          ),
          childrenPadding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 16.h,
          ),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20.sp,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            'Product Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            "SKU, GST, Brand & variant info",
            style: theme.textTheme.bodySmall,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  theme,
                  'Product SKU',
                  product.sku,
                ),
                if (product.subCategoryName.isNotEmpty || product.categoryName.isNotEmpty) ...[
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'Category',
                    product.subCategoryName.isNotEmpty ? product.subCategoryName : product.categoryName,
                  ),
                ],
                if (product.brandName != null && product.brandName!.isNotEmpty) ...[
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'Brand',
                    product.brandName,
                  ),
                ],
                if ((product.supplierName != null && product.supplierName!.isNotEmpty) ||
                    (product.supplierId != null && product.supplierId!.isNotEmpty)) ...[
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'Supplier',
                    (product.supplierName != null && product.supplierName!.isNotEmpty) ? product.supplierName : product.supplierId,
                  ),
                ],
                if (product.gstRate.trim().isNotEmpty && product.gstRate != '0%') ...[
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'GST Rate',
                    '${product.gstRate}%',
                  ),
                ],
                if (product.hsnCode != null && product.hsnCode!.isNotEmpty) ...[
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'HSN Code',
                    product.hsnCode,
                  ),
                ],
                if (variant != null) ...[
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'Variant SKU',
                    variant.sku,
                  ),
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'Pack Size',
                    variant.attributes['Size'] ?? 'Pack of ${variant.packSize} ${product.unit}',
                  ),
                  if (variant.weight != null) ...[
                    _buildDivider(theme),
                    _buildDetailRow(
                      theme,
                      'Weight',
                      '${variant.weight} ${variant.weightUnit}',
                    ),
                  ],
                  _buildDivider(theme),
                  _buildDetailRow(
                    theme,
                    'Min. Order',
                    '${variant.moq} pack${variant.moq > 1 ? "s" : ""}',
                  ),
                  if (variant.expiryDate != null) ...[
                    _buildDivider(theme),
                    _buildDetailRow(
                      theme,
                      'Expiry',
                      variant.expiryDate,
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      ThemeData theme,
      String label,
      String? value,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              ':',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.trim().isNotEmpty == true ? value! : 'N/A',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionPanel(ThemeData theme, ProductModel product) {
    final displayPrice = _selectedVariant != null ? _selectedVariant!.priceForQuantity(_quantity) : product.price;
    const isReachable = true;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConfig.formatPrice(displayPrice),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                if (_selectedVariant != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _selectedVariant!.attributes['Size'] ?? "Pack of ${_selectedVariant!.packSize}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_selectedVariant != null) ...[
            _buildQuantitySelector(theme),
            const SizedBox(width: 16),
          ],
          SizedBox(
            height: 34.h,
            child: ElevatedButton(
              onPressed: (isReachable && _selectedVariant != null && _selectedVariant!.stock > 0) ? () => _onAddToCart(product) : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text(
                'Add To cart',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme) {
    final stock = _selectedVariant?.stock ?? 0;

    Widget buildButton({
      required IconData icon,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: 32.w,
          height: 34.w,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16.sp,
            color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildButton(
            icon: Icons.remove,
            enabled: _quantity > 1,
            onTap: () => setState(() => _quantity--),
          ),
          SizedBox(
            width: 28.w,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          buildButton(
            icon: Icons.add,
            enabled: _quantity < stock,
            onTap: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(ThemeData theme, ProductModel product) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '${product.discountPercent?.toStringAsFixed(0) ?? '0'}% OFF',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.primaryColor,
      title: const Text('Store Explorer'),
      centerTitle: true,
      actions: [
        if (widget.product.id != null)
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FavoriteButton(
              productId: widget.product.id!,
              size: 24.sp,
            ),
          ),
      ],
    );
  }

  Widget _buildVariantSelector(ThemeData theme, ProductModel product) {
    if (product.selectableOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...product.selectableOptions.entries.map((entry) {
          final attributeKey = entry.key;
          final options = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attributeKey.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: options.map((option) {
                  final isSelected = _selectedAttributes[attributeKey] == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onAttributeTap(attributeKey, option, product.packVariants);
                      }
                    },
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSpecificationsTile(
      ThemeData theme,
      ProductModel product,
      ) {
    if (product.specifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          childrenPadding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 14.h,
          ),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.settings_suggest_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            "Specifications",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            "${product.specifications.length} details",
          ),
          children: [
            _buildSpecifications(theme, product),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecifications(
      ThemeData theme,
      ProductModel product,
      ) {
    return Column(
      children: [
        ...product.specifications.entries.map(
              (e) => _buildDetailRow(
            theme,
            e.key,
            e.value?.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(
      ThemeData theme,
      ProductModel product,
      ) {
    if (product.description == null || product.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 22.sp,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                "Description",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            product.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsWidget(
      ThemeData theme,
      ProductModel product,
      ) {
    if (product.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sell_outlined,
                size: 22.sp,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                "Tags",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: product.tags.map(
                  (tag) {
                return Chip(
                  label: Text(tag),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class OfferWidget extends ConsumerWidget {
  final List<String>? offers;

  const OfferWidget({super.key, this.offers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (offers == null || offers!.isEmpty) return const SizedBox();

    final couponsAsync = ref.watch(couponsByCodesProvider(offers!));

    return couponsAsync.when(
      data: (coupons) {
        if (coupons.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'Available Offers',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: <Widget>[
                ...coupons.map(
                      (coupon) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CouponChip(coupon: coupon),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.all(16.w),
        child: const Center(child: AppLoader()),
      ),
      error: (e, _) => const SizedBox(),
    );
  }
}

class CouponChip extends ConsumerWidget {
  final CouponModel coupon;

  const CouponChip({super.key, required this.coupon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      onPressed: () {
        // the coupon
      },
      label: Text(coupon.code),
    );
  }
}

class RelatedProductsSection extends ConsumerWidget {
  final ProductModel product;

  const RelatedProductsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sameCategoryAsync = ref.watch(relatedProductsProvider(product));
    final sameWarehouseAsync = ref.watch(
      sameWarehouseProductsProvider(product),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductRow(
          title: 'More from this category',
          asyncProducts: sameCategoryAsync,
        ),
        _ProductRow(
          title: 'More from this store',
          asyncProducts: sameWarehouseAsync,
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String title;
  final AsyncValue<List<ProductModel>> asyncProducts;

  const _ProductRow({required this.title, required this.asyncProducts});

  @override
  Widget build(BuildContext context) {
    return asyncProducts.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 240.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: products.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) => SizedBox(
                  width: 160.w,
                  child: ProductCardWidget(product: products[index]),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }
}

class PricingTierWidget extends StatelessWidget {
  final List<PricingTier> pricingTiers;
  final int currentQuantity;
  final String? itemLabel;
  final void Function(PricingTier tier)? onTierSelected;

  const PricingTierWidget({
    super.key,
    required this.pricingTiers,
    required this.currentQuantity,
    this.itemLabel,
    this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find active tier
    PricingTier? activeTier;
    for (var tier in pricingTiers) {
      if (currentQuantity >= tier.minQty) {
        if (activeTier == null || tier.minQty > activeTier.minQty) {
          activeTier = tier;
        }
      }
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: pricingTiers.map((tier) {
        final isSelected = activeTier == tier;

        return InkWell(
          onTap: () => onTierSelected?.call(tier),
          borderRadius: BorderRadius.circular(10.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color:
              isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    "${tier.minQty}+",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConfig.formatPrice(tier.price, decimals: 0),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? theme.colorScheme.primary : null,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      itemLabel != null ? "/$itemLabel" : "/pack",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 8.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AttributesWidget extends StatelessWidget {
  final Map<String, dynamic> attributes;

  const AttributesWidget({super.key, required this.attributes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: attributes.entries.map((entry) {
        final key = entry.key;
        final capitalized = key[0].toUpperCase() + key.substring(1);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
              children: [
                TextSpan(
                  text: '$capitalized: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '${entry.value}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class WholesaleSection extends StatelessWidget {
  const WholesaleSection({
    super.key,
    required this.product,
    this.currentVariant,
    required this.currentQuantity,
    required this.onDealSelected,
  });

  final ProductModel product;
  final PackVariant? currentVariant;
  final int currentQuantity;
  final void Function(PackVariant variant, int quantity) onDealSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final deals = <_BulkDeal>[];

    // 1. Try to get tiers from variants first
    for (final variant in product.packVariants) {
      final bulkTiers = variant.pricingTiers.where((t) => t.minQty > 1).toList();
      for (final tier in bulkTiers) {
        deals.add(_BulkDeal(variant: variant, tier: tier));
      }
    }

    // 2. If no deals found in variants, fallback to using product-level tiers
    if (deals.isEmpty) {
      for (final tier in product.pricingTiers.where((t) => t.minQty > 1)) {
        // Try to match this tier to a variant by label
        PackVariant? matchedVariant;
        final tLabel = (tier.label ?? '').toLowerCase().replaceAll(' ', '');

        for (final v in product.packVariants) {
          final vLabel = (v.attributes['Size'] ?? '').toLowerCase().replaceAll(' ', '');
          if (vLabel.isNotEmpty && tLabel.isNotEmpty && (vLabel.contains(tLabel) || tLabel.contains(vLabel))) {
            matchedVariant = v;
            break;
          }
        }

        // If no match found, use the first active variant as a safe fallback
        matchedVariant ??= product.packVariants.isNotEmpty ? product.packVariants.first : null;

        if (matchedVariant != null) {
          deals.add(_BulkDeal(variant: matchedVariant, tier: tier));
        }
      }
    }

    if (deals.isEmpty) return const SizedBox.shrink();

    // Sort deals by price per unit ascending (best deal first) or by quantity
    deals.sort((a, b) => a.tier.minQty.compareTo(b.tier.minQty));

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.brandSeed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.stars_rounded, color: AppColors.brandSeed, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'Wholesale / Bulk Deals',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Save more when you buy in bulk. Select a deal below:',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 16.h),
          ...deals.map((deal) {
            final variant = deal.variant;
            final tier = deal.tier;
            final label = variant.attributes['Size'] ?? '${variant.packSize} ${product.unit}';
            final isSelected = currentVariant?.id == variant.id && currentQuantity == tier.minQty;

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: InkWell(
                onTap: () => onDealSelected(variant, tier.minQty),
                borderRadius: BorderRadius.circular(12.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Qty Badge
                      Container(
                        width: 50.w,
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          "${tier.minQty}+",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? Colors.white : scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Special Wholesale Price",
                              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 9.sp),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppConfig.formatPrice(tier.price),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isSelected ? scheme.primary : AppColors.brandSeed,
                            ),
                          ),
                          Text(
                            "per unit",
                            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 8.sp),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 10.w),
                        Icon(Icons.check_circle, color: scheme.primary, size: 20.sp),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _BulkDeal {
  final PackVariant variant;
  final PricingTier tier;
  _BulkDeal({required this.variant, required this.tier});
}

class BulkPricingCard extends StatelessWidget {
  const BulkPricingCard({
    super.key,
    required this.pricingTiers,
    required this.currentQuantity,
    this.itemLabel,
    this.onTierSelected,
  });

  final List<PricingTier> pricingTiers;
  final int currentQuantity;
  final String? itemLabel;
  final void Function(PricingTier tier)? onTierSelected;

  @override
  Widget build(BuildContext context) {
    if (pricingTiers.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: theme.colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Bulk Pricing',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Buy more and save more',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          PricingTierWidget(
            pricingTiers: pricingTiers,
            currentQuantity: currentQuantity,
            onTierSelected: onTierSelected,
            itemLabel: itemLabel,
          ),
        ],
      ),
    );
  }
}
