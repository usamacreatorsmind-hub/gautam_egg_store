import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:sure_wholesaler/widgets/app_shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/components.dart';

class NewProductsSliver extends ConsumerWidget {
  const NewProductsSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newArrivalsAsync = ref.watch(newArrivalsProvider);

    return newArrivalsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: AppShimmer(height: 220.h, width: double.infinity, radius: 24.r),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (products) {
        if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        final items = products.take(12).toList();

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.brandSeed.withValues(alpha: 0.1)),
                gradient: LinearGradient(
                  colors: [AppColors.brandSeed.withValues(alpha: 0.05), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Column(
                children: [
                  SectionHeader(
                    title: 'New Arrivals',
                    icon: Icons.new_releases_rounded,
                    iconColor: AppColors.brandSeed,
                    onSeeAll: () => context.push(
                      AppRoutes.categoryItemsPath('all'),
                      extra: {
                        'categoryName': 'New Arrivals',
                        'sortBy': 'Newest',
                      },
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: ProductCardWidget.gridHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(width: 12.w),
                      itemBuilder: (context, i) => SizedBox(
                        width: ProductCardWidget.gridWidth,
                        child: ProductCardWidget(
                          product: items[i],
                          layout: ProductCardLayout.grid,
                          customBadge: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(color: AppColors.brandSeed, borderRadius: BorderRadius.circular(4.r)),
                            child: Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
