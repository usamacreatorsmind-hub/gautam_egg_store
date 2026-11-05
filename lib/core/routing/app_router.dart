import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sure_wholesaler/IntroductionScreen/onboarding_screen.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/data_push/data_push_screen.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/features/business_kyc/screens/business_kyc_stepper_screen.dart';
import 'package:sure_wholesaler/features/business_kyc/screens/kyc_status_screen.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/order_summary_args.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/screens/addresses/address_screen.dart';
import 'package:sure_wholesaler/screens/auth/OTP_Verification_Screen.dart';
import 'package:sure_wholesaler/screens/auth/UserScreen.dart';
import 'package:sure_wholesaler/screens/auth/login_screen.dart';
import 'package:sure_wholesaler/screens/cart/Cart_Screen.dart';
import 'package:sure_wholesaler/screens/cart/checkout_screen.dart';
import 'package:sure_wholesaler/screens/cart/order_summary_screen.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';
import 'package:sure_wholesaler/screens/cart/schedule_screen.dart';
import 'package:sure_wholesaler/screens/categories/ItemStoryScreen.dart';
import 'package:sure_wholesaler/screens/categories/brands_screen.dart';
import 'package:sure_wholesaler/screens/categories/category_items.dart';
import 'package:sure_wholesaler/screens/categories/category_screen.dart';
import 'package:sure_wholesaler/screens/favorite_products/favorite_products.dart';
import 'package:sure_wholesaler/screens/home/new_products_sliver.dart';
import 'package:sure_wholesaler/screens/navigation/NavigationButton.dart';
import 'package:sure_wholesaler/screens/notifications/notification.dart';
import 'package:sure_wholesaler/screens/offer/Offer_Screen.dart';
import 'package:sure_wholesaler/screens/orders/Order_Screen.dart';
import 'package:sure_wholesaler/screens/orders/order_detail_by_id_screen.dart';
import 'package:sure_wholesaler/screens/orders/order_detail_screen.dart';
import 'package:sure_wholesaler/screens/product/product_details_screen.dart';
import 'package:sure_wholesaler/screens/profile/Edit_Profile_Screen.dart';
import 'package:sure_wholesaler/screens/profile/HelpAndSupportScreen.dart';
import 'package:sure_wholesaler/screens/profile/PrivacyPolicyScreen.dart';
import 'package:sure_wholesaler/screens/profile/Profile_Screen.dart';
import 'package:sure_wholesaler/screens/profile/terms_and_conditions.dart';
import 'package:sure_wholesaler/screens/quick/quickDelivery.dart';
import 'package:sure_wholesaler/screens/scheduled/scheduled_screen.dart';
import 'package:sure_wholesaler/screens/stock_alert/stock_alert.dart';
import 'package:sure_wholesaler/widgets/Search_Icon_Widget.dart';
import 'package:sure_wholesaler/widgets/components.dart';
import 'package:sure_wholesaler/widgets/select_address_on_map.dart';

/// Global navigator key accessible for notification navigation
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router configuration using go_router
class AppRouter {
  AppRouter._();

  /// Check if user is authenticated
  static bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Cached profile existence — null means unchecked this session.
  static bool? _profileExists;

  /// Cached onboarding-seen flag — null means not yet read from prefs.
  static bool? _onboardingSeen;

  static const _onboardingKey = 'onboarding_seen';

  static Future<bool> hasSeenOnboarding() async {
    _onboardingSeen ??= (await SharedPreferences.getInstance()).getBool(_onboardingKey) ?? false;
    return _onboardingSeen!;
  }

