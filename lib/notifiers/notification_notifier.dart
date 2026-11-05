import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/models/app_notification_model.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/repositories/notification_repository.dart';

/// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

/// Notifier provider
final notificationNotifierProvider =
    StreamNotifierProvider<NotificationNotifier, List<AppNotificationModel>>(
  NotificationNotifier.new,
);

class NotificationNotifier extends StreamNotifier<List<AppNotificationModel>> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Stream<List<AppNotificationModel>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value([]);

    return _repo.watchNotifications(userId: userId);
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _repo.markAllAsRead(userId: userId);
  }
}
