import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/constants/asset_constants.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/notifiers/order_notifier.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';

final selectedTabProvider = StateProvider.autoDispose.family<int, String>((ref, key) => 0);

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(selectedTabProvider('orders').notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ordersAsync = ref.watch(orderProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        toolbarHeight: 60.h, // Adjusted height after removing filter chips
        elevation: 0,
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: 5.w),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.transparent,
          unselectedLabelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
          labelColor: scheme.onPrimary,
          unselectedLabelColor: scheme.onPrimary.withValues(alpha: 0.6),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            TabLabelWidget(scheme: scheme, label: 'Pending', index: 0, tabKey: 'orders'),
            TabLabelWidget(scheme: scheme, label: 'Confirmed', index: 1, tabKey: 'orders'),
            TabLabelWidget(scheme: scheme, label: 'Packed', index: 2, tabKey: 'orders'),
            TabLabelWidget(scheme: scheme, label: 'Out for Delivery', index: 3, tabKey: 'orders'),
            TabLabelWidget(scheme: scheme, label: 'Delivered', index: 4, tabKey: 'orders'),
            TabLabelWidget(scheme: scheme, label: 'Cancelled', index: 5, tabKey: 'orders'),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, stack) {
          print(e);
          print(stack);
          return Center(child: Text('Error: $e'));
        },
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _OrderList(baseProvider: pendingOrdersProvider),
            _OrderList(baseProvider: confirmedOrdersProvider),
            _OrderList(baseProvider: processingOrdersProvider), // Packed
            _OrderList(baseProvider: shippedOrdersProvider), // Out for Delivery
            _OrderList(baseProvider: deliveredOrdersProvider),
            _OrderList(baseProvider: cancelledOrdersProvider),
          ],
        ),
      ),
    );
  }
}

class TabLabelWidget extends ConsumerWidget {
  const TabLabelWidget({
    required this.label,
    required this.scheme,
    required this.index,
    required this.tabKey,
    this.fullWidth = false,
    super.key,
  });

  final ColorScheme scheme;
  final String label;
  final int index;
  final String tabKey;
  final bool fullWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedTabProvider(tabKey)) == index;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: isSelected ? scheme.onPrimary : scheme.onPrimary.withValues(alpha: 0.15),
      ),
      alignment: fullWidth ? Alignment.center : null,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? scheme.primary : scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final ProviderListenable<List<OrderModel>> baseProvider;

  const _OrderList({required this.baseProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allOrders = ref.watch(baseProvider);

    final orders = allOrders.toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AssetConstants.illuShoppingCart,
              height: 140.h,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: orders.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.15),
        ),
      ),
      child: GestureDetector(
        onTap: () => context.pushNamed(RouteNames.orderDetailScreen, extra: order),
        child: Column(
          children: [
            _buildHeader(theme, context),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Divider(
                height: 1,
                color: scheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            _buildBody(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context) {
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 18.w, 8.w, 18.w), // Reduced right padding for share button
      child: Row(
        children: [
          /// Order Icon
          Container(
            height: 54.w,
            width: 54.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              color: scheme.primary.withOpacity(0.10),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: scheme.primary,
              size: 26.sp,
            ),
          ),

          SizedBox(width: 14.w),

          /// Order Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.sp,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2.h),
                Builder(
                  builder: (context) {
                    final names = order.productDetails.values.map((e) {
                      final String sizeStr = e.unit.isNotEmpty ? ' (${e.unit})' : '';
                      return '${e.name}$sizeStr';
                    }).join(', ');

                    return Text(
                      names.isEmpty ? 'Wholesale Order' : names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                    );
                  },
                ),
                SizedBox(height: 4.h),
                _DeliveryTypeBadge(
                  type: order.deliveryType,
                  scheme: scheme,
                ),
              ],
            ),
          ),

          /// Status & Share
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(theme),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => _shareOrder(context),
                icon: Icon(Icons.share_outlined, size: 20.sp, color: scheme.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareOrder(BuildContext context) {
    final firstProduct = order.productDetails.values.firstOrNull;
    final amountStr = AppConfig.formatPrice(order.computedTotal);
    final productName = firstProduct?.name ?? 'Items';

    // Blinkit-style share text
    final shareText = "🛍️ My ${AppConfig.appName} order is on its way!\n\n"
        "💰 Order Total: $amountStr\n"
        "📦 Item: $productName${order.productDetails.length > 1 ? ' & ${order.productDetails.length - 1} more' : ''}\n\n"
        "Download ${AppConfig.appName} for bulk savings!";

    Share.share(shareText);
  }

  Widget _buildStatusChip(ThemeData theme) {
    final scheme = theme.colorScheme;

    final Color bg;
    final Color fg;

    switch (order.status.toLowerCase()) {
      case OrderStatus.pending:
        bg = AppColors.warningBg;
        fg = AppColors.warningDark;
        break;

      case OrderStatus.confirmed:
      case OrderStatus.packed:
      case OrderStatus.outForDelivery:
        bg = scheme.primary.withValues(alpha: 0.12);
        fg = scheme.primary;
        break;

      case OrderStatus.delivered:
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        break;

      case OrderStatus.cancelled:
        bg = scheme.error.withOpacity(0.12);
        fg = scheme.error;
        break;

      default:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 7.h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        order.status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Date + Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    order.createdAt.toString().split(' ')[0],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                AppConfig.formatPrice(order.computedTotal),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          /// Product Images
          if (order.productDetails.isNotEmpty)
            SizedBox(
              height: 72.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.productDetails.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  final detail = order.productDetails.values.elementAt(index);
                  final imageUrl = detail.imageUrl;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: Container(
                      width: 72.h,
                      height: 72.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        color: scheme.surfaceContainerHighest,
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? ImageBuilder(
                              url: imageUrl,
                              width: 72.h,
                              height: 72.h,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.image_outlined,
                              size: 24.sp,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                    ),
                  );
                },
              ),
            ),

          SizedBox(height: 18.h),

          /// Footer
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 18.sp,
                color: scheme.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "Tap to view complete order details",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryTypeBadge extends StatelessWidget {
  final DeliveryType type;
  final ColorScheme scheme;

  const _DeliveryTypeBadge({required this.type, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final isQuick = type == DeliveryType.quick;
    return Row(
      children: [
        Icon(
          isQuick ? Icons.flash_on_rounded : Icons.schedule_rounded,
          size: 11.sp,
          color: isQuick ? AppColors.warning : scheme.primary,
        ),
        SizedBox(width: 3.w),
        Text(
          isQuick ? 'Quick' : 'Scheduled',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: isQuick ? AppColors.warning : scheme.primary,
          ),
        ),
      ],
    );
  }
}
