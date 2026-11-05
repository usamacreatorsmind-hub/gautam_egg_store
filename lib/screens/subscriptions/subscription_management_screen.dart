// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/features/invoicePdfService/InvoicePdfService.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/subscription_model.dart';
import 'package:sure_wholesaler/notifiers/order_notifier.dart';
import 'package:sure_wholesaler/notifiers/subscription_notifier.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schedule_card.dart';
import 'package:sure_wholesaler/screens/orders/Order_Screen.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';

import '../../core/constants/app_constants.dart';

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({
    super.key,
    this.initialTabIndex = 0,
  });
  final int initialTabIndex;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(selectedTabProvider('subscriptions').notifier).state =
            _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final subsAsync = ref.watch(userSubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(46.h),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.symmetric(horizontal: 5.w),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.transparent,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor:
                theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              TabLabelWidget(
                  scheme: theme.colorScheme,
                  label: 'Active',
                  index: 0,
                  tabKey: 'subscriptions'),
              TabLabelWidget(
                  scheme: theme.colorScheme,
                  label: 'Pending',
                  index: 1,
                  tabKey: 'subscriptions'),
              TabLabelWidget(
                  scheme: theme.colorScheme,
                  label: 'Paused / Cancelled',
                  index: 2,
                  tabKey: 'subscriptions'),
            ],
          ),
        ),
      ),
      body: subsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text('Failed to load subscriptions:\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (subs) => TabBarView(
          controller: _tabController,
          children: [
            _SubList(
              subs: subs
                  .where((s) => s.status == SubscriptionStatus.active)
                  .toList(),
              emptyLabel: 'No active subscriptions',
            ),
            _SubList(
              subs: subs
                  .where((s) => s.status == SubscriptionStatus.pending)
                  .toList(),
              emptyLabel: 'No pending subscriptions',
            ),
            _SubList(
              subs: subs
                  .where((s) =>
                      s.status == SubscriptionStatus.paused ||
                      s.status == SubscriptionStatus.cancelled)
                  .toList(),
              emptyLabel: 'None here',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SubList extends StatelessWidget {
  final List<SubscriptionModel> subs;
  final String emptyLabel;

  const _SubList({required this.subs, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (subs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.autorenew,
              size: 64.sp,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
            ),
            SizedBox(height: 12.h),
            Text(emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: subs.length,
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (context, i) => _SubCard(sub: subs[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SubCard extends ConsumerWidget {
  final SubscriptionModel sub;

  const _SubCard({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sub.products.map((p) => p.name).join(', '),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                _StatusChip(status: sub.status),
              ],
            ),
          ),

          // ── Product thumbnails ───────────────────────────────────
          if (sub.products.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
              child: SizedBox(
                height: 56.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sub.products.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final product = sub.products[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        width: 56.h,
                        height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: scheme.surfaceContainerHighest,
                        ),
                        child: product.imageUrls.isNotEmpty
                            ? ImageBuilder(
                                url: product.imageUrls.first,
                                width: 56.h,
                                height: 56.h,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.image,
                                size: 24.sp,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Schedule card ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: RepeatScheduleCard(schedule: sub.repeatSchedule),
          ),

          // ── Next delivery ────────────────────────────────────────
          if (sub.nextDeliveryAt != null)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.h),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 14.sp, color: AppColors.success),
                  SizedBox(width: 4.w),
                  Text(
                    'Next delivery: ${_formatDate(sub.nextDeliveryAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // ── Footer: total + actions ──────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
            child: Row(
              children: [
                  Text(
                    AppConfig.formatPrice(sub.total),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                const Spacer(),
                _ActionButtons(sub: sub),
              ],
            ),
          ),

          // ── Recurring orders ─────────────────────────────────────
          if (sub.id != null)
            _SubscriptionOrdersSection(subscriptionId: sub.id!),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final SubscriptionModel sub;

  const _ActionButtons({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(subscriptionNotifierProvider.notifier);

    Future<void> confirm({
      required String title,
      required String body,
      required Future<void> Function() onConfirm,
    }) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm')),
          ],
        ),
      );
      if (ok == true) {
        await onConfirm();
      }
    }

    switch (sub.status) {
      case SubscriptionStatus.active:
        return Row(
          children: [
            _OutlineBtn(
              label: 'Bill',
              icon: Icons.receipt_long_rounded,
              onTap: () => confirm(
                title: 'Generate Subscription Bill?',
                body:
                    'This will open the printable bill for this subscription.',
                onConfirm: () => SubscriptionPdfGenerator.printPdf(sub),
              ),
            ),
            SizedBox(width: 8.w),
            _OutlineBtn(
              label: 'Pause',
              icon: Icons.pause_circle_outline,
              onTap: () => confirm(
                title: 'Pause Subscription?',
                body: 'No orders will be created while paused.',
                onConfirm: () => notifier.pause(sub.id!),
              ),
            ),
            SizedBox(width: 8.w),
            _OutlineBtn(
              label: 'Cancel',
              icon: Icons.cancel_outlined,
              color: Theme.of(context).colorScheme.error,
              onTap: () => confirm(
                title: 'Cancel Subscription?',
                body: 'This cannot be undone.',
                onConfirm: () => notifier.cancel(sub.id!),
              ),
            ),
          ],
        );

      case SubscriptionStatus.paused:
        return Row(
          children: [
            _OutlineBtn(
              label: 'Resume',
              icon: Icons.play_circle_outline,
              color: AppColors.success,
              onTap: () => confirm(
                title: 'Resume Subscription?',
                body: 'Deliveries will resume on the next scheduled date.',
                onConfirm: () => notifier.resume(sub.id!),
              ),
            ),
            SizedBox(width: 8.w),
            _OutlineBtn(
              label: 'Cancel',
              icon: Icons.cancel_outlined,
              color: Theme.of(context).colorScheme.error,
              onTap: () => confirm(
                title: 'Cancel Subscription?',
                body: 'This cannot be undone.',
                onConfirm: () => notifier.cancel(sub.id!),
              ),
            ),
          ],
        );

      case SubscriptionStatus.pending:
        return Text(
          'Awaiting activation',
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );

      default: // cancelled
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg) = switch (status) {
      SubscriptionStatus.active => (
          AppColors.successLight,
          AppColors.successDark
        ),
      SubscriptionStatus.pending => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      SubscriptionStatus.paused => (AppColors.warningBg, AppColors.warningDark),
      _ => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4.r)),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      icon: Icon(icon, size: 14.sp),
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionOrdersSection extends ConsumerWidget {
  final String subscriptionId;

  const _SubscriptionOrdersSection({required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync =
        ref.watch(ordersForSubscriptionProvider(subscriptionId));

    return ordersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 14.w),
              title: Text(
                'Recurring Orders (${orders.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              children: orders.map((order) => _OrderRow(order: order)).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  final OrderModel order;

  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color bg, Color fg) = switch (order.status.toLowerCase()) {
      OrderStatus.delivered => (AppColors.successLight, AppColors.successDark),
      OrderStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
      OrderStatus.packed || OrderStatus.outForDelivery => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () =>
          context.pushNamed(RouteNames.orderDetailScreen, extra: order),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              AppConfig.formatPrice(order.total),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(4.r)),
              child: Text(
                order.status.toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: fg, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
