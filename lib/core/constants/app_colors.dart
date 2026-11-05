import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color brandSeed = Color(0xFFFB9902);
  static const Color brand100 = Color(0xFF531A05);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF166534);

  static const Color warning = Color(0xFFEA580C);
  static const Color warningBg = Color(0xFFFFF7ED);
  static const Color warningDark = Color(0xFF7C2D12);

  static const Color error = Color(0xFFDC2626);

  static const Color info = Color(0xFF2563EB);
  static const Color infoBright = Color(0xFF1D4ED8);
  static const Color infoLight = Color(0xFFE0E7FF);
  static const Color infoDark = Color(0xFF1E3A8A);

  static const Color accentPurple = Color(0xFF9333EA);

  // Surface
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFBBDEFB);

  // Text
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textDisabled = Color(0xFFA8A29E);
  static const Color textHint = Color(0xFF78716C);
  static const Color onBrand = Color(0xFFFFFFFF);

  // Commerce
  static const Color price = Color(0xFF16A34A);
  static const Color priceStrikethrough = textHint;
  static const Color discount = Color(0xFFDC2626);
  static const Color badge = brandSeed;
  static const Color badgeText = Color(0xFFFFFFFF);

  // Grey scale (use these instead of Colors.grey.shade*)
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);

  // Surface backgrounds
  static const Color surfaceSecondary = Color(0xFFF2F3F7);

  // Misc
  static const Color transparentColor = Colors.transparent;
  static const Color colorBlack = Colors.black;
  static const Color shimmerBase = Color(0xFFBBDEFB);

  // Star / rating
  static const Color starColor = Color(0xFFFFC107); // amber

  // Map / location pin
  static const Color locationPin = Color(0xFFFF5252); // redAccent

  // Error gradient (used in out-of-stock / critical banners)
  static const Color errorDeep = Color(0xFFB71C1C);
  static const Color errorLight = Color(0xFFE53935);

  // Order status
  static const Color statusPlaced = textHint;
  static const Color statusAccepted = brandSeed;
  static const Color statusRiderAssigned = accentPurple;
  static const Color statusOutForDelivery = info;
  static const Color statusDelivered = success;
  static const Color statusCancelled = error;
  static const Color statusDelayed = Color(0xFF42A5F5);

  static const Map<String, Color> orderStatusColor = {
    'placed': statusPlaced,
    'accepted': statusAccepted,
    'riderAssigned': statusRiderAssigned,
    'outForDelivery': statusOutForDelivery,
    'delivered': statusDelivered,
    'cancelled': statusCancelled,
    'delayed': statusDelayed,
  };
}
