import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';

class AppNotifications {
  /// Shows a clean, white, full-width notification at the bottom.
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Use root context to prevent crashes during navigation.
    // Fallback to provided context if root is not available.
    final targetContext = rootNavigatorKey.currentContext ?? context;

    // Check if context is still valid/mounted to avoid "popping" errors
    if (!targetContext.mounted) return;

    Flushbar(
      titleText: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      icon: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
        size: 28,
      ),
      mainButton: onButtonPressed != null
          ? TextButton(
              onPressed: () {
                onButtonPressed();
              },
              child: Text(
                buttonLabel ?? "VIEW",
                style: const TextStyle(
                  color: AppColors.brandSeed,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.white,
      flushbarPosition: FlushbarPosition.BOTTOM,
      flushbarStyle: FlushbarStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, -4),
          blurRadius: 12,
        ),
      ],
      duration: duration,
      animationDuration: const Duration(milliseconds: 400),
      // subtle top border for white-on-white distinction
      borderColor: AppColors.grey200,
      borderWidth: 0.5,
    ).show(targetContext);
  }

  /// Shows a clean, white, full-width error notification at the bottom.
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Use root context to prevent crashes during navigation.
    // Fallback to provided context if root is not available.
    final targetContext = rootNavigatorKey.currentContext ?? context;

    // Check if context is still valid/mounted to avoid "popping" errors
    if (!targetContext.mounted) return;

    Flushbar(
      titleText: Text(
        title,
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: AppColors.error,
        size: 28,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.white,
      flushbarPosition: FlushbarPosition.BOTTOM,
      flushbarStyle: FlushbarStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, -4),
          blurRadius: 12,
        ),
      ],
      duration: duration,
      animationDuration: const Duration(milliseconds: 400),
      borderColor: AppColors.grey200,
      borderWidth: 0.5,
    ).show(targetContext);
  }

  /// Alias for the primary notification style.
  static void showPremiumNotification(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    showSuccess(
      context,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onButtonPressed: onButtonPressed,
    );
  }
}
