import 'package:sure_wholesaler/widgets/app_shimmer.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';

class HorizontalProductStrip extends ConsumerStatefulWidget {
  final List<String>? warehouseIds;
  final DeliveryType? deliveryType;
  final bool subscriptionOnly;
  final int maxItems;
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onSeeAll;

  const HorizontalProductStrip({
    this.warehouseIds,
    this.deliveryType,
    this.subscriptionOnly = false,
    this.maxItems = 8,
    this.title,
    this.icon,
    this.iconColor,
    this.onSeeAll,
  });

  @override
  ConsumerState<HorizontalProductStrip> createState() =>
      HorizontalProductStripState();
}

class HorizontalProductStripState
    extends ConsumerState<HorizontalProductStrip> {
  ProductsParams get _params => ProductsParams(
        deliveryType: widget.deliveryType,
        warehouseIds: widget.warehouseIds,
      );

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(paginatedProductsProvider(_params).notifier).loadProducts(),
    );
  }

  IconData get _badgeIcon {
    if (widget.subscriptionOnly) return Icons.repeat_rounded;
    return widget.deliveryType?.icon ?? Icons.local_shipping_rounded;
  }

  String get _badgeLabel {
    if (widget.subscriptionOnly) return 'Subscribe & Save';
    return '${widget.deliveryType?.label ?? ''} Delivery';
  }

  Color get _accentColor {
    if (widget.subscriptionOnly) return AppColors.brandSeed;
    return widget.deliveryType?.color ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(paginatedProductsProvider(_params));

    final products = widget.subscriptionOnly
        ? state.products
            .where((p) =>
                p.activePackVariants.any((v) => v.isSubscriptionAvailable))
            .take(widget.maxItems)
            .toList()
        : state.products.take(widget.maxItems).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Container(
        decoration: BoxDecoration(
          color: _accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: _accentColor.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section title + See all + badge ─────────────────
            Padding(
              padding: EdgeInsets.only(left: 14.w, right: 14.w, bottom: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with optional "See all"
                  // if (widget.title != null)
                  //   Row(
                  //     children: [
                  //       if (widget.icon != null)
                  //         Container(
                  //           padding: const EdgeInsets.all(7),
                  //           decoration: BoxDecoration(
                  //             color: (widget.iconColor ?? _accentColor)
                  //                 .withValues(alpha: 0.12),
                  //             shape: BoxShape.circle,
                  //           ),
                  //           child: Icon(widget.icon,
                  //               color: widget.iconColor ?? _accentColor,
                  //               size: 16.sp),
                  //         ),
                  //       if (widget.icon != null) SizedBox(width: 8.w),
                  //       Expanded(
                  //         child: Text(
                  //           widget.title!,
                  //           style: theme.textTheme.titleMedium?.copyWith(
                  //             fontWeight: FontWeight.w700,
                  //             letterSpacing: -0.2,
                  //           ),
                  //         ),
                  //       ),
                  //       if (widget.onSeeAll != null)
                  //         GestureDetector(
                  //           onTap: widget.onSeeAll,
                  //           child: Text(
                  //             'See all',
                  //             style: theme.textTheme.labelMedium?.copyWith(
                  //               color: theme.colorScheme.primary,
                  //               fontWeight: FontWeight.w600,
                  //             ),
                  //           ),
                  //         ),
                  //     ],
                  //   ),
                  if (widget.title != null) SizedBox(height: 8.h),
                  // Delivery type badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_badgeIcon, size: 14.sp, color: _accentColor),
                            SizedBox(width: 5.w),
                            Text(
                              _badgeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _accentColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onSeeAll != null)
                        InkWell(
                          onTap: () => widget.onSeeAll!(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 5.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "See All",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _accentColor,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Product cards ────────────────────────────────────
            if (state.isLoading && products.isEmpty)
              SizedBox(
                height: ProductCardWidget.gridHeight + 10.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                  itemBuilder: (context, index) => AppShimmer.productSkeleton(
                    width: ProductCardWidget.gridWidth,
                    height: ProductCardWidget.gridHeight,
                  ),
                ),
              )
            else if (products.isEmpty)
              SizedBox(
                height: 100.h,
                child: Center(
                  child: Text(
                    'No products available',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SizedBox(
                height: ProductCardWidget.gridHeight + 10.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                  itemBuilder: (context, index) => SizedBox(
                    width: ProductCardWidget.gridWidth,
                    child: ProductCardWidget(product: products[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
