import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/core/theme/app_theme.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final List<_QuickAction> actions = [
      _QuickAction(
        icon: Icons.grid_view_rounded,
        label: 'Categories',
        subtitle: 'Browse all items',
        bgColor: scheme.primaryContainer,
        iconColor: scheme.onPrimaryContainer,
        route: AppRoutes.category,
      ),
      _QuickAction(
        subtitle: 'Get it in 30 mins',
        icon: Icons.electric_bolt_rounded,
        label: 'Quick Delivery',
        bgColor: AppColors.warningBg,
        iconColor: AppColors.warningDark,
        route: AppRoutes.quickDelivery,
      ),
      _QuickAction(
        icon: Icons.schedule_rounded,
        label: 'Scheduled',
        subtitle: 'Plan ahead',
        bgColor: AppColors.infoLight,
        iconColor: AppColors.infoBright,
        route: AppRoutes.scheduledScreen,
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(14.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 👈 2 columns
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio:
              1.0, // 👈 Providing more vertical space for the subtitle
        ),
        itemBuilder: (context, index) {
          return _GridItem(item: actions[index]);
        },
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final _QuickAction item;

  const _GridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: item.bgColor,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () {
          context.push(item.route);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.iconColor, size: 30.sp),
              SizedBox(height: 6.h),

              /// Title
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),

              /// Subtitle (only if exists)
              if (item.subtitle.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle; // 👈 NEW
  final Color bgColor;
  final Color iconColor;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle, // 👈 optional
    required this.bgColor,
    required this.iconColor,
    required this.route,
  });
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.lightTheme.appBarTheme.backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.search);
        },
        child: Container(
          height: 45.h,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppTheme.lightTheme.primaryColor),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              Icon(Icons.search,
                  color: AppTheme.lightTheme.primaryColor, size: 22.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Search "products"!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 61.h; // 45.h height + 16.h vertical padding

  @override
  double get minExtent => 61.h; // Same as maxExtent since it doesn't shrink

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false; // No state to rebuild
  }
}