  static Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    (await SharedPreferences.getInstance()).setBool(_onboardingKey, true);
  }

  /// Call after the user creates their profile so we skip the Firestore
  /// check on the next home navigation.
  static void markProfileCreated() => _profileExists = true;

  /// Clear when the user signs out so the next login re-checks.
  static void clearProfileCache() => _profileExists = null;

  /// GoRouter configuration
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

    // Redirect logic for onboarding → authentication → profile creation
    redirect: (BuildContext context, GoRouterState state) async {
      final bool loggedIn = isAuthenticated;

      final bool onOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final bool onAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.otpVerification ||
          state.matchedLocation == AppRoutes.userSetup ||
          state.matchedLocation == AppRoutes.privacyPolicy ||
          state.matchedLocation == AppRoutes.helpSupport;

      // If NOT logged in and NOT on an auth page and NOT on onboarding, force redirect to login!
      if (!loggedIn && !onAuthPage && !onOnboarding) {
        if (!await hasSeenOnboarding()) return AppRoutes.onboarding;
        return AppRoutes.login;
      }

      // Already on onboarding — stay
      if (onOnboarding) return null;

      // Not logged in on an auth page — stay
      if (!loggedIn && onAuthPage) return null;

      // Logged in on login page → go home
      if (loggedIn && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.home;
      }

      // Logged in on any app page → check profile once per session
      if (loggedIn && !onAuthPage) {
        _profileExists ??= await checkUserProfileExists();
        if (_profileExists == false) return AppRoutes.userSetup;
      }

      return null;
    },

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown error'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: AppButton(
                text: 'Go Home',
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
            )

            // ElevatedButton(
            //   onPressed: () => context.go(AppRoutes.home),
            //   child: const Text('Go Home'),
            // ),
          ],
        ),
      ),
    ),

    routes: [
      // ===== ONBOARDING =====
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ===== AUTH ROUTES =====
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.otpVerification,
        name: RouteNames.otpVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OTPVerificationScreen(
            mobileNumber: extra?['mobileNumber'] ?? '',
            verificationId: extra?['verificationId'] ?? '',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.userSetup,
        name: RouteNames.userSetup,
        builder: (context, state) {
          final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
          final mobileNumber = phone.startsWith(AppConfig.phonePrefix) ? phone.substring(AppConfig.phonePrefix.length) : phone;
          return UserScreen(mobileNumber: mobileNumber);
        },
      ),

      // ===== MAIN APP ROUTES =====
      // Main navigation shell (bottom nav bar)
      GoRoute(
        path: AppRoutes.home,
        name: RouteNames.home,
        builder: (context, state) => const NavigationButton(),
      ),

      // GoRoute(
      //   path: AppRoutes.mySubscriptions,
      //   name: RouteNames.mySubscriptions,
      //   builder: (context, state) => const SubscriptionManagementScreen(),
      // ),

      // ===== STANDALONE ROUTES =====

      GoRoute(
        path: AppRoutes.cart,
        name: RouteNames.cart,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: CartScreen(
            // Subscription cart route disabled.
            subscriptionOnly: false,
          ),
          fullscreenDialog: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: AppRoutes.offers,
        name: RouteNames.offers,
        builder: (context, state) => const OfferScreen(),
      ),

      GoRoute(
        path: AppRoutes.search,
        name: RouteNames.search,
        builder: (context, state) => const SearchIconWidget(),
      ),

      GoRoute(
        path: AppRoutes.productDetails,
        name: RouteNames.productDetails,
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return ProductDetails(product: product);
        },
      ),

      GoRoute(
        path: AppRoutes.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: RouteNames.editProfile,
            builder: (context, state) => const EditProfileFormWidget(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.orders,
        name: RouteNames.orders,
        builder: (context, state) => const OrderScreen(),
      ),

      GoRoute(
        path: AppRoutes.itemStory,
        name: RouteNames.itemStory,
        builder: (context, state) {
          final docId = state.pathParameters['docId']!;
          return ItemStoryScreen(docId: docId);
        },
      ),
      // help support  and privacy policy
      GoRoute(path: AppRoutes.privacyPolicy, name: RouteNames.privacyPolicy, builder: (context, state) => Privacypolicyscreen()),

      GoRoute(path: AppRoutes.helpSupport, name: RouteNames.helpSupport, builder: (context, state) => HelpAndSupportScreen()),

      GoRoute(
        path: AppRoutes.category,
        name: RouteNames.category,
        builder: (context, state) {
          return CategoryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.brandScreen,
        name: RouteNames.brandScreen,
        builder: (context, state) {
          return BrandsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.notificationScreen,
        name: RouteNames.notificationScreen,
        builder: (context, state) {
          return NotificationScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutScreen,
        name: RouteNames.checkoutScreen,
        builder: (context, state) {
          final products = state.extra as List<ProductModel>? ?? [];
          final warehouseId = state.uri.queryParameters['warehouseId'];
          final deliveryTypeName = state.uri.queryParameters['deliveryType'] ?? 'quick';
          final deliveryType = DeliveryType.values.firstWhere(
            (type) => type.name == deliveryTypeName,
            orElse: () => DeliveryType.quick,
          );
          return CheckoutScreen(
            products: products,
            warehouseId: warehouseId,
            deliveryType: deliveryType,
            // Subscription checkout flow disabled.
            isSubscription: false,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderSummaryScreen,
        name: RouteNames.orderSummaryScreen,
        builder: (context, state) {
          final args = state.extra as OrderSummaryArgs;

          return OrderSummaryScreen(
            orderSummaryArgs: args,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderDetailScreen,
        name: RouteNames.orderDetailScreen,
        builder: (context, state) {
          final args = state.extra as OrderModel;

          return OrderDetailScreen(
            order: args,
          );
        },
      ),

      // Order detail by ID (used by notification tap navigation)
      GoRoute(
        path: AppRoutes.orderDetailById,
        name: RouteNames.orderDetailById,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailByIdScreen(orderId: orderId);
        },
      ),

      GoRoute(
        path: AppRoutes.addressOnMap,
        name: RouteNames.addressOnMap,
        builder: (context, state) {
          return SelectAddressOnMapScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.stockAlertScreen,
        name: RouteNames.stockAlertScreen,
        builder: (context, state) {
          return const StockAlertScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.favoriteProducts,
        name: RouteNames.favoriteProducts,
        builder: (context, state) {
          return const FavoriteProductsScreen();
        },
      ),

      GoRoute(
        path: AppRoutes.categoryItems,
        name: RouteNames.categoryItems,
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final extra = state.extra;

          // Handle both old format (String) and new format (Map)
          if (extra is Map<String, dynamic>) {
            return CategoryItems(
              categoryId: categoryId,
              categoryName: extra['categoryName'] as String? ?? 'Products',
              subcategoryId: extra['subcategoryId'] as String?,
              brandId: extra['brandId'] as String?,
              brandName: extra['brandName'] as String?,
              initialSortBy: extra['sortBy'] as String?,
              initialMinDiscount: extra['minDiscount'] as int?,
              initialInStock: extra['inStock'] as bool?,
              initialExpressDelivery: extra['expressOnly'] as bool?,
              initialPriceRange: extra['priceRange'] as RangeValues?,
            );
          }

          // Legacy support: extra is just the category name
          return CategoryItems(
            categoryId: categoryId,
            categoryName: extra as String? ?? 'Products',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.termsAndConditions,
        name: RouteNames.termsAndConditions,
        builder: (context, state) => const TermsAndConditions(),
      ),
      GoRoute(
        path: AppRoutes.quickDelivery,
        name: RouteNames.quickDelivery,
        builder: (context, state) => const QuickdeliveryScreen(),
      ),

      // GoRoute(
      //   path: AppRoutes.subscribe,
      //   name: RouteNames.subscribe,
      //   builder: (context, state) => const SubscriptionScreen(),
      // ),

      GoRoute(
        path: AppRoutes.scheduledScreen,
        name: RouteNames.scheduledScreen,
        builder: (context, state) => const ScheduledScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectRepeatSchedule, // New route for ScheduleScreen
        name: RouteNames.selectRepeatSchedule,
        builder: (context, state) {
          final initialSchedule = state.extra as RepeatSchedule?;
          return ScheduleScreen(initial: initialSchedule);
        },
      ),

      GoRoute(
        path: AppRoutes.address,
        name: RouteNames.address,
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.dataPush,
        builder: (context, state) => const DataPushScreen(),
      ),
    ],
  );

  /// Returns true only when the user has a Firestore document with
  /// isProfileCreated == true and all required fields populated.
  static Future<bool> checkUserProfileExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await AppConfig.firestore
          .collection(Collections.users).doc(user.uid).get().timeout(const Duration(seconds: 3));

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final isProfileCreated = data['isProfileCreated'] as bool? ?? false;
      // Updated to check new project field names
      final userName = (data['displayName'] as String? ?? data['userName'] as String? ?? '').trim();
      final mobileNo = (data['phoneNumber'] as String? ?? data['mobileNo'] as String? ?? '').trim();

      return isProfileCreated && userName.isNotEmpty && mobileNo.isNotEmpty;
    } catch (e) {
      debugPrint('Error or timeout checking user profile: $e');
      return true;
    }
  }

  /// Navigate after OTP verification
  /// Returns the route to navigate to based on user profile status
  static Future<String> getPostAuthRoute() async {
    _profileExists = await checkUserProfileExists();
    return _profileExists! ? AppRoutes.home : AppRoutes.userSetup;
  }
}

/// Extension on BuildContext for easier navigation
extension GoRouterExtension on BuildContext {
  /// Navigate to cart screen
  void goToCart() => push(AppRoutes.cart);

  /// Navigate to product details
  void goToProductDetails(ProductModel product) => push(
        AppRoutes.productDetailsPath(product.id ?? 'unknown'),
        extra: product,
      );

  /// Navigate to profile
  void goToProfile() => push(AppRoutes.profile);

  /// Navigate to edit profile
  void goToEditProfile() => push('${AppRoutes.profile}/edit');

  /// Navigate to search
  void goToSearch() => push(AppRoutes.search);

  /// Navigate to stock alerts
  void goToStockAlerts() => push(AppRoutes.stockAlertScreen);

  /// Navigate to order detail by ID — used by notification tap
  void goToOrderDetailById(String orderId) => pushNamed(
        RouteNames.orderDetailById,
        pathParameters: {'orderId': orderId},
      );

  /// Navigate to login (clears stack)
  void goToLogin() => go(AppRoutes.login);

  /// Navigate to home (clears stack)
  void goToHome() => go(AppRoutes.home);

  /// Navigate after successful OTP verification
  Future<void> navigateAfterAuth() async {
    final route = await AppRouter.getPostAuthRoute();
    go(route);
  }
}

/// Helper class to refresh GoRouter when Firebase Auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
