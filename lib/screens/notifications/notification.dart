import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/notifiers/notification_notifier.dart';
import 'package:sure_wholesaler/models/app_notification_model.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  'Failed to load notifications',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(notificationNotifierProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: theme.disabledColor),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(notification: n);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = notification.isRead != true;

    return ListTile(
      tileColor: isUnread ? theme.colorScheme.primary.withOpacity(0.05) : null,
      leading: CircleAvatar(
        backgroundColor: _iconColor(notification.type).withOpacity(0.1),
        child: Icon(_icon(notification.type),
            color: _iconColor(notification.type), size: 20),
      ),
      title: Text(
        notification.title ?? '',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            notification.body ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        // Mark as read
        if (notification.id != null) {
          ref
              .read(notificationNotifierProvider.notifier)
              .markAsRead(notification.id!);
        }

        // Priority 1: Navigation by orderId
        final orderId = notification.orderId ??
            notification.data?['orderId'] ??
            notification.data?['order_id'];

        if (orderId != null && orderId.toString().isNotEmpty) {
          context.push(AppRoutes.orderDetailByIdPath(orderId.toString()));

          // context.pushNamed(RouteNames.orderDetailScreen, extra: orderId!);

          return;
        }

        // Priority 2: Navigation by productId
        final productId = notification.productId ??
            notification.data?['productId'] ??
            notification.data?['product_id'];

        if (productId != null && productId.toString().isNotEmpty) {
          context.push(extra: orderId, AppRoutes.orderDetailById);
          return;
        }

        // Priority 3: Fallback by type
        if (notification.type == NotificationType.offer) {
          context.push(AppRoutes.offers);
          return;
        }

        if (notification.type == NotificationType.product) {
          context.push(AppRoutes.category);
          return;
        }

        // If no ID is found, just show a message if it's not a generic system notification
        AppNotifications.showError(
          context,
          title: 'Error',
          message: 'Notification details not available',
        );
      },
    );
  }

  IconData _icon(NotificationType? type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.delivery:
        return Icons.local_shipping_outlined;
      case NotificationType.product:
        return Icons.inventory_2_outlined;
      case NotificationType.stock:
        return Icons.warehouse_outlined;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.system:
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor(NotificationType? type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.info;
      case NotificationType.delivery:
        return AppColors.statusAccepted;
      case NotificationType.product:
        return AppColors.infoDark;
      case NotificationType.stock:
        return AppColors.statusRiderAssigned;
      case NotificationType.offer:
        return AppColors.success;
      case NotificationType.system:
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
