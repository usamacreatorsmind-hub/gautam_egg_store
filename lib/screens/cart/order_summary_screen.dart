import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/features/invoicePdfService/InvoicePdfService.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/order_summary_args.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/coupon_notifier.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/notifiers/order_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/notifiers/warehouse_notifier.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schedule_card.dart';
import 'package:sure_wholesaler/services/whatsapp_api_service.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/models/app_settings_model.dart';
import 'package:sure_wholesaler/repositories/settings_repository.dart';

import '../../core/routing/app_router.dart';
import '../../utils/location_base_classes/location_utils.dart';

// ─── delivery calculation result ──────────────────────────────────────────────

class _DeliveryCalc {
  final double charge;
  final double distanceKm;
  final String model; // 'Fixed' | 'Distance-based' | 'Base rate' | 'Unknown'
  final double extraKm;

  const _DeliveryCalc({
    required this.charge,
    required this.distanceKm,
    required this.model,
    required this.extraKm,
  });

  static const unknown = _DeliveryCalc(charge: 0, distanceKm: 0, model: 'Unknown', extraKm: 0);
}

// ─── charge computation ────────────────────────────────────────────────────────

class _OrderCharges {
  final double totalMrp;
  final double subtotal;
  final double mrpDiscount;
  final double couponDiscount;
  final double deliveryFee;
  final bool deliveryFree;
  final double platformFee;
  final double packingFee;
  final double extraOrderCharge;
  final double gstAmount;
  final double gatewayFee;
  final double total;

  const _OrderCharges({
    required this.totalMrp,
    required this.subtotal,
    required this.mrpDiscount,
    required this.couponDiscount,
    required this.deliveryFee,
    required this.deliveryFree,
    required this.platformFee,
    required this.packingFee,
    required this.extraOrderCharge,
    required this.gstAmount,
    required this.gatewayFee,
    required this.total,
  });

  static _OrderCharges compute({
    required double totalMrp,
    required double totalSellingPrice,
    required double couponSavings,
    required _DeliveryCalc delivery,
    required DeliveryChargeProfile deliveryConfig,
    required WarehouseTaxConfig taxConfig,
    required String paymentMethod,
    required AppSettingsModel settings,
  }) {
    final mrpDiscount = (totalMrp - totalSellingPrice).clamp(0.0, double.infinity);

    // Logic updated: Disabling automatic free delivery based on global settings.
    // Delivery will now follow Distance Slabs regardless of order value.
    final deliveryFree = (deliveryConfig.freeDeliveryThreshold > 0 && totalSellingPrice >= deliveryConfig.freeDeliveryThreshold);
    final deliveryFee = deliveryFree ? 0.0 : delivery.charge;

    // Subtotal after coupon discount
    final netProductAmount = (totalSellingPrice - couponSavings).clamp(0.0, double.infinity);

    // Platform Fee (linked to admin panel platformCharge, fallback 5)
    final platformFee = settings.platformFee;

    // Packing Fee (linked to admin panel handlingCharge, fallback 5)
    final packingFee = settings.handlingCharge;

    // Extra Order Charge:
    // Dynamic calculation from Settings Surcharges
    double extraOrderCharge = 0.0;
    final sortedSurcharges = List<OrderSurcharge>.from(settings.orderValueSurcharges)
      ..sort((a, b) => b.aboveSubtotal.compareTo(a.aboveSubtotal));

    for (var surcharge in sortedSurcharges) {
      if (totalSellingPrice >= surcharge.aboveSubtotal) {
        extraOrderCharge = surcharge.charge;
        break;
      }
    }

    // Fallback if no surcharges defined in settings
    if (settings.orderValueSurcharges.isEmpty) {
      if (totalSellingPrice > 200000) {
        extraOrderCharge = 2000.0;
      } else if (totalSellingPrice > 100000) {
        extraOrderCharge = 1000.0;
      }
    }

    // GST Amount is removed from calculations/UI
    const gstAmount = 0.0;

    // Intermediate total before gateway fee
    final baseTotal = netProductAmount + deliveryFee + platformFee + packingFee + extraOrderCharge;

    // Gateway fee as percentage of total
    final gatewayFee = paymentMethod != PaymentMethod.cod ? baseTotal * taxConfig.paymentGatewayChargePercentage / 100 : 0.0;

    final total = (baseTotal + gatewayFee).clamp(0.0, double.infinity);

    return _OrderCharges(
      totalMrp: totalMrp,
      subtotal: totalSellingPrice,
      mrpDiscount: mrpDiscount,
      couponDiscount: couponSavings,
      deliveryFee: deliveryFee,
      deliveryFree: deliveryFree,
      platformFee: platformFee,
      packingFee: packingFee,
      extraOrderCharge: extraOrderCharge,
      gstAmount: gstAmount,
      gatewayFee: gatewayFee,
      total: total,
    );
  }
}

// ─── payment options ───────────────────────────────────────────────────────────

class _PaymentOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;

  const _PaymentOption({required this.id, required this.label, required this.subtitle, required this.icon});
}

const _kPaymentMethods = [
  _PaymentOption(
    id: PaymentMethod.cod,
    label: 'Cash on Delivery',
    subtitle: 'Pay when your order arrives',
    icon: Icons.payments_outlined,
  ),
  // Online payment disabled as Razorpay is not yet configured for this project
  /*
  _PaymentOption(
    id: PaymentMethod.online,
    label: 'Online Payment',
    subtitle: 'UPI · Cards · Net Banking',
    icon: Icons.account_balance_wallet_outlined,
  ),
  */
];

