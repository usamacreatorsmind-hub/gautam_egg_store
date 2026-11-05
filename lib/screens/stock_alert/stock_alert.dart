import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/models/stock_alert_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/notifiers/stock_alert_notifier.dart';
import 'package:intl/intl.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class StockAlertScreen extends ConsumerStatefulWidget {
  const StockAlertScreen({super.key});

  @override
  ConsumerState<StockAlertScreen> createState() => _StockAlertScreenState();
}

class _StockAlertScreenState extends ConsumerState<StockAlertScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertsState = ref.watch(userStockAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: const Text('Stock Alerts'),
        centerTitle: true,
      ),
      body: alertsState.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
              SizedBox(height: 12.h),
              Text(
                'Failed to load alerts',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return _buildEmptyState(theme);
          }
          return _buildAlertsList(theme, alerts);
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64.sp,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Stock Alerts',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'When a product is out of stock, you can subscribe to get notified when it\'s back.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(ThemeData theme, List<StockAlertModel> alerts) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(theme, alert);
      },
    );
  }

  Widget _buildAlertCard(ThemeData theme, StockAlertModel alert) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.onBrand),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(theme);
      },
      onDismissed: (_) {
        ref.read(userStockAlertsProvider.notifier).unsubscribe(
              productId: alert.productId,
            );
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: 'Alert removed for ${alert.productName}',
        );
      },
      child: InkWell(
        onTap: () async {
          final product = await ref.read(productByIdProvider(alert.productId).future);
          if (product == null || !mounted) return;
          context.goToProductDetails(product);
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.productName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      alert.createdAt != null
                          ? 'Subscribed on ${DateFormat('dd MMM yyyy').format(alert.createdAt!)}'
                          : 'Waiting for restock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _onRemoveAlert(alert),
                icon: Icon(
                  Icons.close,
                  size: 20.sp,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(ThemeData theme) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Alert'),
        content: const Text(
          'Are you sure you want to remove this stock alert?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _onRemoveAlert(StockAlertModel alert) async {
    final confirmed = await _showDeleteConfirmation(Theme.of(context));
    if (confirmed == true) {
      final success = await ref.read(userStockAlertsProvider.notifier).unsubscribe(productId: alert.productId);

      if (mounted) {
        if (success) {
          AppNotifications.showSuccess(
            context,
            title: 'Success',
            message: 'Alert removed for ${alert.productName}',
          );
        } else {
          AppNotifications.showError(
            context,
            title: 'Error',
            message: 'Failed to remove alert',
          );
        }
      }
    }
  }
}
