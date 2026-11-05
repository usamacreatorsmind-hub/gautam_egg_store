import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/core/services/inapp_messaging_service.dart';
import 'package:sure_wholesaler/core/services/notification_service.dart';
import 'package:sure_wholesaler/core/theme/app_theme.dart';
import 'package:sure_wholesaler/firebase_options.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_permissions.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      channelKey: NotificationChannels.fcm,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      icon: AppConfig.launcherIconResource,
      notificationLayout: NotificationLayout.Default,
      payload: message.data.map((k, v) => MapEntry(k, v.toString())),
    ),
  );
}


void main() {
  runZonedGuarded(_bootstrap, (error, stack) {
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all Flutter framework errors (widget build, layout, etc.)
  FlutterError.onError = (details) {
    debugPrint('═══ FlutterError ═══\n${details.exceptionAsString()}\n${details.stack}');
  };

  // Catch asynchronous errors not caught by the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('═══ PlatformDispatcher Error ═══\n$error\n$stack');
    return true;
  };

  // Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Notifications — channels only; permission is requested after runApp
  try {
    await AwesomeNotifications().initialize(
      AppConfig.launcherIconResource,
      [
        NotificationChannel(
          channelKey: NotificationChannels.basic,
          channelName: NotificationChannels.basicName,
          channelDescription: NotificationChannels.basicDescription,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: NotificationChannels.scheduled,
          channelName: NotificationChannels.scheduledName,
          channelDescription: NotificationChannels.scheduledDescription,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: NotificationChannels.fcm,
          channelName: NotificationChannels.fcmName,
          channelDescription: NotificationChannels.fcmDescription,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
        ),
      ],
      debug: kDebugMode,
    );
  } catch (e) {
    debugPrint("AwesomeNotifications init error: $e");
  }

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await NotificationService.init();
  } catch (e) {
    debugPrint("NotificationService init error: $e");
  }

  try {
    await InAppMessagingService.init();
  } catch (e) {
    debugPrint("InAppMessaging init error: $e");
  }

  runApp(SafeArea(top: false, child: ProviderScope(child: MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Request notification and location permissions now that the UI context exists
    _requestInitialPermissions();

    // Set up AwesomeNotifications tap listener (foreground + background)
    NotificationService.setupActionListeners();

    // Listen for background-to-foreground notification taps via FCM
    NotificationService.setupBackgroundTapListener();

    // Check if app was opened from a terminated-state notification
    // Delay to ensure the router is fully initialized
    Future.delayed(const Duration(seconds: 1), () {
      NotificationService.handleTerminatedState();
    });
  }

  Future<void> _requestInitialPermissions() async {
    // 1. Notification Permission
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // 2. Location Permission (Request after notification or in parallel)
    // We add a small delay to avoid multiple dialogs appearing at the exact same millisecond
    await Future.delayed(const Duration(milliseconds: 500));
    await LocationPermissions.ensurePermission();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppDimensions.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,

        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return const Scaffold(
              body: Center(child: Text('Error reloading, please restart the app')),
            );
          };

          // Handle Fatal Runtime Errors
          PlatformDispatcher.instance.onError = (error, stack) {
            debugPrint('═══ PlatformDispatcher Error ═══\n$error\n$stack');
            return true; // Prevent the app from crashing
          };

          // Handle Non-Fatal Flutter Errors
          FlutterError.onError = (FlutterErrorDetails details) {
            debugPrint('═══ FlutterError ═══\n${details.exceptionAsString()}\n${details.stack}');
          };

          return child ?? const SizedBox.shrink();
        },

        // ✅ Also wrap in SafeArea to catch bottom-most crashes (if needed)
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

// Gautam@2026