import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/models/notification_preferences_model.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';

final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesModel>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferencesModel> {
  @override
  Future<NotificationPreferencesModel> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return const NotificationPreferencesModel();

    final doc = await AppConfig.firestore
        .collection(AppCollections.users)
        .doc(uid)
        .get();

    final data = doc.data();
    if (data == null || data[FirestoreFields.notificationPreferences] == null) {
      return const NotificationPreferencesModel();
    }

    return NotificationPreferencesModel.fromMap(
      Map<String, dynamic>.from(
        data[FirestoreFields.notificationPreferences] as Map,
      ),
    );
  }

  Future<void> toggle(String key, bool value) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    // final current = state.valueOrNull ?? const NotificationPreferencesModel();
    // state = AsyncData(_updateField(current, key, value));

    await AppConfig.firestore
        .collection(AppCollections.users)
        .doc(uid)
        .set({
      FirestoreFields.notificationPreferences: {key: value}
    }, SetOptions(merge: true));
  }

  Future<void> toggleAll(bool value) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final updated = const NotificationPreferencesModel().withAll(value);
    state = AsyncData(updated);

    await AppConfig.firestore
        .collection(AppCollections.users)
        .doc(uid)
        .set(
      {FirestoreFields.notificationPreferences: updated.toMap()},
      SetOptions(merge: true),
    );
  }

  NotificationPreferencesModel _updateField(
    NotificationPreferencesModel prefs,
    String key,
    bool value,
  ) {
    switch (key) {
      case 'order':
        return prefs.copyWith(order: value);
      case 'delivery':
        return prefs.copyWith(delivery: value);
      case 'product':
        return prefs.copyWith(product: value);
      case 'stock':
        return prefs.copyWith(stock: value);
      case 'offer':
        return prefs.copyWith(offer: value);
      case 'system':
        return prefs.copyWith(system: value);
      default:
        return prefs;
    }
  }
}
