import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/core/theme/app_theme.dart';
import 'package:sure_wholesaler/features/campaign/providers/campaign_providers.dart';
import 'package:sure_wholesaler/features/campaign/widgets/campaign_card.dart';
import 'package:sure_wholesaler/features/searchLog/providers/popular_search_provider.dart';
import 'package:sure_wholesaler/features/searchLog/providers/search_log_provider.dart';
import 'package:sure_wholesaler/models/brand_model.dart';
import 'package:sure_wholesaler/models/category_model.dart';
import 'package:sure_wholesaler/notifiers/brand_notifier.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/category_notifier.dart';
import 'package:sure_wholesaler/notifiers/flash_sale_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/screens/home/buy_again_card.dart';
import 'package:sure_wholesaler/services/warehouse_service.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/utils/locationProviders.dart' as loc;
import 'package:sure_wholesaler/widgets/SlidersWidget.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/widgets/app_shimmer.dart';
import 'package:sure_wholesaler/widgets/components.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';
import 'package:tuple/tuple.dart';
import '../../models/cart_model.dart';
import '../../models/delivery_model.dart';
import '../../widgets/Product_Card_Widget.dart';
import 'all_category_tab_bar.dart';
import 'footer_card.dart';
import 'new_products_sliver.dart';
import 'sale_cards.dart';
import 'widgets/location_selection_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final saleCards = <SaleCardModel>[
    SaleCardModel(
      title: "Under",
      discountType: DiscountType.under,
      value: "99",
      colors: [const Color(0xffFF6B6B), const Color(0xffFF8E53)],
    ),
    SaleCardModel(
      title: "Flat",
      discountType: DiscountType.flat,
      value: "50%",
      colors: [const Color(0xff4facfe), const Color(0xff00f2fe)],
    ),
  ];

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  Timer? _debounce;
  int _selectedTab = 0;

  void updateSelectedTab(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_isSearchActive) {
        setState(() => _isSearchActive = true);
      }
    });
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      ref.read(productSearchQueryProvider.notifier).state = trimmed;
    });
    final active = query.isNotEmpty;
    if (active != _isSearchActive) {
      setState(() => _isSearchActive = active);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    ref.read(productSearchQueryProvider.notifier).state = '';
    setState(() => _isSearchActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider).value;
    final cartItemCount = cart?.items.where((i) => !i.isSubscription).fold<int>(0, (sum, i) => sum + i.quantity) ?? 0;

    return PopScope(
      canPop: !_isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSearch();
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Cleaner background
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandSeed.withValues(alpha: 0.12),
                    AppColors.brandSeed.withValues(alpha: 0.03),
                    Colors.white,
                  ],
                ),
              ),
            ),
            CustomScrollView(
              controller: _isSearchActive ? null : _scrollController,
              physics: _isSearchActive ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              slivers: [
                const _HomeAppBar(),
                const _HomeCategoryTabs(),
                if (_isSearchActive) _SearchResultsSliver(onClear: _clearSearch) else const _HomeContentSliver(),
              ],
            ),
            if (cartItemCount > 0 && !_isSearchActive)
              Positioned(
                bottom: 12.h,
                left: 16.w,
                right: 16.w,
                child: _buildCartBar(cartItemCount),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar(int itemCount) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.cart),
      child: Container(
        height: 64.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandSeed, AppColors.brand100],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandSeed.withValues(alpha: 0.4),
              blurRadius: 15.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24.sp),
                Positioned(
                  top: -5.h,
                  right: -5.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Text(
                      itemCount.toString(),
                      style: TextStyle(
                        color: AppColors.brandSeed,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ITEMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'VIEW CART',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: 68.h,
      backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
      ),
      title: const _AppBarContent(),
      bottom: const _SearchFieldBottom(),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}

class _SearchFieldBottom extends ConsumerWidget implements PreferredSizeWidget {
  const _SearchFieldBottom();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = context.findAncestorStateOfType<_HomeScreenState>()!;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.brandSeed.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: TextField(
        controller: state._searchController,
        focusNode: state._searchFocusNode,
        onChanged: state._onSearchChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search products, brands...',
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.brandSeed, size: 20.sp),
          suffixIcon: state._isSearchActive
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppActionChip(label: "Clear", icon: Icons.clear, onTap: state._clearSearch),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.r),
            borderSide: BorderSide(color: AppColors.border, width: 1.5.w),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.r),
            borderSide: BorderSide(color: AppColors.brandSeed, width: 1.0.w),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}

class _HomeCategoryTabs extends ConsumerWidget {
  const _HomeCategoryTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>()!;
    if (homeState._isSearchActive) return const SliverToBoxAdapter();