// ─── screen ────────────────────────────────────────────────────────────────────

class OrderSummaryScreen extends ConsumerStatefulWidget {
  final OrderSummaryArgs orderSummaryArgs;

  const OrderSummaryScreen({super.key, required this.orderSummaryArgs});

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  bool _isPlacingOrder = false;
  bool _isSubscriptionPayment = false;
  bool _isConfigErrorDialogVisible = false;
  String _selectedPaymentMethod = PaymentMethod.cod;

  OrderModel? _pendingOnlineOrder;
  List<dynamic>? _itemsToClear; // Store items to remove from cart after payment
  final _upiController = TextEditingController();
  final _couponController = TextEditingController();

  // Razorpay disabled as it is not yet configured for this project
  // RazorPayHelper? _razorPay;

  _DeliveryCalc _deliveryCalc = _DeliveryCalc.unknown;
  bool _calculatingDelivery = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDeliveryCharge());
    // Razorpay disabled as it is not yet configured for this project
    /*
    _razorPay = RazorPayHelper(
      onSuccess: (pId, oId, sig) => _handlePaymentSuccess(),
      onError: (err) => _handlePaymentError(err),
      onExternalWallet: (_) {},
    );
    */
  }

  @override
  void dispose() {
    _upiController.dispose();
    _couponController.dispose();
    // _razorPay?.dispose();
    super.dispose();
  }

  /*
  Future<void> _handlePaymentSuccess() async {
    if (!mounted) return;
    final pendingOrder = _pendingOnlineOrder;

    if (pendingOrder?.id != null) {
      try {
        await ref.read(orderRepositoryProvider).updateOrder(
              pendingOrder!.id!,
              pendingOrder.copyWith(paymentStatus: PaymentStatus.paid),
            );
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to update payment status: $e');
      }
    }

    await _performCartCleanup();
    _pendingOnlineOrder = null;
    _clearCartAndNavigate();
  }
  */

  Future<void> _performCartCleanup() async {
    if (_itemsToClear == null) return;
    final cartNotifier = ref.read(cartProvider.notifier);
    for (var item in _itemsToClear!) {
      try {
        await cartNotifier.removeFromCart(item);
      } catch (_) {}
    }
    _itemsToClear = null;
  }

  /*
  void _handlePaymentError(String error) {
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    AppNotifications.showError(
      context,
      title: 'Error',
      message: 'Payment failed: $error',
    );
  }
  */

  void _clearCartAndNavigate() {
    // Clear applied coupon when order is placed successfully
    ref.read(removeCouponProvider)();

    // 1. Navigate to Home immediately
    context.go(AppRoutes.home);

    // 2. Wait for navigation to complete and UI to settle
    Future.delayed(const Duration(milliseconds: 600), () {
      final globalContext = rootNavigatorKey.currentContext;
      if (globalContext != null) {
        AppNotifications.showSuccess(
          globalContext,
          title: 'Success',
          message: 'Order placed successfully!',
        );
      }
    });
  }

  Future<void> _sendOrderBillToWhatsApp(OrderModel order) async {
    if (!WhatsappApiService.isConfigured) {
      if (kDebugMode) {
        debugPrint('WhatsApp bill sending skipped: API not configured.');
      }
      return;
    }

    final customerPhone = order.user.mobileNo.trim();
    if (customerPhone.isEmpty) {
      if (kDebugMode) {
        debugPrint('WhatsApp bill sending skipped: customer phone missing.');
      }
      return;
    }

    try {
      final pdfFile = await OrderBillGenerator.savePdf(order);
      await WhatsappApiService.sendPdfBill(
        customerPhone: customerPhone,
        pdfFile: pdfFile,
        orderNumber: order.orderNumber,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to send order bill on WhatsApp: $e');
      }
    }
  }

  Future<void> _onCouponTap(String code, double cartTotal, List<CouponModel> coupons) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    final applied = ref.read(appliedCouponProvider);
    if (applied?.code.trim().toUpperCase() == cleanCode) {
      ref.read(removeCouponProvider)();
      if (mounted) {
        AppNotifications.showSuccess(
          context,
          title: 'Coupon Removed',
          message: 'Coupon $cleanCode has been removed',
        );
      }
      return;
    }

    CouponModel coupon = coupons.firstWhere(
      (c) => c.code.trim().toUpperCase() == cleanCode,
      orElse: () => CouponModel.empty(),
    );

    if (coupon.code.isEmpty) {
      try {
        final fetched = await ref.read(couponRepositoryProvider).watchCouponByCode(cleanCode).first;
        if (fetched != null) {
          coupon = fetched;
        }
      } catch (_) {}
    }

    if (coupon.code.isEmpty) {
      if (mounted) {
        AppNotifications.showError(
          context,
          title: 'Invalid Coupon',
          message: 'No coupon found with code "$cleanCode"',
        );
      }
      return;
    }

    final user = ref.read(userProvider).value;
    final userTimesUsed = user?.getCouponUsage(coupon.code) ?? 0;

    if (coupon.applyOn == ApplyOn.products && coupon.applicableProducts.isNotEmpty) {
      final cart = ref.read(cartProvider).value;
      if (cart != null) {
        final filtered = cart.items.where((item) {
          final itemDeliveryType = item.selectedDeliveryType ?? DeliveryType.quick;
          return item.warehouseId == widget.orderSummaryArgs.warehouseId &&
              itemDeliveryType == widget.orderSummaryArgs.deliveryType &&
              !item.isSubscription;
        }).toList();
        final hasApplicableProduct = filtered.any((item) => coupon.applicableProducts.contains(item.productId));
        if (!hasApplicableProduct) {
          if (mounted) {
            AppNotifications.showError(
              context,
              title: 'Cannot Apply Coupon',
              message: 'This coupon is not applicable to items in your cart',
            );
          }
          return;
        }
      }
    }

    final reason = coupon.rejectReason(cartTotal, userTimesUsed);
    if (reason == null) {
      ref.read(appliedCouponProvider.notifier).apply(coupon);
      final discountAmount = coupon.calculateDiscount(cartTotal);
      if (mounted) {
        AppNotifications.showSuccess(
          context,
          title: 'Coupon Applied!',
          message: '${coupon.code} applied. You saved ${AppConfig.formatPrice(discountAmount)}',
        );
      }
    } else {
      if (mounted) {
        AppNotifications.showError(
          context,
          title: 'Cannot Apply Coupon',
          message: reason,
        );
      }
    }
  }

  Warehouse? _resolveWarehouse(List<Warehouse> warehouses, String? warehouseId) {
    if (warehouses.isEmpty) return null;
    for (final warehouse in warehouses) {
      if (warehouse.id == warehouseId) return warehouse;
    }
    return warehouses.first;
  }

  Future<_DeliveryCalc> _calculateDelivery(
    Warehouse warehouse,
    DeliveryType deliveryType,
    AppSettingsModel settings,
  ) async {
    final address = widget.orderSummaryArgs.deliveryAddress.address;

    // Use settings lat/lng if available, otherwise fallback to warehouse lat/lng
    final storeLat = settings.latitude != 0.0 ? settings.latitude : warehouse.latitude;
    final storeLng = settings.longitude != 0.0 ? settings.longitude : warehouse.longitude;

    final distanceKm = await LocationUtils.distanceInKm(
      storeLat,
      storeLng,
      address.latitude,
      address.longitude,
    );

    final dist = distanceKm ?? 0.0;
    double charge = 0.0;

    final sortedSlabs = List<DeliverySlab>.from(settings.deliveryDistanceSlabs)..sort((a, b) => a.upToKm.compareTo(b.upToKm));

    bool slabFound = false;
    for (var slab in sortedSlabs) {
      if (dist <= slab.upToKm) {
        charge = slab.charge;
        slabFound = true;
        break;
      }
    }

    if (!slabFound) {
      if (sortedSlabs.isNotEmpty) {
        charge = sortedSlabs.last.charge;
      } else {
        // Fallback to legacy hardcoded values if no slabs defined
        if (dist <= 3.0) {
          charge = 1700.0;
        } else if (dist <= 6.0) {
          charge = 3400.0;
        } else {
          charge = 5100.0;
        }
      }
    }

    return _DeliveryCalc(
      charge: charge,
      distanceKm: dist,
      model: 'Distance-based',
      extraKm: 0,
    );
  }

  void _showConfigErrorDialog([String? message]) {
    if (!mounted || _isConfigErrorDialogVisible) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isConfigErrorDialogVisible) return;

      _isConfigErrorDialogVisible = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Configuration Error"),
          content: Text(message ?? "Unable to fetch tax and delivery settings. Please try again later or contact support."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _isConfigErrorDialogVisible = false;
                context.pop();
              },
              child: const Text("Go Back"),
            ),
          ],
        ),
      ).then((_) {
        _isConfigErrorDialogVisible = false;
      });
    });
  }

  Future<void> _updateDeliveryCharge(Warehouse warehouse, [AppSettingsModel? settings]) async {
    if (!mounted) return;
    setState(() => _calculatingDelivery = true);
    try {
      final currentSettings = settings ?? await ref.read(settingsRepositoryProvider).getSettings();
      final calc = await _calculateDelivery(
        warehouse,
        widget.orderSummaryArgs.deliveryType,
        currentSettings,
      );
      if (mounted) {
        setState(() {
          _deliveryCalc = calc;
        });
      }
    } catch (e) {
      debugPrint("Delivery calculation error: $e");
      _showConfigErrorDialog("Failed to calculate delivery distance. Please check your internet.");
    } finally {
      if (mounted) {
        setState(() => _calculatingDelivery = false);
      }
    }
  }

  Future<void> _initDeliveryCharge() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    final warehouseId = widget.orderSummaryArgs.warehouseId;
    final warehouses = ref.read(warehouseProvider).value ?? [];
    final warehouse = _resolveWarehouse(warehouses, warehouseId);
    if (warehouse != null) {
      await _updateDeliveryCharge(warehouse, settings);
    } else {
      setState(() => _calculatingDelivery = false);
    }
  }

  bool get _upiValid {
    if (_selectedPaymentMethod != 'UPI') return true;
    return RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(_upiController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final address = widget.orderSummaryArgs.deliveryAddress;
    final products = widget.orderSummaryArgs.products;
    final cartAsync = ref.watch(cartProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final availableCoupons = ref.watch(couponsStreamProvider).maybeWhen(data: (c) => c, orElse: () => <CouponModel>[]);

    ref.listen<AsyncValue<List<Warehouse>>>(warehouseProvider, (prev, next) {
      if (next.hasError) {
        setState(() => _calculatingDelivery = false);
        _showConfigErrorDialog("System configuration could not be loaded.");
      }
      next.whenData((warehouses) {
        final warehouse = _resolveWarehouse(warehouses, widget.orderSummaryArgs.warehouseId);
        if (warehouse != null) {
          _updateDeliveryCharge(warehouse);
        } else if (!next.isLoading) {
          _showConfigErrorDialog("Warehouse configuration is missing in the database.");
        }
      });
    });

    ref.listen(selectedWarehousesProvider, (prev, next) {
      final warehouses = ref.read(warehouseProvider).value ?? [];
      final warehouse = _resolveWarehouse(warehouses, widget.orderSummaryArgs.warehouseId);
      if (warehouse != null) _updateDeliveryCharge(warehouse);
    });

    final warehouseAsync = ref.watch(warehouseProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value ?? AppSettingsModel.defaults;

    final selectedDeliveryType = widget.orderSummaryArgs.deliveryType;
    // Subscription checkout flow disabled.
    const selectedIsSubscription = false;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Order Summary",
          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.onBrand, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: cartAsync.when(
        loading: () => _loadingIndicator(scheme),
        error: (e, st) {
          print(e.toString());

          return Center(child: Text("Cart Error: $e"));
        },
        data: (cart) => warehouseAsync.when(
          loading: () => _loadingIndicator(scheme),
          error: (e, st) => Center(child: Text("Warehouse Error: $e")),
          data: (warehouses) {
            final warehouse = _resolveWarehouse(
              warehouses,
              widget.orderSummaryArgs.warehouseId,
            );
            if (warehouse == null) {
              return const Center(
                child: Text("Technical Error: Warehouse config missing."),
              );
            }
            final deliveryConfig = warehouse.deliveryProfileFor(selectedDeliveryType);
            final taxConfig = warehouse.taxConfig;
            final filteredCartItems = cart.items.where((item) {
              final itemDeliveryType = item.selectedDeliveryType ?? DeliveryType.quick;
              return item.warehouseId == widget.orderSummaryArgs.warehouseId &&
                  itemDeliveryType == selectedDeliveryType &&
                  item.isSubscription == selectedIsSubscription;
            }).toList();

            double totalMrp = 0;
            double totalSellingPrice = 0;
            final productMap = {for (var p in products) p.id: p};
            for (var item in filteredCartItems) {
              final product = productMap[item.productId];
              if (product == null) continue;
              final variant = product.getPackVariant(item.packVariantId);
              final price = variant?.price ?? product.price;
              final mrp = variant?.mrp ?? product.mrp ?? price;
              totalSellingPrice += price * item.quantity;
              totalMrp += mrp * item.quantity;
            }

            final couponSavings = appliedCoupon != null ? appliedCoupon.calculateDiscount(totalSellingPrice) : 0.0;

            final charges = _OrderCharges.compute(
              totalMrp: totalMrp,
              totalSellingPrice: totalSellingPrice,
              couponSavings: couponSavings,
              delivery: _deliveryCalc,
              deliveryConfig: deliveryConfig,
              taxConfig: taxConfig,
              paymentMethod: _selectedPaymentMethod,
              settings: settings,
            );

            final deliveryType = selectedDeliveryType;
            final isSubscription = selectedIsSubscription;

            return Column(
              children: [
                if (_calculatingDelivery) LinearProgressIndicator(minHeight: 2, color: scheme.primary),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                    children: [
                      SizedBox(height: 32.h),
                      _AppBarContent(
                        summary: widget.orderSummaryArgs,
                        deliveryType: deliveryType,
                        isSubscription: isSubscription,
                        address: address,
                      ),
                      SizedBox(height: 14.h),
                      ...filteredCartItems.map((item) {
                        final p = productMap[item.productId];
                        if (p == null) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.all(5.w),
                          child: _ProductCard(p, quantity: item.quantity, variant: p.getPackVariant(item.packVariantId)),
                        );
                      }),
                      SizedBox(height: 14.h),
                      _BillDetailsCard(
                        charges: charges,
                        delivery: _deliveryCalc,
                        deliveryConfig: deliveryConfig,
                        tax: taxConfig,
                        appliedCoupon: appliedCoupon,
                        paymentMethod: _selectedPaymentMethod,
                        calculatingDelivery: _calculatingDelivery,
                        settings: settings,
                      ),
                      SizedBox(height: 14.h),
                      _PaymentCard(
                        selected: _selectedPaymentMethod,
                        totalAmount: charges.total,
                        upiController: _upiController,
                        onChanged: (m) => setState(() => _selectedPaymentMethod = m),
                      ),
                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
                _BottomBar(
                  charges: charges,
                  paymentMethod: _selectedPaymentMethod,
                  canPlace: !_calculatingDelivery && _upiValid,
                  isPlacingOrder: _isPlacingOrder,
                  couponWidget: _CouponCard(
                    couponController: _couponController,
                    availableCoupons: availableCoupons,
                    appliedCoupon: appliedCoupon,
                    cartTotal: totalSellingPrice,
                    onCouponTap: (code) => _onCouponTap(code, totalSellingPrice, availableCoupons),
                  ),
                  onPlaceOrder: () => _placeOrder(products, address, charges),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _loadingIndicator(ColorScheme scheme) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(color: scheme.primary, size: 40),
    );
  }

  Future<void> _placeOrder(
    List<ProductModel> items,
    FullDeliveryAddress address,
    _OrderCharges charges,
  ) async {
    if (_selectedPaymentMethod == 'UPI' && !_upiValid) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please enter a valid UPI ID',
      );
      return;
    }

    final warehouseId = widget.orderSummaryArgs.warehouseId;
    final warehouses = ref.read(warehouseProvider).value ?? [];
    final warehouse = _resolveWarehouse(warehouses, warehouseId);

    if (warehouse == null) {
      _showConfigErrorDialog();
      return;
    }

    final selectedDeliveryType = widget.orderSummaryArgs.deliveryType;
    final selectedDeliveryConfig = warehouse.deliveryProfileFor(selectedDeliveryType);
    final selectedDeliveryBoyConfig = warehouse.deliveryBoyProfileFor(selectedDeliveryType);

    final settings = await ref.read(settingsRepositoryProvider).getSettings();

    final freshCalc = await _calculateDelivery(warehouse, selectedDeliveryType, settings);
    final freshCharges = _OrderCharges.compute(
      totalMrp: charges.subtotal + charges.mrpDiscount,
      totalSellingPrice: charges.subtotal,
      couponSavings: charges.couponDiscount,
      delivery: freshCalc,
      deliveryConfig: selectedDeliveryConfig,
      taxConfig: warehouse.taxConfig,
      paymentMethod: _selectedPaymentMethod,
      settings: settings,
    );

    if (AppConfig.getCleanPrice(freshCharges.total) < 100) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Minimum order amount is ₹100',
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final orderNumber = await orderRepo.generateOrderNumber();
      final productMap = {for (var p in items) p.id: p};
      final currentCart = ref.read(cartProvider).value;
      if (currentCart == null) return;
      // Subscription order placement disabled.
      const selectedIsSubscription = false;
      final filteredCartItems = currentCart.items.where((item) {
        final itemDeliveryType = item.selectedDeliveryType ?? DeliveryType.quick;
        return item.warehouseId == widget.orderSummaryArgs.warehouseId &&
            itemDeliveryType == selectedDeliveryType &&
            item.isSubscription == selectedIsSubscription;
      }).toList();

      final appliedCoupon = ref.read(appliedCouponProvider);
      final deliveryConfigSnapshot = DeliveryChargeProfile(
        deliveryTypeApplied: freshCalc.model,
        baseDeliveryCharge: selectedDeliveryConfig.baseDeliveryCharge,
        deliveryChargePerKm: selectedDeliveryConfig.deliveryChargePerKm,
        fixedDeliveryCharge: selectedDeliveryConfig.fixedDeliveryCharge,
        fixedDeliveryChargeForKm: selectedDeliveryConfig.fixedDeliveryChargeForKm,
        freeDeliveryThreshold: selectedDeliveryConfig.freeDeliveryThreshold,
        freeDeliveryDays: selectedDeliveryConfig.freeDeliveryDays,
      );
      final deliveryBoyConfigSnapshot = DeliveryBoyChargeProfile(
        baseDeliveryCharge: selectedDeliveryBoyConfig.baseDeliveryCharge,
        deliveryChargePerKm: selectedDeliveryBoyConfig.deliveryChargePerKm,
        fixedDeliveryCharge: selectedDeliveryBoyConfig.fixedDeliveryCharge,
        fixedDeliveryChargeForKm: selectedDeliveryBoyConfig.fixedDeliveryChargeForKm,
        deliveryCharge: freshCalc.charge,
        estimatedDeliveryBoyPayout: freshCalc.charge,
      );
      final deliveryType = selectedDeliveryType;

      final Map<String, OrderProductDetail> productDetails = {};
      for (var cartItem in filteredCartItems) {
        final product = productMap[cartItem.productId];
        if (product == null || product.id == null) continue;
        final variant = product.getPackVariant(cartItem.packVariantId);
        final price = variant?.price ?? product.price;
        final mrp = variant?.mrp ?? product.mrp;

        // Correct label for order detail
        String variantUnit = product.unit;
        if (variant != null) {
          final attrPart = variant.attributes.values.join(' / ');
          final packPart = variant.packSize > 1 ? 'Pack of ${variant.packSize}' : '';
          if (attrPart.isNotEmpty && packPart.isNotEmpty) {
            variantUnit = '$attrPart · $packPart';
          } else if (attrPart.isNotEmpty) {
            variantUnit = attrPart;
          } else if (packPart.isNotEmpty) {
            variantUnit = packPart;
          }
        }

        productDetails['${product.id}_${cartItem.packVariantId}'] = OrderProductDetail(
          finalAmount: price * cartItem.quantity,
          packVariantId: cartItem.packVariantId,
          name: product.name,
          unit: variantUnit,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
          packSize: variant?.packSize ?? 1,
          pricePerPack: price,
          mrpPerPack: mrp,
          quantity: cartItem.quantity,
        );
      }

      final paymentMethodValue = _selectedPaymentMethod;

      final snapshotWarehouseId = warehouse.id ?? warehouseId ?? '';

      _itemsToClear = filteredCartItems;

      // ── REGULAR ORDER PATH ───────────────────────────────────────────────
      final order = OrderModel(
        warehouseId: snapshotWarehouseId,
        userId: address.user.userId,
        deliveryType: deliveryType,
        repeatSchedule: widget.orderSummaryArgs.repeatSchedule,
        orderNumber: orderNumber,
        subtotal: freshCharges.subtotal,
        discount: freshCharges.mrpDiscount + freshCharges.couponDiscount,
        deliveryCharge: freshCharges.deliveryFee,
        total: freshCharges.total,
        platformFee: freshCharges.platformFee,
        packingFee: freshCharges.packingFee,
        extraOrderCharge: freshCharges.extraOrderCharge,
        status: OrderStatus.pending,
        paymentMethod: paymentMethodValue,
        paymentStatus: _selectedPaymentMethod == PaymentMethod.cod ? PaymentStatus.pending : PaymentStatus.awaitingPayment,
        user: address.user,
        deliveryAddress: address.address,
        products: items,
        productDetails: productDetails,
        appliedCouponCode: appliedCoupon?.code,
        deliveryConfig: deliveryConfigSnapshot,
        deliveryBoyConfig: deliveryBoyConfigSnapshot,
        taxConfig: warehouse.taxConfig,
      );

      final orderId = await orderRepo.createOrder(order);
      final persistedOrder = order.copyWith(id: orderId);
      await _sendOrderBillToWhatsApp(persistedOrder);

      // Online payment logic commented out as Razorpay is not configured
      /*
      if (paymentMethodValue == PaymentMethod.online) {
        _pendingOnlineOrder = persistedOrder;
        _razorPay?.initiatePayment(
          amount: freshCharges.total,
          name: AppConfig.appName,
          description: 'Payment for ${persistedOrder.orderNumber}',
          prefill: {
            'contact': address.user.mobileNo,
            'email': address.user.email ?? '',
          },
          orderId: null, // If using Razorpay Orders API, generate and pass here
        );
        return; // Wait for payment callback
      }
      */

      await _performCartCleanup();

      _clearCartAndNavigate();
    } catch (e) {
      if (mounted) {
        print(e.toString());
        if (kDebugMode) debugPrint(e.toString());
        AppNotifications.showError(
          context,
          title: 'Error',
          message: 'Failed to place order: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILL DETAILS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BillDetailsCard extends StatelessWidget {
  final _OrderCharges charges;
  final _DeliveryCalc delivery;
  final DeliveryChargeProfile deliveryConfig;
  final WarehouseTaxConfig tax;
  final CouponModel? appliedCoupon;
  final AppSettingsModel settings;

  final String paymentMethod;
  final bool calculatingDelivery;

  const _BillDetailsCard({
    required this.charges,
    required this.delivery,
    required this.deliveryConfig,
    required this.tax,
    required this.appliedCoupon,
    required this.paymentMethod,
    required this.calculatingDelivery,
    required this.settings,
  });

  static String _f(double v) => AppConfig.formatPrice(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalSavings = charges.mrpDiscount + charges.couponDiscount;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded, size: 18.sp, color: scheme.primary),
              ),
              SizedBox(width: 12.w),
              Text(
                "Bill Details",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ]),
            SizedBox(height: 20.h),
            _sectionLabel(context, "ITEMS"),
            SizedBox(height: 10.h),
            _row(context, "Items Total (MRP)", _f(charges.totalMrp)),
            if (charges.mrpDiscount > 0) _row(context, "Product Discount", "−${_f(charges.mrpDiscount)}", color: AppColors.success),
            if (charges.couponDiscount > 0)
              _row(
                context,
                "Coupon Savings (${appliedCoupon?.code ?? ''})",
                "−${_f(charges.couponDiscount)}",
                color: AppColors.success,
              ),
            SizedBox(height: 8.h),
            _row(context, "Items Subtotal", _f((charges.subtotal - charges.couponDiscount).clamp(0.0, double.infinity)), isBold: true),
            SizedBox(height: 16.h),
            const Divider(height: 1, thickness: 0.5),
            SizedBox(height: 16.h),
            _sectionLabel(context, "DELIVERY"),
            SizedBox(height: 10.h),
            _deliverySection(context, scheme, theme),
            SizedBox(height: 16.h),
            const Divider(height: 1, thickness: 0.5),
            SizedBox(height: 16.h),
            _sectionLabel(context, "TAXES & CHARGES"),
            SizedBox(height: 10.h),
            if (charges.platformFee > 0) _row(context, "Platform Fee", _f(charges.platformFee)),
            if (charges.packingFee > 0) _row(context, "Packing Fee", _f(charges.packingFee)),
            if (charges.extraOrderCharge > 0) _row(context, "Extra Order Charge", _f(charges.extraOrderCharge)),
            if (charges.gatewayFee > 0)
              _row(
                context,
                "Payment Gateway Fee",
                _f(charges.gatewayFee),
              ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Payable",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    _f(charges.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (totalSavings > 0) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.savings_rounded, size: 16, color: AppColors.success),
                    SizedBox(width: 8.w),
                    Text(
                      "You're saving ${_f(totalSavings)} on this order!",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.successDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _deliverySection(BuildContext context, ColorScheme scheme, ThemeData theme) {
    if (calculatingDelivery) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(children: [
            SizedBox(
              height: 14.h,
              child: AppLoader(strokeWidth: 1.5, color: scheme.primary),
            ),
            SizedBox(width: 30.w),
          ]),
        ),
      );
    }

    final isFree = charges.deliveryFree;
    // Increased valid range to 10,000km to handle long-distance testing/stores
    final isDistanceValid = delivery.distanceKm > 0 && delivery.distanceKm < 10000;

    String rangeText = "Location not set";
    if (isDistanceValid) {
      final sortedSlabs = List<DeliverySlab>.from(settings.deliveryDistanceSlabs)..sort((a, b) => a.upToKm.compareTo(b.upToKm));

      bool slabFound = false;
      for (var slab in sortedSlabs) {
        if (delivery.distanceKm <= slab.upToKm) {
          rangeText = "Up to ${slab.upToKm.toStringAsFixed(0)} KM range (${AppConfig.formatPrice(slab.charge, decimals: 0)})";
          slabFound = true;
          break;
        }
      }
      if (!slabFound && sortedSlabs.isNotEmpty) {
        rangeText =
            "Above ${sortedSlabs.last.upToKm.toStringAsFixed(0)} KM range (${AppConfig.formatPrice(sortedSlabs.last.charge, decimals: 0)})";
      } else if (!slabFound) {
        // Fallback display
        if (delivery.distanceKm <= 3.0) {
          rangeText = "0 - 3 KM range (${AppConfig.formatPrice(1700, decimals: 0)})";
        } else if (delivery.distanceKm <= 6.0) {
          rangeText = "3 - 6 KM range (${AppConfig.formatPrice(3400, decimals: 0)})";
        } else {
          rangeText = "6 - 10 KM range (${AppConfig.formatPrice(5100, decimals: 0)})";
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // distance + model chips
        if (delivery.distanceKm > 0) ...[
          Wrap(spacing: 8.w, runSpacing: 6.h, children: [
            _chip(context,
                icon: Icons.route_outlined,
                label: isDistanceValid ? "${delivery.distanceKm.toStringAsFixed(2)} km away" : "Invalid Distance (Check Store Lat/Long)"),
            _chip(context, icon: Icons.local_shipping_outlined, label: rangeText),
          ]),
          if (!isDistanceValid)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                "Warning: Store or Address coordinates are 0.0 in Database.",
                style: TextStyle(color: Colors.red, fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(height: 10.h),
        ],

        // free delivery banner
        if (isFree && deliveryConfig.freeDeliveryThreshold > 0) ...[
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(
              "Free delivery - order >= ${_f(deliveryConfig.freeDeliveryThreshold)}",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.successDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],

        SizedBox(height: 6.h),
        _row(
          context,
          "Delivery Fee",
          isFree ? "FREE" : _f(charges.deliveryFee),
          color: isFree ? AppColors.success : null,
          isBold: true,
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurfaceVariant, letterSpacing: 0.8));
  }

  Widget _row(BuildContext context, String label, String value, {Color? color, bool isBold = false, String? hint}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                      color: isBold ? null : scheme.onSurfaceVariant,
                    )),
              ),
              SizedBox(width: 16.w),
              Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color)),
            ],
          ),
          if (hint != null)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Text(hint, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required IconData icon, required String label}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13.sp, color: scheme.onSurfaceVariant),
        SizedBox(width: 4.w),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends ConsumerWidget {
  final String selected;
  final TextEditingController upiController;
  final double totalAmount;

  late String selectedOnlinePaymentMethod;
  final _formKey = GlobalKey<FormState>();

  // from key value

  final ValueChanged<String> onChanged;

  _PaymentCard({required this.selected, required this.upiController, required this.totalAmount, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      surfaceTintColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lock_outlined, size: 18.sp, color: scheme.primary),
              SizedBox(width: 8.w),
              Text('Payment Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            SizedBox(height: 4.h),
            Text('All transactions are encrypted & secure', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            SizedBox(height: 14.h),
            ..._kPaymentMethods.map((m) => _PaymentTile(
                method: m,
                isSelected: selected == m.id,
                onTap: () {
                  onChanged(m.id);
                })),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final _PaymentOption method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTile({required this.method, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isSelected ? scheme.primary.withValues(alpha: 0.06) : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isSelected ? scheme.primary : scheme.outlineVariant, width: isSelected ? 1.8.w : 1.w),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(method.icon, size: 22.sp, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: isSelected ? scheme.primary : null)),
                  SizedBox(height: 2.h),
                  Text(method.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle, key: const ValueKey('c'), color: scheme.primary, size: 22.sp)
                  : Icon(Icons.radio_button_unchecked, key: const ValueKey('u'), color: scheme.outlineVariant, size: 22.sp),
            ),
          ]),
        ),
      ),
    );
  }
}

