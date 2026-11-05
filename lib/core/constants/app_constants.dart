import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'asset_constants.dart';

export 'app_colors.dart';

// =============================================================
// APP CONSTANTS  —  Single source of truth for all client config
//
// CLONING CHECKLIST (change only these files for a new client):
//   1. AppConfig below          ← app name, bundle ID, phone/currency, support
//   2. AppColors.brandSeed      ← brand color  (app_colors.dart)
//   3. AssetConstants           ← logo + illustrations  (asset_constants.dart)
//   4. pubspec.yaml             ← package name, version, app description
//   5. .env  (or .env.local)    ← Firebase project credentials
//   Everything else reads from these five locations.
// =============================================================

// -------------------------------------------------------------
// CLIENT CONFIG  ← change these for each client/white-label
// -------------------------------------------------------------
class AppConfig {
  /// Display name shown in the app bar, splash, login, etc.
  static const String appName = 'Gautam Egg Store';

  /// Short tagline shown below the logo on auth screens
  static const String tagline = 'Big Savings. Bigger Supply.';

  /// App description (used in pubspec / store listings)
  static const String description = 'A premium wholesale e-commerce app for bulk supply.';

  /// Android package name / iOS bundle ID
  static const String bundleId = 'com.app.gautam_egg_store';

  /// Semantic version shown in the About / upgrade prompt
  static const String appVersion = '1.0.0';

  /// Country phone prefix shown on the OTP/login screen
  static const String phonePrefix = '+91';

  /// Firestore database ID
  static const String databaseId = 'admineggstore';

  /// Centralized FirebaseFirestore instance for databaseId
  static FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: databaseId,
      );

  /// Currency symbol used across the app — also see formatPrice() below
  static const String currencySymbol = '₹';

  /// Firestore collection prefix — ALL surewholesaler_* collections are composed from this.
  /// Change to e.g. 'freshmart_' and every collection name updates automatically.
  static const String collectionPrefix = '';

  /// Company / support contact
  static const String supportEmail = 'gautameggstore@gmail.com';
  static const String supportPhone = '+916205358681';
  static const String legalCompanyName = 'Gautam Egg Store';
  static const String splashSubtitle = ' Big Savings. Bigger Supply.';
  static const String launcherIconResource = 'resource://mipmap/ic_launcher';
  static const String businessAddress = 'Bagmali Sanchi patti Hajijpur , Vaishali , Bihar 844123';

  // ignore: non_constant_identifier_names
  static var RAZ_KEY = "rzp_test_ebaOKw4xjzfhCR";

  /// Hard Fix for 100x issue:
  /// The database stores prices in Paisa (subunits).
  /// We always divide by 100 to get the Rupee value.
  static double getCleanPrice(num amount) {
    return amount.toDouble() / 100;
  }

  /// Format a price value with the client's currency symbol.
  static String formatPrice(num amount, {int decimals = 2}) {
    double value = getCleanPrice(amount);

    final formatter = intl.NumberFormat.decimalPattern('en_IN');
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;

    return '$currencySymbol ${formatter.format(value)}';
  }

  static String formatPriceWithLabel(String label, num amount, {int decimals = 2}) => '$label ${formatPrice(amount, decimals: decimals)}';

  static String privacyPolicyUrl = 'https://privacy.ezyknotcareers.com/vkart-app-privacy-policy/';
  static String termsOfServiceUrl = 'https://privacy.ezyknotcareers.com/vkart-app-terms-and-conditions/';
  static String disclaimerUrl = 'https://privacy.ezyknotcareers.com/vkart-app-disclaimer/';
}

// -------------------------------------------------------------
// API ENDPOINTS
// -------------------------------------------------------------

// -------------------------------------------------------------
// NOTIFICATION CHANNELS  (AwesomeNotifications keys)
// -------------------------------------------------------------
class NotificationChannels {
  static const String basic = 'basic_channel';
  static const String basicName = 'Basic Notifications';
  static const String basicDescription = 'General notifications';
  static const String scheduled = 'scheduled_channel';
  static const String scheduledName = 'Scheduled Notifications';
  static const String scheduledDescription = 'Scheduled reminders';
  static const String fcm = 'fcm_channel';
  static const String fcmName = 'FCM Notifications';
  static const String fcmDescription = 'Firebase Cloud Messaging';
}

