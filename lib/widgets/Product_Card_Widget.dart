import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';

enum ProductCardLayout { grid, list }

class ProductCardWidget extends StatelessWidget {
  static double get gridWidth => 135.w;

  static double get gridHeight => 215.w;

  static double get listMinHeight => 100.h;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.layout = ProductCardLayout.grid,
    this.variant,
    this.quantity,
    this.subtitle,
    this.footer,
    this.trailing,
    this.heroTag,
    this.showDeliveryChips = true,
    this.showDiscountBadge = true,
    this.showPrice = true,
    this.padding,
    this.removeButton,
    this.onTierSelected,
    this.customBadge,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final void Function(PricingTier)? onTierSelected;
  final ProductCardLayout layout;
  final PackVariant? variant;
  final int? quantity;
  final String? subtitle;
  final Widget? footer;
  final Widget? removeButton;
  final Widget? trailing;
  final Object? heroTag;
  final bool showDeliveryChips;
  final bool showDiscountBadge;
  final bool showPrice;
  final EdgeInsetsGeometry? padding;
  final Widget? customBadge;

  @override
  Widget build(BuildContext context) {
    final card = layout == ProductCardLayout.grid
        ? _GridProductCard(
            product: product,
            onTap: onTap,
            showDiscountBadge: showDiscountBadge,
            customBadge: customBadge,
            onAddToCart: onAddToCart,
            heroTag: heroTag,
            subtitle: subtitle,
          )
        : _ListProductCard(
            product: product,
            onTap: onTap,
            variant: variant,
            quantity: quantity,
            removeButton: removeButton,
            subtitle: subtitle,
            footer: footer,
            trailing: trailing,
            heroTag: heroTag,
            showPrice: showPrice,
            padding: padding,
            onTierSelected: onTierSelected,
            customBadge: customBadge,
            onAddToCart: onAddToCart,
          );

    return card;
  }
}