class _UpiInput extends StatelessWidget {
  final TextEditingController controller;

  const _UpiInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'UPI ID',
        hintText: 'yourname@upi',
        prefixIcon: const Icon(Icons.alternate_email, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        helperText: 'e.g. name@okicici · name@ybl · name@paytm',
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) {
        final val = v?.trim() ?? '';
        if (val.isEmpty) return 'UPI ID is required';
        if (!RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(val)) {
          return 'Enter a valid UPI ID (e.g. name@upi)';
        }
        return null;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final _OrderCharges charges;
  final String paymentMethod;
  final bool canPlace;
  final VoidCallback onPlaceOrder;
  final bool isPlacingOrder;
  final Widget couponWidget;

  const _BottomBar({
    required this.charges,
    required this.paymentMethod,
    required this.canPlace,
    required this.onPlaceOrder,
    required this.isPlacingOrder,
    required this.couponWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: couponWidget,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, MediaQuery.of(context).padding.bottom + 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL PAYABLE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        AppConfig.formatPrice(charges.total),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                SizedBox(
                  height: 54.h,
                  width: 160.w,
                  child: ElevatedButton(
                    onPressed: (isPlacingOrder || !canPlace) ? null : onPlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: isPlacingOrder
                        ? const SizedBox(width: 20, height: 20, child: AppLoader(strokeWidth: 2, color: Colors.white))
                        : Text(
                            paymentMethod == PaymentMethod.cod ? 'PLACE ORDER' : 'PAY NOW',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarContent extends StatelessWidget {
  final OrderSummaryArgs summary;
  final DeliveryType deliveryType;
  final bool isSubscription;
  final FullDeliveryAddress address;

  const _AppBarContent({
    required this.summary,
    required this.deliveryType,
    required this.isSubscription,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, eta, icon) = switch (deliveryType) {
      DeliveryType.quick => (
          'Quick Delivery',
          '', // 'Arrives in ~10 minutes',
          Icons.flash_on
        ),
      DeliveryType.scheduled => ('Scheduled Delivery', 'Choose delivery time', Icons.schedule),
    };

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          ),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: deliveryType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: deliveryType.color),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  SizedBox(height: 3.h),
                  Text(eta, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2.h),
                  Text("Review your order before placing it",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),

// if Scheduled deliver  then show this widget to show recurring  schdule
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: deliveryType.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: deliveryType.color)),
            ),
          ]),
        ),
        SizedBox(
          height: 10.h,
        ),
        if (summary.repeatSchedule != null) RepeatScheduleCard(schedule: summary.repeatSchedule!),
        _DeliveryAddressCard(address),
      ],
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  final FullDeliveryAddress address;

  const _DeliveryAddressCard(this.address);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.location_on_outlined, color: scheme.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Deliver to", style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                SizedBox(height: 4.h),
                Text(address.user.userName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(address.address.fullAddress(), style: theme.textTheme.bodySmall),
                SizedBox(height: 4.h),
                Row(children: [
                  Icon(Icons.phone_outlined, size: 13.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 4.w),
                  Text(address.user.mobileNo, style: theme.textTheme.bodySmall),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final PackVariant? variant;

  const _ProductCard(this.product, {required this.quantity, this.variant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final price = variant?.price ?? product.price;
    final mrp = variant?.mrp ?? product.mrp;

    // Enhanced Label logic to show both Size/Attributes AND Pack Size
    String unitLabel = product.unit;
    if (variant != null) {
      final attrPart = variant!.attributes.values.join(' / ');
      final packPart = variant!.packSize > 1 ? 'Pack of ${variant!.packSize}' : '';
      if (attrPart.isNotEmpty && packPart.isNotEmpty) {
        unitLabel = '$attrPart · $packPart';
      } else if (attrPart.isNotEmpty) {
        unitLabel = attrPart;
      } else if (packPart.isNotEmpty) {
        unitLabel = packPart;
      }
    }

    final lineTotal = price * quantity;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              height: 70.w,
              width: 70.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: scheme.surfaceContainerHighest,
              ),
              child: product.imageUrls.isNotEmpty
                  ? ImageBuilder(
                      url: product.imageUrls.first,
                      width: 70.w,
                      height: 70.w,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.image_not_supported, color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(unitLabel, style: theme.textTheme.bodySmall),
                SizedBox(height: 2.h),
                Text("Qty: $quantity  ·  ${AppConfig.formatPrice(price)} each", style: theme.textTheme.bodySmall),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Item Total", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(AppConfig.formatPrice(lineTotal), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (mrp != null && (mrp * quantity) > lineTotal)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("MRP", style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                            Text(AppConfig.formatPrice(mrp * quantity),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(decoration: TextDecoration.lineThrough, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final List<CouponModel> availableCoupons;
  final CouponModel? appliedCoupon;
  final double cartTotal;
  final TextEditingController couponController;
  final void Function(String) onCouponTap;

  const _CouponCard({
    required this.couponController,
    required this.availableCoupons,
    required this.appliedCoupon,
    required this.cartTotal,
    required this.onCouponTap,
  });

  Future<void> _showBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
                left: 20.w,
                right: 20.w,
                top: 12.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.confirmation_number_outlined,
                          color: scheme.primary,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Apply Coupon",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Enter your coupon code to unlock savings",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          padding: EdgeInsets.all(8.w),
                          minimumSize: Size(32.w, 32.h),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(Icons.close_rounded, size: 18.sp),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Input Box Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: couponController.text.isNotEmpty ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: couponController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              letterSpacing: 1.1,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter code (e.g. GAUTAM10)',
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13.sp,
                                letterSpacing: 0,
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              prefixIcon: Icon(
                                Icons.local_offer_outlined,
                                color: scheme.primary,
                                size: 20.sp,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 14.h,
                              ),
                              border: InputBorder.none,
                              suffixIcon: couponController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.cancel_rounded,
                                        size: 18.sp,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        couponController.clear();
                                        setModalState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      SizedBox(
                        height: 50.h,
                        child: FilledButton(
                          onPressed: couponController.text.trim().isEmpty
                              ? null
                              : () {
                                  final code = couponController.text.trim().toUpperCase();
                                  Navigator.of(ctx).pop();
                                  onCouponTap(code);
                                },
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'APPLY',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Applied Coupon or Scratch Card Hint
                  if (appliedCoupon != null) ...[
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        appliedCoupon!.code,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Applied',
                                      style: TextStyle(
                                        color: AppColors.successDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Saving ${AppConfig.formatPrice(appliedCoupon!.calculateDiscount(cartTotal))} on this order',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.successDark,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                onCouponTap(appliedCoupon!.code);
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: scheme.error.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'REMOVE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp,
                                    color: scheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.08),
                            scheme.secondaryContainer.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              color: scheme.primary,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Have a Scratch Card?',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurface,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Scratch your card to reveal the secret coupon code and enter it above.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11.sp,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isApplied = appliedCoupon != null;

    return Card(
      surfaceTintColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showBottomSheet(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: isApplied ? AppColors.success : scheme.primary,
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: isApplied
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${appliedCoupon!.code} applied',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.successDark,
                            ),
                          ),
                          Text(
                            'Saving ${AppConfig.formatPrice(appliedCoupon!.calculateDiscount(cartTotal))}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Have a coupon code?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
              if (isApplied)
                TextButton(
                  onPressed: () => onCouponTap(appliedCoupon!.code),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Remove',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  'Apply',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
