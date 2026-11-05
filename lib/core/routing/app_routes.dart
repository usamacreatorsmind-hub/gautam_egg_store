/// Route path constants for the application
/// Using abstract class to prevent instantiation
abstract class AppRoutes {
  // Splash
  static const String splash = '/splash';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Auth routes
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String userSetup = '/user-setup';

  // Main app routes (shell routes)
  static const String home = '/';
  static const String orders = '/orders';
  static const String offers = '/offers';
  static const String profile = '/profile';

  // Nested routes
  static const String cart = '/cart';
  static const String search = '/search';
  static const String category = '/category';
  static const String quickDelivery = '/quick-delivery';
  static const String subscribe = '/subscribe';
  static const String scheduledScreen = '/scheduled';
  static const String selectRepeatSchedule = '/select-repeat-schedule';
  static const String allCategories = '/all-categories';

  static const String productDetails = '/product/:productId';
  static const String editProfile = '/profile/edit';

  // Helper method to generate product details route with ID
  static String productDetailsPath(String productId) => '/product/$productId';

  // Helper method to generate category items route with ID
  static String categoryItemsPath(String categoryId) =>
      '/category-items/$categoryId';

  static const String itemStory = '/item-story/:docId';
  static const String categoryItems = '/category-items/:categoryId';
  static const String checkoutScreen = '/checkout-screen';
  static const String orderSummaryScreen = '/order-summary-screen';
  static const String orderDetailScreen = '/order-detail-screen';
  static const String orderDetailById = '/order-detail/:orderId';
  static const String brandScreen = '/brand-screen';
  static const String notificationScreen = '/notification-screen';
  static const String stockAlertScreen = '/stock-alerts';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String helpSupport = '/help-support';

  static String address = '/address';

  static String walletHomeScreen = '/wallet-home-screen';
  static String walletTransectionScreen = '/wallet-transections';
  static String walletCredit = '/wallet-credit';
  static String addressOnMap = '/address-on-map';
  static String favoriteProducts = '/favorite-products';
  static const String mySubscriptions = '/my-subscriptions';
  static const String subscriptionDetail = '/subscription-detail/:subscriptionId';
  static const String swiggyStyle = '/swiggy-style';
  static const String dataPush = '/data-push';

  //address';

  // Helper method to generate order detail by ID route
  static String orderDetailByIdPath(String orderId) => '/order-detail/$orderId';

  /// Helper method to generate subscription detail path
  static String subscriptionDetailPath(String subId) => '/subscription-detail/$subId';
}

/// Route names for named navigation (optional, for clarity)
abstract class RouteNames {
  static const String login = 'login';
  static const String otpVerification = 'otpVerification';
  static const String userSetup = 'userSetup';
  static const String home = 'home';
  static const String orders = 'orders';
  static const String offers = 'offers';
  static const String profile = 'profile';
  static const String favoriteProducts = 'favoriteProducts';
  static const String cart = 'cart';
  static const String search = 'search';
  static const String allCategories = 'allCategories';
  static const String productDetails = 'productDetails';
  static const String editProfile = 'editProfile';
  static const String itemStory = 'itemStory';
  static const String category = 'category';
  static const String categoryItems = 'categoryItems';
  static const String checkoutScreen = 'checkoutScreen';
  static const String orderSummaryScreen = 'orderSummaryScreen';
  static const String orderDetailScreen = 'orderDetailScreen';
  static const String orderDetailsScreen = 'orderDetailScreen';
  static const String orderDetailById = 'orderDetailById';
  static const String privacyPolicy = 'privacyPolicy';
  static const String termsAndConditions = 'termsAndConditions';
  static const String helpSupport = 'helpSupport';

  static const String brandScreen = "brand";
  static const String notificationScreen = "notificationScreen";
  static const String stockAlertScreen = "stockAlertScreen";
  static const String quickDelivery = 'quickDelivery';
  static const String subscribe = 'subscribe';
  static const String scheduledScreen = 'scheduledScreen';
  static const String selectRepeatSchedule = 'selectRepeatSchedule';
  static const String address = 'address';
  static const String walletHomeScreen = 'walletHomeScreen';
  static const String walletCredit = 'walletCreditScreen';
  static const String walletTransectionScreen = 'walletTransectionScreen';
  static const String addressOnMap = 'addressOnMap';
  static const String mySubscriptions = 'mySubscriptions';
  static const String subscriptionDetail = 'subscriptionDetail';
}