class _GridProductCard extends StatelessWidget {
  const _GridProductCard({
    required this.product,
    required this.onTap,
    required this.showDiscountBadge,
    this.customBadge,
    this.onAddToCart,
    this.heroTag,
    this.subtitle,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final bool showDiscountBadge;
  final Widget? customBadge;
  final VoidCallback? onAddToCart;
  final String? subtitle;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final discountPercent = product.discountPercent;
    final firstVariant = product.packVariants.isNotEmpty ? product.packVariants.first : null;
    final price = firstVariant?.price ?? product.price;
    final mrp = firstVariant?.mrp ?? product.mrp;
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: onTap ?? () => context.goToProductDetails(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Hero(
                          tag: heroTag ??
                              'grid_${product.id}_${identityHashCode(this)}_${DateTime.now().microsecondsSinceEpoch}',
                          child: imageUrl != null
                              ? ImageBuilder(url: imageUrl, fit: BoxFit.contain)
                              : Icon(Icons.shopping_bag_outlined,
                                  color: scheme.primary, size: 32.sp),
                        ),
                      ),
                    ),
                  ),
                  if (customBadge != null)
                    Positioned(top: 6.h, left: 6.w, child: customBadge!)
                  else if (showDiscountBadge && discountPercent != null && discountPercent >= 1)
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${discountPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  if (onAddToCart != null)
                    Positioned(
                      bottom: 6.h,
                      right: 6.w,
                      child: GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.brandSeed,
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(Icons.add_rounded, color: Colors.white, size: 14.sp),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6.h),
          // Content Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppConfig.formatPrice(price),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandSeed,
                      ),
                    ),
                    if (mrp != null && mrp > price) ...[
                      SizedBox(width: 8.w),
                      Text(
                        AppConfig.formatPrice(mrp),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListProductCard extends StatelessWidget {
  const _ListProductCard({
    required this.product,
    required this.onTap,
    this.variant,
    this.removeButton,
    this.quantity,
    this.subtitle,
    this.footer,
    this.trailing,
    this.heroTag,
    required this.showPrice,
    this.padding,
    this.onTierSelected,
    this.customBadge,
    this.onAddToCart,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final PackVariant? variant;
  final int? quantity;
  final String? subtitle;
  final Widget? removeButton;
  final Widget? customBadge;
  final Widget? footer;
  final Widget? trailing;
  final Object? heroTag;
  final bool showPrice;
  final EdgeInsetsGeometry? padding;
  final void Function(PricingTier)? onTierSelected;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final firstVariant = variant ?? (product.packVariants.isNotEmpty ? product.packVariants.first : null);
    final price =
        (firstVariant != null && quantity != null) ? firstVariant.priceForQuantity(quantity!) : (firstVariant?.price ?? product.price);

    final mrp = firstVariant?.mrp ?? product.mrp;

    // Enhanced Label logic to show both Size/Attributes AND Pack Size
    String unitLabel = product.unit;
    if (firstVariant != null) {
      final attrPart = firstVariant.attributes.values.join(' / ');
      final packPart = firstVariant.packSize > 1 ? 'Pack of ${firstVariant.packSize}' : '';
      if (attrPart.isNotEmpty && packPart.isNotEmpty) {
        unitLabel = '$attrPart · $packPart';
      } else if (attrPart.isNotEmpty) {
        unitLabel = attrPart;
      } else if (packPart.isNotEmpty) {
        unitLabel = packPart;
      }
    }

    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    final discountPercent = product.discountPercent;

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap ?? () => context.goToProductDetails(product),
      child: Container(
        padding: padding ?? EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    // Image
                    Hero(
                      tag: heroTag ?? 'list_${product.id}_${identityHashCode(this)}_${DateTime.now().microsecondsSinceEpoch}',
                      child: Stack(
                        children: [
                          Container(
                            width: 75.w,
                            height: 75.w,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: imageUrl != null
                                  ? ImageBuilder(url: imageUrl, fit: BoxFit.cover)
                                  : Icon(Icons.shopping_bag_outlined, color: scheme.primary, size: 24.sp),
                            ),
                          ),
                          if (customBadge != null)
                            Positioned(top: 4.h, left: 4.w, child: customBadge!)
                          else if (discountPercent != null && discountPercent >= 1)
                            Positioned(
                              top: 4.h,
                              left: 4.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(999.r),
                                ),
                                child: Text(
                                  '${discountPercent.round()}% OFF',
                                  style: TextStyle(
                                    color: AppColors.successDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: removeButton != null ? 24.w : 0),
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (product.brandName != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              product.brandName!,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          SizedBox(height: 6.h),
                          if (showPrice)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8.w,
                              children: [
                                Text(
                                  AppConfig.formatPrice(price),
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandSeed,
                                  ),
                                ),
                                if (mrp != null && mrp > price)
                                  Text(
                                    AppConfig.formatPrice(mrp),
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                              ],
                            ),
                          if (unitLabel.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              unitLabel,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trailing / Add Button
                    if (trailing != null)
                      trailing!
                    else if (onAddToCart != null)
                      IconButton.filled(
                        onPressed: onAddToCart,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.brandSeed,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      Container(
                        height: 36.h,
                        width: 36.w,
                        decoration: BoxDecoration(
                          color: AppColors.brandSeed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: AppColors.brandSeed),
                      ),
                  ],
                ),
                if (footer != null) ...[
                  SizedBox(height: 10.h),
                  footer!,
                ],
                if (variant != null && variant!.pricingTiers.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: PricingTierList(
                      pricingTiers: variant!.pricingTiers,
                      quantity: quantity ?? 0,
                      onTierSelected: onTierSelected,
                    ),
                  ),
              ],
            ),
            if (removeButton != null)
              Positioned(
                top: -4.h,
                right: -4.w,
                child: removeButton!,
              ),
          ],
        ),
      ),
    );
  }
}

class PricingTierList extends StatelessWidget {
  final List<PricingTier> pricingTiers;
  final int quantity;
  final void Function(PricingTier tier)? onTierSelected;

  const PricingTierList({
    super.key,
    required this.pricingTiers,
    required this.quantity,
    this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    PricingTier? activeTier;
    for (var tier in pricingTiers) {
      if (quantity >= tier.minQty) {
        if (activeTier == null || tier.minQty > activeTier.minQty) {
          activeTier = tier;
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pricingTiers.map((tier) {
          final isSelected = activeTier == tier;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => onTierSelected?.call(tier),
              borderRadius: BorderRadius.circular(8.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandSeed.withValues(alpha: 0.1) : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? AppColors.brandSeed : AppColors.border.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandSeed : AppColors.textHint.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        "${tier.minQty}+",
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppConfig.formatPrice(tier.price, decimals: 0),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? AppColors.brandSeed : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
