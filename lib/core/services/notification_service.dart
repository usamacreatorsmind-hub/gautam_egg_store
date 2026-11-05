import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// init
  static Future<void> init() async {
    await _requestPermission();
    await _getToken();
    await getInstallationId();
    _listenTokenRefresh();
    _foregroundListener();
    try {
      await _messaging.subscribeToTopic('all');
      if (kDebugMode) debugPrint("Subscribed to FCM topic 'all'");
    } catch (e) {
      if (kDebugMode) debugPrint("Error subscribing to topic 'all': $e");
    }
  }

  /// Set up AwesomeNotifications action listeners.
  /// Must be called from a widget's initState (after MaterialApp is built).
  static void setupActionListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  /// Handle notification tap — works for foreground and background states.
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (kDebugMode == true) debugPrint("Notification tapped: $payload");

    if (payload == null) return;
    final data = payload.map((k, v) => MapEntry(k, v ?? ''));
    _navigateFromPayload(data);
  }

  /// Handle terminated state: check if app was opened from a notification.
  /// Call this after the router is ready (e.g. in MyApp initState with a delay).
  static Future<void> handleTerminatedState() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      if (kDebugMode == true) {
        debugPrint("App opened from terminated notification: ${message.data}");
      }
      _navigateFromPayload(
        message.data.map((k, v) => MapEntry(k, v.toString())),
      );
    }
  }

  /// Handle background-to-foreground: FCM onMessageOpenedApp.
  static void setupBackgroundTapListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode == true) {
        debugPrint("App resumed from background notification: ${message.data}");
      }
      _navigateFromPayload(
        message.data.map((k, v) => MapEntry(k, v.toString())),
      );
    });
  }

  /// Navigate based on notification payload data.
  static void _navigateFromPayload(Map<String, String> data) {
    final type = data['type'] ?? '';

    // All order-related notification types carry an orderId
    const orderTypes = {
      'order',
      'order_placed',
      'order_status_update',
    };

    if (orderTypes.contains(type)) {
      final orderId = data['orderId'] ?? '';
      if (orderId.isNotEmpty) {
        _pushWhenReady(() {
          rootNavigatorKey.currentContext!.goToOrderDetailById(orderId);
        });
      }
    }
  }

  /// Defers navigation until the navigator is mounted, retrying up to 10×.
  static void _pushWhenReady(VoidCallback navigate, [int attempt = 0]) {
    if (rootNavigatorKey.currentContext != null) {
      navigate();
      return;
    }
    if (attempt >= 10) return;
    Future.delayed(const Duration(milliseconds: 200), () {
      _pushWhenReady(navigate, attempt + 1);
    });
  }

  /// Permission
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission();
    if (kDebugMode == true) {
      debugPrint("Permission: ${settings.authorizationStatus}");
    }
  }

  /// Get FCM token
  static Future<String?> _getToken() async {
    final token = await _messaging.getToken();
    if (kDebugMode == true) debugPrint("FCM Token: $token");
    return token;
  }

  /// Firebase Installation ID
  static Future<String?> getInstallationId() async {
    try {
      final id = await FirebaseInstallations.instance.getId();
      if (kDebugMode == true) debugPrint("Installation ID: $id");
      return id;
    } catch (e) {
      if (kDebugMode == true) debugPrint("Installation ID error: $e");
      return null;
    }
  }

  /// Token refresh
  static void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode == true) debugPrint("Token refreshed");
      await updateUserToken(newToken);
    });
  }

  /// Foreground notification
  static void _foregroundListener() {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode == true) debugPrint("Foreground message received");
      _showLocalNotification(message);
    });
  }

  /// Update token for CURRENT user only
  static Future<void> updateUserToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await AppConfig.firestore
        .collection(Collections.users).doc(uid).update({
      'fcmToken': token,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Show local notification with payload data for navigation
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;

    final notification = message.notification;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: NotificationChannels.fcm,
        title: notification?.title ?? data['title'],
        body: notification?.body ?? data['body'],
        icon: AppConfig.launcherIconResource,
        payload: data.map((k, v) => MapEntry(k, v.toString())),
        notificationLayout: data['image'] != null ? NotificationLayout.BigPicture : NotificationLayout.Default,
        bigPicture: data['image'],
        largeIcon: data['image'],
      ),
    );
  }

  static Future<void> saveUserTokenToFireStore(String userId) async {
    try {
      final token = await _getToken();

      if (token != null && token.isNotEmpty && userId.isNotEmpty) {
        await AppConfig.firestore
            .collection(Collections.users).doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'plateform': Platform.operatingSystem,
        }, SetOptions(merge: true));

        if (kDebugMode) {
          debugPrint("Token saved for user: $userId");
        }
      }
    } catch (e) {
      if (kDebugMode == true) debugPrint("Save token error for user: $e");
    }
  }
}