// -------------------------------------------------------------
// FIRESTORE COLLECTIONS
// All names are built from AppConfig.collectionPrefix so that
// changing the prefix once renames every collection.
// Exception: 'brands' is a shared global collection (no prefix).
// -------------------------------------------------------------
class AppCollections {
  static const String _p = AppConfig.collectionPrefix;
  static String productCampaign = '${_p}product_campaigns';

  static const String admin = '${_p}admin';
  static const String users = '${_p}users';
  static const String products = '${_p}products';
  static const String variants = '${_p}variants';
  static const String inventories = '${_p}inventory';
  static const String warehouses = '${_p}stores';
  static const String orders = '${_p}orders';
  static const String cart = '${_p}carts';
  static const String categories = '${_p}categories';
  static const String brands = 'brands'; // shared / unnamespaced
  static const String sliders = '${_p}sliders';
  static const String addresses = '${_p}addresses';
  static const String notifications = '${_p}broadcastNotifications';
  static const String coupon = '${_p}coupons';
  static const String couponUsages = '${_p}coupon_usages';
  static const String stockAlerts = '${_p}stock_alerts';
  static const String favorites = '${_p}fevorites'; // Firestore name kept as-is
  static const String subscriptions = '${_p}subscriptions';
  static const String flashSales = '${_p}flash_sales';
  static const String creditConfig = '${_p}credit_config';
  static const String creditPackages = '${_p}credit_packages';
  static const String productReviews = '${_p}product_reviews';
  static const String searchLogs = '${_p}search_logs';
  static const String popularSearches = '${_p}popular_searches';
  static const String settings = '${_p}settings';

  static String get businessKyc => '${_p}business_kyc';

  static String get credentials => '${_p}credentials';
}

// -------------------------------------------------------------
// UI / LAYOUT
// -------------------------------------------------------------
class AppDimensions {
  /// Base design canvas fed to flutter_screenutil
  static const Size designSize = Size(392, 850);
  static const Size desktopDesignSize = Size(1440, 900);

  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;

  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
}

// -------------------------------------------------------------
// STRINGS — UI copy that varies per client
// -------------------------------------------------------------
class AppStrings {
  // Section headers

  static const String featuredBrands = 'Featured Brands';
  static const String newArrivals = 'New Arrivals';

  // Category page labels
  static const String brandsLabel = 'Brands';
  static const String brandsSubtitle = 'Popular brands';
  static const String categoriesLabel = 'Categories';
  static const String categoriesSubtitle = 'Product categories';
  static const String highMarginLabel = 'High Margin Store';
  static const String highMarginSubtitle = 'Premium products';
  static const String regionalBrandsLabel = 'Regional Brands Store';
  static const String regionalBrandsSubtitle = 'Local specialties';

  // Auth screen
  static const String otpSentMessage = 'We have sent a verification code to your mobile number.';
  static const String loginButtonLabel = 'Login';
  static const String verifyButtonLabel = 'Verify OTP';
  static const String resendOtpLabel = 'Resend OTP';

  // Orders
  static const String orderPlaced = 'Order Placed';
  static const String orderAccepted = 'Accepted';
  static const String orderRiderAssigned = 'Rider Assigned';
  static const String orderOutForDelivery = 'Out for Delivery';
  static const String orderDelivered = 'Delivered';
  static const String orderCancelled = 'Cancelled';
  static const String orderDelayed = 'Delayed';

  // Generic
  static const String loading = 'Loading…';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String noData = 'Nothing here yet.';
}

class FirestoreFields {
  static const String notificationPreferences = 'notificationPreferences';
  static const String productId = 'productId';
  static const String addedAt = 'addedAt';
  static const String status = 'status';
}

class IntroductionScreenConstants {
  static const String img1 = AssetConstants.illuFreshGroceries;
  static const String page1Title = " Wholesale Supplies\nDelivered";
  static const String page1Body = "High-quality wholesale goods and business essentials delivered straight to your location.";

  static const String page2Title = "Fast & Reliable\nDelivery";
  static const String page2Body = "Quick delivery from nearby warehouses with live order tracking and instant updates.";

  static const String img2 = AssetConstants.illuDelivery;

  static const String page3Title = "Save More\nEvery Day";
  static const String page3Body = "Exclusive bulk offers, business savings, rewards and unbeatable wholesale deals.";

  static const String img3 = AssetConstants.illuSavings;
}
