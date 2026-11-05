import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/models/category_model.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';
import 'package:sure_wholesaler/notifiers/category_notifier.dart';
import 'package:sure_wholesaler/screens/navigation/NavigationButton.dart';

import '../../core/routing/app_routes.dart';

class CategoryTabBarDelegate extends SliverPersistentHeaderDelegate {
  final WidgetRef ref;
  final List<CategoryModel> rootCategories;
  final bool isLoading;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CategoryTabBarDelegate({
    required this.ref,
    required this.rootCategories,
    required this.isLoading,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  double get minExtent => 100.h;

  @override
  double get maxExtent => 100.h;

  @override
  bool shouldRebuild(CategoryTabBarDelegate old) =>
      old.selectedIndex != selectedIndex || old.rootCategories.length != rootCategories.length || old.isLoading != isLoading;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ]
            : null,
      ),
      child: isLoading
          ? _buildLoadingTabs()
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              itemCount: rootCategories.length,
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;
                final category = rootCategories[index];
                return GestureDetector(
                  onTap: () {
                    onTabSelected(index);
                    context.push(
                      '/category-items/${category.docId}',
                      extra: {
                        'categoryName': category.name,
                        'sortBy': 'Popularity',
                      },
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon / image
                        _CategoryTabIcon(
                          category: category,
                          isSelected: isSelected,
                        ),
                        SizedBox(height: 6.h),
                        // Label
                        Text(
                          _shortName(category.name),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.brandSeed : AppColors.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // Animated underline
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 24.w : 0,
                          height: 3.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.brandSeed,
                                AppColors.brandSeed.withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
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

  Widget _buildLoadingTabs() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Container(
          width: 40.w,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  // Trim long category names to keep tabs compact
  String _shortName(String name) {
    const maxLen = 8;
    if (name.length <= maxLen) return name;
    return '${name.substring(0, maxLen - 1)}…';
  }
}

class _CategoryTabIcon extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  const _CategoryTabIcon({required this.category, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.w, // Fixed: use w for height of a circle too or just keep it square
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandSeed.withValues(alpha: 0.1) : AppColors.grey100,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: AppColors.brandSeed, width: 1.5.w) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: category.imageUrl != null
          ? ImageBuilder(
              url: category.imageUrl,
              fit: BoxFit.cover,
              errorWidget: Icon(Icons.category_outlined, size: 20.sp, color: AppColors.grey500),
            )
          : Icon(Icons.category_outlined, size: 20.sp, color: isSelected ? AppColors.brandSeed : AppColors.grey500),
    );
  }
}
