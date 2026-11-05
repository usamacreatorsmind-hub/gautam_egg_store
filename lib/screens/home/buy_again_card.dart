import 'package:sure_wholesaler/widgets/app_shimmer.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/notifiers/buy_again_notifier.dart';
import 'package:sure_wholesaler/notifiers/order_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/screens/home/home_screen.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/components.dart';

class BuyAgainSliver extends ConsumerWidget {
  const BuyAgainSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(orderProvider).isLoading;
    final items = ref.watch(buyAgainProvider);

    if (isLoading) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 0, 8.h),
        sliver: SliverToBoxAdapter(
          child: SizedBox(
            height: 190.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(right: 16.w),
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (_, __) => AppShimmer.productSkeleton(
                width: 140.w,
                height: 190.h,
              ),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        SectionHeader(
          title: 'Buy Again',
          icon: Icons.replay_rounded,
          iconColor: AppColors.brandSeed,
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 0, 8.h),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: 190.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(right: 16.w),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, i) => BuyAgainCard(item: items[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BuyAgainCard extends StatelessWidget {
  final BuyAgainItem item;
  const BuyAgainCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = item.product;
    final detail = item.detail;
    final imageUrl =
        product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () => context.goToProductDetails(product),
      child: SizedBox(
        width: 140.w,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.brandSeed.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: 100.h,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.border.withValues(alpha: 0.3),
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: AppColors.border, size: 26.sp),
                            ),
                          )
                        : Container(
                            color: AppColors.border.withValues(alpha: 0.3),
                            child: Icon(Icons.shopping_bag_outlined,
                                color: AppColors.border, size: 26.sp),
                          ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.brandSeed,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay_rounded,
                                color: Colors.white, size: 9.sp),
                            SizedBox(width: 2.w),
                            Text(
                              'BUY AGAIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(9.w, 6.h, 9.w, 6.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            AppConfig.formatPrice(detail.pricePerPack),
                            style: TextStyle(
                              fontSize: 11.sp, // Reduced to fit Rs 100.00
                              fontWeight: FontWeight.w800,
                              color: AppColors.price,
                            ),
                          ),
                          if (detail.mrpPerPack != null && detail.mrpPerPack! > detail.pricePerPack) ...[
                            SizedBox(width: 4.w),
                            Text(
                              AppConfig.formatPrice(detail.mrpPerPack!),
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: AppColors.priceStrikethrough,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Qty: ${detail.totalUnits} ${product.unit}',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
