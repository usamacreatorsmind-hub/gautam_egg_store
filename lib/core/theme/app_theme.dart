import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';

/// =======================================================
/// APP THEME (Production Ready • Material 3 • Clean)
/// =======================================================
/// Rules:
/// - No hardcoded text colors
/// - Only ColorScheme used
/// - One builder for both themes
/// - Consistent light/dark
/// =======================================================

class AppTheme {
  /// Brand seed color — sourced from AppColors for single-point client config
  static const Color seed = AppColors.brandSeed; // vivid orange

  /// -------------------------------------------------------
  /// Public themes
  /// -------------------------------------------------------
  static ThemeData lightTheme = _buildTheme(Brightness.light);
  static ThemeData darkTheme = _buildTheme(Brightness.dark);

  /// -------------------------------------------------------
  /// Single theme builder (BEST PRACTICE)
  /// -------------------------------------------------------
  static ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: AppColors.brandSeed,
      secondary: AppColors.brand100,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      /// ===============================
      /// SCAFFOLD
      /// ===============================
      scaffoldBackgroundColor: AppColors.background,

      /// ===============================
      /// TEXT (NO COLORS HERE)
      /// ===============================
      textTheme: AppTextTheme.base,

      /// ===============================
      /// APP BAR
      /// ===============================
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: RoundedRectangleBorder(
          // side: BorderSide(
          //   color: scheme.outlineVariant,
          //   width: 0,
          // ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
        actionsIconTheme: IconThemeData(color: scheme.onPrimary),
      ),

      /// ===============================
      /// CHIPS
      /// ===============================
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(fontSize: 13, color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      /// ===============================
      /// BUTTONS
      /// ===============================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // snack bar theme

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),

      /// ===============================
      /// CARDS
      /// ===============================
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      /// ===============================
      /// INPUT FIELDS
      /// ===============================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 2,
          ),
        ),
      ),

      /// ===============================
      /// NAVIGATION
      /// ===============================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.primary,
        selectedItemColor: scheme.onPrimary,
        unselectedItemColor: scheme.onPrimary.withOpacity(.6),
        type: BottomNavigationBarType.fixed,
      ),

      /// ===============================
      /// SNACKBAR
      /// ===============================
      // snackBarTheme: SnackBarThemeData(
      //   backgroundColor: scheme.inverseSurface,
      //   contentTextStyle: TextStyle(
      //     color: scheme.onInverseSurface,
      //   ),
      //   behavior: SnackBarBehavior.floating,
      // ),

      /// ===============================
      /// DIALOGS
      /// ===============================
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      /// ===============================
      /// DIVIDER
      /// ===============================
      dividerColor: scheme.outlineVariant,

      /// 🔥 GLOBAL SNACKBAR THEME
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surface,
        dismissDirection: DismissDirection.horizontal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: scheme.primary,
      ),
    );
  }

  /// -------------------------------------------------------
  /// ORDER STATUS COLORS — delegated to AppColors
  /// -------------------------------------------------------
  static Map<String, Color> get orderStatusColor => AppColors.orderStatusColor;
}

/// =======================================================
/// TEXT THEME (TYPOGRAPHY ONLY • NO COLORS)
/// =======================================================
class AppTextTheme {
  static const TextTheme base = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12),
  );
}