    final categoriesAsync = ref.watch(categoryProvider);
    final rootCategories = ref.watch(categoryTreeProvider);

    return SliverPersistentHeader(
      pinned: false,
      delegate: CategoryTabBarDelegate(
        ref: ref,
        rootCategories: rootCategories,
        isLoading: categoriesAsync.isLoading,
        selectedIndex: homeState._selectedTab,
        onTabSelected: homeState.updateSelectedTab,
      ),
    );
  }
}

class _HomeContentSliver extends ConsumerWidget {
  const _HomeContentSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SliderWidget()),
        const QuickActionsSliver(),
        // const FlashSaleSliver(),
        const BuyAgainSliver(),
        const _TopElectronicsSliver(), // Dedicated Section for Electronics
        const DiscountSliver(),
        const NewProductsSliver(),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        const FeaturedBrandsSliver(),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        // const SliverToBoxAdapter(child: MobileFooterCard()),
      ],
    );
  }
}

class _TopElectronicsSliver extends ConsumerWidget {
  const _TopElectronicsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String electronicsId = "3BRYvntGLk7TxfQZFUB1";
    final productsAsync = ref.watch(productsByCategoryStreamProvider(electronicsId));

    return productsAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (products) {
        if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        final displayItems = products.take(6).toList();

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Top Electronics',
                  icon: Icons.devices_other_rounded,
                  iconColor: Colors.blue,
                  onSeeAll: () => context.push(
                    '/category-items/$electronicsId',
                    extra: {'categoryName': 'Electronics'},
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: ProductCardWidget.gridHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayItems.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemBuilder: (context, i) => SizedBox(
                      width: ProductCardWidget.gridWidth,
                      child: ProductCardWidget(
                        product: displayItems[i],
                        layout: ProductCardLayout.grid,
                        onAddToCart: () {
                          final product = displayItems[i];
                          final activeVariants = product.activePackVariants;
                          if (activeVariants.isEmpty) return;
                          final variant = activeVariants.first;
                          ref.read(cartProvider.notifier).addToCart(
                                CartItem.fromVariant(
                                  variant: variant,
                                  deliveryType: DeliveryType.quick,
                                  warehouseId: 'default',
                                ),
                              );
                          AppNotifications.showPremiumNotification(
                            context,
                            title: 'Success',
                            message: '${product.name} added to cart',
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultsSliver extends ConsumerWidget {
  final VoidCallback onClear;

  const _SearchResultsSliver({required this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warehouseIds = ref.watch(resolvedWarehouseProvider);
    final results = ref.watch(searchedProductsProvider);
    final query = ref.watch(productSearchQueryProvider);

    ref.listen(searchedProductsProvider, (_, next) {
      next.whenData((products) {
        final q = ref.read(productSearchQueryProvider);
        if (products.isEmpty && q.isNotEmpty) {
          ref.read(submitSearchLogProvider)(
            keyword: q,
            hubId: warehouseIds.join(','),
            serviceArea: ref.read(loc.effectiveLocationProvider)?.fullAddress ?? 'Unknown Location',
          );
        }
      });
    });

    final popularSearches = ref.watch(fetchTrendingSearchesProvider);

    if (query.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Popular Searches", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 14.h),
              popularSearches.when(
                loading: () => const AppLoader(size: 24),
                error: (e, __) {
                  debugPrint('Error loading popular searches: $e');
                  return const Text('Failed to load');
                },
                data: (searches) => Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: searches
                      .map((s) => AppActionChip(
                            label: s.keyword,
                            icon: Icons.trending_up_rounded,
                            onTap: () {
                              ref.read(productSearchQueryProvider.notifier).state = s.keyword;
                              ref.read(incrementSearchCount)(s.keyword);
                            },
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 40.h),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 110.h,
                        width: 110.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withValues(alpha: 0.08),
                        ),
                        child: Icon(Icons.search_rounded, size: 52.sp, color: scheme.primary),
                      ),
                      SizedBox(height: 24.h),
                      Text('Search Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Text(
                          'Find groceries, daily essentials and more instantly',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4.h),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return results.when(
      loading: () => const SliverFillRemaining(child: Center(child: AppLoader())),
      error: (_, __) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 54.sp, color: scheme.error),
              SizedBox(height: 12.h),
              Text('Something went wrong', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 110.h,
                      width: 110.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.error.withValues(alpha: 0.08),
                      ),
                      child: Icon(Icons.search_off_rounded, size: 52.sp, color: scheme.error),
                    ),
                    SizedBox(height: 22.h),
                    Text('No products found', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Text('We couldn’t find anything for "$query"',
                        textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: ProductCardWidget(
                    product: products[index],
                    layout: ProductCardLayout.list,
                    onTap: onClear,
                    onAddToCart: () {
                      final product = products[index];
                      final activeVariants = product.activePackVariants;
                      if (activeVariants.isEmpty) return;
                      final variant = activeVariants.first;
                      final deliveryType =
                          variant.availableDeliveryTypes.isNotEmpty ? variant.availableDeliveryTypes.first : DeliveryType.quick;
                      final warehouseId = variant.inventory?.warehouseId ??
                          ref.read(cartProvider).value?.warehouseId ??
                          ref.read(resolvedWarehouseProvider).firstOrNull ??
                          'default';
                      ref
                          .read(cartProvider.notifier)
                          .addToCart(CartItem.fromVariant(variant: variant, deliveryType: deliveryType, warehouseId: warehouseId));

                      AppNotifications.showPremiumNotification(
                        context,
                        title: 'Success',
                        message: '${product.name} added to cart',
                        buttonLabel: 'VIEW',
                        onButtonPressed: () => context.push('/cart'),
                      );
                    },
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}

class _AppBarContent extends ConsumerWidget {
  const _AppBarContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(loc.effectiveLocationProvider);
    final warehouse = ref.watch(nearestWarehouseProvider).asData?.value;
    final address = location != null && location.fullAddress.isNotEmpty ? location.fullAddress : 'Detecting location...';

    String? etaText;
    if (location != null && warehouse != null) {
      final roadDistance = ref
          .watch(loc.roadDistanceBetweenCoordinatesProvider(
            Tuple2(LatLng(location.latitude, location.longitude), LatLng(warehouse.latitude, warehouse.longitude)),
          ))
          .asData
          ?.value;

      if (roadDistance != null) {
        final km = roadDistance / 1000;
        etaText = '${(km * 5).toStringAsFixed(0)} min';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(AppConfig.appName, style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold, color: AppColors.onBrand)),
            ),
            if (etaText != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.onBrand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.electric_bolt_rounded, color: Colors.orange, size: 10.sp),
                    SizedBox(width: 2.w),
                    Text(etaText, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.onBrand)),
                  ],
                ),
              ),
            ],
          ],
        ),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const LocationSelectionBottomSheet(),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  (address == 'Detecting location...' && location == null) ? 'Enable location to see delivery time' : address,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.onBrand.withValues(alpha: 0.8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14.sp,
                  color: AppColors.onBrand.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuickActionsSliver extends ConsumerWidget {
  const QuickActionsSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    // Since only 2 cards are active, we use 2 columns to fill width
    final crossAxisCount = width > 600 ? 4 : 2;
    // Wider aspect ratio for 2 columns to look professional
    final childAspectRatio = width > 600 ? 1.0 : 1.7;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12.w,
          crossAxisSpacing: 12.w,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildListDelegate([
          _QuickActionTile(
            icon: Icons.category_rounded,
            label: 'All Categories',
            color: const Color(0xffFFF8E1),
            iconColor: const Color(0xffFFA000),
            onTap: () => context.push(AppRoutes.category),
          ),
          _QuickActionTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Best Deals',
            color: const Color(0xffFFEBEE),
            iconColor: const Color(0xffD32F2F),
            onTap: () => context.push(
              AppRoutes.categoryItemsPath('all'),
              extra: {
                'categoryName': 'Best Deals',
                'sortBy': 'Discount: High to Low',
                'minDiscount': 1,
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: iconColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: iconColor.withValues(alpha: 0.8),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeaturedBrandsSliver extends ConsumerWidget {
  const FeaturedBrandsSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);
    return brandsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              const AppLoader(size: 24),
              SizedBox(height: 8.h),
              const Text("Loading Brands..."),
            ],
          ),
        ),
      ),
      error: (e, st) {
        debugPrint('Brands Stream Error: $e');
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: TextButton.icon(
                onPressed: () => ref.read(brandsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Retry loading brands", style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        );
      },
      data: (brands) {
        final active = brands.where((b) => b.isActive).toList();
        if (active.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(height: 4.h),
                    const Text("No active brands found", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brandSeed.withValues(alpha: 0.08), AppColors.brandSeed.withValues(alpha: 0.02)]),
                border: Border.all(color: AppColors.brandSeed.withValues(alpha: 0.12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionHeader(
                        title: 'Brands',
                        icon: Icons.verified_rounded,
                        iconColor: AppColors.brandSeed,
                        onSeeAll: () => context.push(AppRoutes.brandScreen)),
                    GridView.builder(
                      padding: EdgeInsets.fromLTRB(0, 10.h, 0, 0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: active.length > 4 ? 4 : active.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount(context),
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 10.h,
                        mainAxisExtent: 115.w,
                      ),
                      itemBuilder: (ctx, i) => _BrandLogoChip(brand: active[i]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return 3;
    if (w < 600) return 4;
    return 5;
  }
}

class _BrandLogoChip extends StatelessWidget {
  final BrandModel brand;

  const _BrandLogoChip({required this.brand});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.categoryItemsPath('all'),
          extra: {'brandId': brand.id, 'brandName': brand.name, 'categoryName': brand.name, 'sortBy': 'Popularity'}),
      child: Column(
        children: [
          Container(
            height: 72.w,
            width: 72.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.brandSeed.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: brand.logoUrl != null
                  ? ImageBuilder(
                      url: brand.logoUrl!,
                      fit: BoxFit.contain, // Logos look better with contain
                      placeholder: const AppLoader(size: 16),
                    )
                  : _BrandInitial(name: brand.name),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            brand.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandInitial extends StatelessWidget {
  final String name;

  const _BrandInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: AppColors.brandSeed.withValues(alpha: 0.1),
        child: Center(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.brandSeed))));
  }
}

class DiscountSliver extends ConsumerWidget {
  const DiscountSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topDiscountsAsync = ref.watch(topDiscountsProvider);

    return topDiscountsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: AppShimmer(height: 220.h, width: double.infinity, radius: 24.r),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (products) {
        if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        // Show top 12 items with highest discount
        final items = products.take(12).toList();

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.discount.withValues(alpha: 0.12),
                    AppColors.discount.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(color: AppColors.discount.withValues(alpha: 0.15)),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  children: [
                    SectionHeader(
                      title: 'Best Deals',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: AppColors.discount,
                      onSeeAll: () => context.push(
                        AppRoutes.categoryItemsPath('all'),
                        extra: {
                          'categoryName': 'Best Deals',
                          'sortBy': 'Discount: High to Low',
                          'minDiscount': 1,
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: ProductCardWidget.gridHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(right: 16.w),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12.w),
                        itemBuilder: (context, i) => SizedBox(
                          width: ProductCardWidget.gridWidth,
                          child: ProductCardWidget(
                            product: items[i],
                            layout: ProductCardLayout.grid,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FlashSaleSliver extends ConsumerStatefulWidget {
  const FlashSaleSliver({super.key});

  @override
  ConsumerState<FlashSaleSliver> createState() => _FlashSaleSliverState();
}

class _FlashSaleSliverState extends ConsumerState<FlashSaleSliver> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final sale = ref.watch(liveFlashSaleProvider);
    if (sale == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final remaining = sale.timeRemaining;
    if (remaining == Duration.zero) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final countdownText = h > 0 ? '${_twoDigit(h)}:${_twoDigit(m)}:${_twoDigit(s)}' : '${_twoDigit(m)}:${_twoDigit(s)}';

    // Fetch products explicitly for the flash sale IDs
    final saleProductsAsync = ref.watch(productsByCategoriesProvider(const [])); // Placeholder logic

    // A better approach is to use a dedicated provider for the specific IDs
    // For now, let's use the all products and filter for simplicity,
    // but ensure it's not paginated (so we don't miss items).
    final allProductsAsync = ref.watch(productsProvider);

    return allProductsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: AppShimmer(height: 180.h, width: double.infinity, radius: 16.r),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (allProducts) {
        final saleProducts = allProducts.where((p) => sale.productIds.contains(p.id)).toList();

        if (saleProducts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlashSaleHeader(
                title: sale.title,
                subtitle: sale.subtitle,
                countdownText: countdownText,
              ),
              SizedBox(
                height: ProductCardWidget.gridHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
                  itemCount: saleProducts.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (context, i) {
                    final product = saleProducts[i];
                    return SizedBox(
                      width: ProductCardWidget.gridWidth,
                      child: ProductCardWidget(
                        product: product,
                        layout: ProductCardLayout.grid,
                        customBadge: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.errorDeep, AppColors.errorLight]),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: Colors.white, size: 9.sp),
                              SizedBox(width: 2.w),
                              Text(
                                '${sale.discountPercent ?? 0}% OFF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlashSaleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String countdownText;

  const _FlashSaleHeader({required this.title, required this.subtitle, required this.countdownText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.errorDeep, AppColors.errorLight], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: AppColors.errorLight.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.bolt_rounded, color: Colors.white, size: 20.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.sp),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ENDS IN',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75), fontSize: 8.sp, fontWeight: FontWeight.w700, letterSpacing: 1)),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.w)),
                child: Text(
                  countdownText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CampaignSliver extends ConsumerWidget {
  const CampaignSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(fetchCampaignProvider);
    return campaignsAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (campaigns) {
        if (campaigns.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
            delegate:
                SliverChildBuilderDelegate((context, index) => CampaignCard(campaign: campaigns[index]), childCount: campaigns.length));
      },
    );
  }
}
