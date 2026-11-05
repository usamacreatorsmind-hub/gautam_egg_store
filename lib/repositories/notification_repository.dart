import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/constants/collections.dart';
import '../models/app_notification_model.dart';

abstract class NotificationRepository {
  Future<void> createNotification(AppNotificationModel notification);

  Future<List<AppNotificationModel>> getNotifications({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  });

  Stream<List<AppNotificationModel>> watchNotifications({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  });

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  });
}

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore = AppConfig.firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(Collections.notifications);

  Query<Map<String, dynamic>> _query({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  }) {
    if (userId != null) {
      return _collection.where('userId', isEqualTo: userId);
    }
    if (deliveryAgentId != null) {
      return _collection.where('deliveryAgentId', isEqualTo: deliveryAgentId);
    }
    if (adminId != null) {
      return _collection.where('adminId', isEqualTo: adminId);
    }
    throw Exception('Target id required');
  }

  @override
  Future<void> createNotification(AppNotificationModel notification) async {
    await _collection.add(notification.toFirestore());
  }

  @override
  Future<List<AppNotificationModel>> getNotifications({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  }) async {
    List<AppNotificationModel> list = [];
    if (userId != null) {
      final userSnap = await _collection.where('userId', isEqualTo: userId).get();
      final broadcastSnap = await _collection.where('targetRole', isEqualTo: 'all').get();

      final Map<String, AppNotificationModel> map = {};
      for (final doc in [...userSnap.docs, ...broadcastSnap.docs]) {
        final model = AppNotificationModel.fromFirestore(doc);
        if (model.id != null) {
          map[model.id!] = model;
        } else {
          list.add(model);
        }
      }
      list = map.values.toList();
    } else {
      final snap = await _query(
        userId: userId,
        deliveryAgentId: deliveryAgentId,
        adminId: adminId,
      ).get();
      list = snap.docs.map((d) => AppNotificationModel.fromFirestore(d)).toList();
    }

    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  @override
  Stream<List<AppNotificationModel>> watchNotifications({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  }) {
    if (userId != null) {
      final controller = StreamController<List<AppNotificationModel>>();
      QuerySnapshot<Map<String, dynamic>>? userSnap;
      QuerySnapshot<Map<String, dynamic>>? broadcastSnap;

      void update() {
        if (userSnap == null || broadcastSnap == null) return;
        final Map<String, AppNotificationModel> map = {};
        for (final doc in [...userSnap!.docs, ...broadcastSnap!.docs]) {
          final model = AppNotificationModel.fromFirestore(doc);
          if (model.id != null) {
            map[model.id!] = model;
          }
        }
        final list = map.values.toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        if (!controller.isClosed) {
          controller.add(list);
        }
      }

      final sub1 = _collection.where('userId', isEqualTo: userId).snapshots().listen((snap) {
        userSnap = snap;
        update();
      }, onError: controller.addError);

      final sub2 = _collection.where('targetRole', isEqualTo: 'all').snapshots().listen((snap) {
        broadcastSnap = snap;
        update();
      }, onError: controller.addError);

      controller.onCancel = () {
        sub1.cancel();
        sub2.cancel();
        controller.close();
      };

      return controller.stream;
    }

    return _query(
      userId: userId,
      deliveryAgentId: deliveryAgentId,
      adminId: adminId,
    ).snapshots().map((snap) {
      final list = snap.docs.map((d) => AppNotificationModel.fromFirestore(d)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead({
    String? userId,
    String? deliveryAgentId,
    String? adminId,
  }) async {
    final batch = _firestore.batch();
    Query<Map<String, dynamic>> q;
    if (userId != null) {
      q = _collection.where('userId', isEqualTo: userId).where('isRead', isEqualTo: false);
    } else {
      q = _query(
        userId: userId,
        deliveryAgentId: deliveryAgentId,
        adminId: adminId,
      ).where('isRead', isEqualTo: false);
    }

    final snap = await q.get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
