import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/features/invoicePdfService/InvoicePdfService.dart';
// import 'package:sure_wholesaler/services/razorpay_helper.dart';
import 'package:sure_wholesaler/models/order_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/delivery_agent_notifier.dart';
import 'package:sure_wholesaler/notifiers/order_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_review_notifier.dart';
import 'package:sure_wholesaler/screens/product/product_review_form.dart';
import 'package:sure_wholesaler/screens/product/product_review_widget.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import '../../widgets/image_builder.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  // Razorpay disabled as it is not yet configured for this project
  // RazorPayHelper? _razorPay;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /*
  Future<void> _markOrderPaid() async {
    if (!mounted) return;
    final orderId = widget.order.id;
    if (orderId == null) return;
    final updated = widget.order.copyWith(paymentStatus: PaymentStatus.paid);
    await ref.read(orderRepositoryProvider).updateOrder(orderId, updated);
    if (!mounted) return;
    // setState(() => _isPaying = false);
    AppNotifications.showSuccess(
      context,
      title: 'Success',
      message: 'Payment successful!',
    );
  }
  */

  /*
  void _payNow(OrderModel order) {
    setState(() => _isPaying = true);
    _razorPay?.initiatePayment(
      amount: order.total,
      name: AppConfig.appName,
      description: 'Order #${order.orderNumber}',
      prefill: {
        'contact': order.user.mobileNo,
        'email': order.user.email ?? '',
      },
    );
  }
  */

  void _showCancelDialog(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Keep Order"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref.read(orderProvider.notifier).cancelOrder(order.id!);
              if (!mounted) return;
              if (success) {
                AppNotifications.showSuccess(
                  context,
                  title: 'Success',
                  message: 'Order cancelled successfully',
                );
              } else {
                AppNotifications.showError(
                  context,
                  title: 'Error',
                  message: 'Failed to cancel order',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text("Cancel Order"),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBill(OrderModel order) async {
    try {
      await OrderBillGenerator.printPdf(order);
    } catch (_) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Failed to generate bill',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdStreamProvider(widget.order.id!));

    return orderAsync.when(
      loading: () => _buildScaffold(context, widget.order),
      error: (_, __) => _buildScaffold(context, widget.order),
      data: (order) => _buildScaffold(context, order ?? widget.order),
    );
  }

  /*
  Widget _buildBottomBar(BuildContext context, OrderModel order) {
    final scheme = Theme.of(context).colorScheme;
    final normalizedPaymentMethod = (order.paymentMethod ?? '').toUpperCase();
    // Online payment disabled as Razorpay is not yet configured
    final needsPayment = false;
    /*
    final needsPayment = order.paymentStatus == PaymentStatus.awaitingPayment &&
        (normalizedPaymentMethod == PaymentMethod.online || normalizedPaymentMethod.startsWith('UPI'));
    */

    if (needsPayment) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: OutlinedButton(
                  onPressed: () => _generateBill(order),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: const Text(
                    'Bill',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            if (order.status == OrderStatus.pending) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ElevatedButton(
                    onPressed: () => _showCancelDialog(context, order),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48.h),
                      side: BorderSide(color: scheme.primary, width: 1.5),
                      backgroundColor: AppColors.badge,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isPaying ? null : () => _payNow(order),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                ),
                child: _isPaying
                    ? SizedBox(height: 20.h, width: 20.h, child: AppLoader(strokeWidth: 2, color: scheme.onPrimary))
                    : Text('Pay Now', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    if (order.status == OrderStatus.pending) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: OutlinedButton(
                  onPressed: () => _generateBill(order),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: const Text(
                    'Bill',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context, order),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.brandSeed,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  'Cancel Order',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: OutlinedButton(
                onPressed: () => _generateBill(order),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: const Text(
                  'Generate Bill',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48.h), backgroundColor: AppColors.brandSeed),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.background)),
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildBottomBar(BuildContext context, OrderModel order) {
    if (order.status == OrderStatus.pending) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: OutlinedButton(
                  onPressed: () => _generateBill(order),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  child: const Text(
                    'Bill',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context, order),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppConfig.appName == 'Gautam Egg Store' ? Colors.red.shade700 : AppColors.brandSeed,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: OutlinedButton(
                onPressed: () => _generateBill(order),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: const Text(
                  'Generate Bill',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                backgroundColor: AppColors.brandSeed,
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.background),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, OrderModel order) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;

    final productLookup = {for (var p in order.products) p.id: p};

    // ── price calculations ──────────────────────────────────────────────────
    final double totalMrp = order.productDetails.values.fold(0.0, (sum, d) => sum + d.mrpLineTotal);
    final subtotal = order.subtotal; // This is totalSellingPrice
    final mrpDiscount = (totalMrp - subtotal).clamp(0.0, double.infinity);
    final couponDiscount = (order.discount - mrpDiscount).clamp(0.0, double.infinity);
    final netProductAmount = (subtotal - couponDiscount).clamp(0.0, double.infinity);

    final platformFee = order.platformFee;
    final packingFee = order.packingFee;
    final extraOrderCharge = order.extraOrderCharge;

    final baseTotal = netProductAmount + order.deliveryCharge + platformFee + packingFee + extraOrderCharge;

    final gatewayFee = (order.paymentMethod != null &&
            order.paymentMethod!.toLowerCase() != 'cod' &&
            order.paymentMethod!.toLowerCase() != 'cash on delivery')
        ? baseTotal * order.taxConfig.paymentGatewayChargePercentage / 100
        : 0.0;

    final calculatedTotal = baseTotal + gatewayFee;
    // ────────────────────────────────────────────────────────────────────────

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
      ),
      bottomNavigationBar: _buildBottomBar(context, order),
      body: ListView(
        padding: EdgeInsets.all(12.w),
        children: [
          // ── Order header ──────────────────────────────────────────────────
          _OrderHeaderCard(order: order),
          SizedBox(height: 12.h),

          // ── Delivery agent ────────────────────────────────────────────────
          if (order.deliveryAgentId != null) ...[
            DeliveryAgentTile(deliveryAgentId: order.deliveryAgentId!),
            SizedBox(height: 12.h),
          ],

          // ── Items ordered ─────────────────────────────────────────────────
          _SectionCard(
            title: "Items Ordered",
            child: Column(
              children: order.productDetails.entries.map((entry) {
                final detail = entry.value;
                final productId = entry.key.split('_').first;
                var product = productLookup[productId];
                product ??= order.products.firstWhere(
                  (p) => p.variantIds.contains(detail.packVariantId),
                  orElse: () => ProductModel.fromMap({'name': 'Product'}, productId),
                );
                return Column(
                  children: [
                    InkWell(onTap: () => context.goToProductDetails(product!), child: _OrderItemRow(product: product, detail: detail)),
                    if (order.status == OrderStatus.delivered)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final hasReviewed = ref.watch(hasReviewedOrderItemProvider(entry.key));
                            return hasReviewed.maybeWhen(
                              data: (reviewed) => reviewed
                                  ? const SizedBox.shrink()
                                  : Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: theme.scaffoldBackgroundColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                                            ),
                                            builder: (context) => Padding(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context).viewInsets.bottom,
                                                left: 16.w,
                                                right: 16.w,
                                                top: 20.h,
                                              ),
                                              child: ProductReviewForm(
                                                productId: productId,
                                                orderId: order.id!,
                                                orderItemId: entry.key,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.rate_review_outlined, size: 16.sp),
                                        label: const Text("Rate & Review"),
                                      ),
                                    ),
                              orElse: () => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 12.h),

          // ── Coupon applied ────────────────────────────────────────────────
          if (order.appliedCouponCode != null) ...[
            _SectionCard(
              title: "Coupon Applied",
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 16.sp, color: AppColors.success),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      order.appliedCouponCode!,
                      style: TextStyle(
                        color: AppColors.successDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "- ${AppConfig.formatPrice(couponDiscount)} saved",
                    style: TextStyle(color: AppColors.successDark, fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // ── Bill details ──────────────────────────────────────────────────
          if (!order.isSubscriptionOrder) ...[
            _SectionCard(
              title: "Bill Details",
              child: Column(
                children: [
                  if (totalMrp > 0) _BillRow("Items Total (MRP)", AppConfig.formatPrice(totalMrp)),
                  if (mrpDiscount > 0)
                    _BillRow(
                      "Product Discount",
                      "- ${AppConfig.formatPrice(mrpDiscount)}",
                      valueColor: scheme.tertiary,
                    ),
                  if (couponDiscount > 0)
                    _BillRow(
                      "Coupon Savings",
                      "- ${AppConfig.formatPrice(couponDiscount)}",
                      valueColor: AppColors.success,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  _BillRow("Items Subtotal", AppConfig.formatPrice(netProductAmount), isBold: true),
                  SizedBox(height: 8.h),
                  if (order.deliveryCharge >= 0) ...[
                    _BillRow(
                      "Delivery Fee",
                      order.deliveryCharge == 0 ? "FREE" : AppConfig.formatPrice(order.deliveryCharge),
                      valueColor: order.deliveryCharge == 0 ? AppColors.success : null,
                    ),
                  ],
                  if (platformFee > 0) _BillRow("Platform Fee", AppConfig.formatPrice(platformFee)),
                  if (packingFee > 0) _BillRow("Packing Fee", AppConfig.formatPrice(packingFee)),
                  if (extraOrderCharge > 0) _BillRow("Extra Order Charge", AppConfig.formatPrice(extraOrderCharge)),
                  if (gatewayFee > 0) _BillRow("Payment Gateway Fee", AppConfig.formatPrice(gatewayFee)),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Divider(height: 1, color: scheme.outlineVariant),
                  ),
                  _BillRow(
                    "Total Amount",
                    AppConfig.formatPrice(calculatedTotal),
                    isBold: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          if (!order.isSubscriptionOrder) ...[
            _SectionCard(
              title: "Payment",
              child: Column(
                children: [
                  _BillRow("Method", order.paymentMethod?.toUpperCase() ?? "COD"),
                  _BillRow(
                    "Status",
                    (order.paymentStatus ?? "Pending").toUpperCase(),
                    valueColor: order.paymentStatus == PaymentStatus.paid ? AppColors.success : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],

          // ── Payment info ──────────────────────────────────────────────────
          SizedBox(height: 12.h),

          // ── Notes ─────────────────────────────────────────────────────────
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            _SectionCard(
              title: "Order Notes",
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 16.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(order.notes!, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // ── Order info ────────────────────────────────────────────────────
          _SectionCard(
            title: "Order Info",
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.tag_rounded,
                  label: "Order Number",
                  value: order.orderNumber,
                  scheme: scheme,
                  theme: theme,
                ),
                if (order.warehouseId.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _InfoRow(
                    icon: Icons.warehouse_outlined,
                    label: "Fulfilled by",
                    value: order.warehouseId,
                    scheme: scheme,
                    theme: theme,
                  ),
                ],
                SizedBox(height: 8.h),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: "Placed on",
                  value: _formatDateTime(order.createdAt),
                  scheme: scheme,
                  theme: theme,
                ),
                SizedBox(height: 8.h),
                _InfoRow(
                  icon: Icons.update_rounded,
                  label: "Last updated",
                  value: _formatDateTime(order.updatedAt),
                  scheme: scheme,
                  theme: theme,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // ── Reviews ───────────────────────────────────────────────────────
          if (order.status == OrderStatus.delivered) ...[
            _SectionCard(
              title: "Reviews",
              child: Column(
                children: order.productDetails.keys.map((orderItemId) {
                  final productId = orderItemId.split('_').first;
                  return ProductReviewWidget(productId: productId, onlyMyReview: true);
                }).toList(),
              ),
            ),
            SizedBox(height: 12.h),
          ],

//view Subscription  order
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month]} ${d.year}, $h:$m $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order header card
// ─────────────────────────────────────────────────────────────────────────────

class _OrderHeaderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderHeaderCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderProgressBar(orderStatus: order.status),
            SizedBox(height: 22.h),
            Row(
              children: [
                Container(
                  height: 54.w,
                  width: 54.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    color: scheme.primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: scheme.primary,
                    size: 26.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            SizedBox(height: 18.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                color: order.deliveryType.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: order.deliveryType.color.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      order.deliveryType.icon,
                      size: 18.sp,
                      color: order.deliveryType.color,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${order.deliveryType.label} Delivery",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: order.deliveryType.color,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          order.isDelivered ? "Delivered Successfully" : "Your order is being processed",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // if (!order.isDelivered &&
            //     !order.isCancelled &&
            //     order.deliveryType == DeliveryType.quick &&
            //     order.warehouseId.isNotEmpty) ...[
            //   SizedBox(height: 18.h),
            //   Consumer(
            //     builder: (context, ref, child) {
            //       final warehouseAsync = ref.watch(
            //         warehouseLatLngbyIdProvider(order.warehouseId),
            //       );
            //
            //       return warehouseAsync.when(
            //         loading: () => const SizedBox.shrink(),
            //         error: (_, __) => const SizedBox.shrink(),
            //         data: (warehouseLatLng) {
            //           if (warehouseLatLng == null) {
            //             return const SizedBox.shrink();
            //           }
            //
            //           return FutureBuilder<double?>(
            //             future: LocationUtils.distanceInKm(
            //               order.deliveryAddress.latitude,
            //               order.deliveryAddress.longitude,
            //               warehouseLatLng.latitude,
            //               warehouseLatLng.longitude,
            //             ),
            //             builder: (context, snapshot) {
            //               if (!snapshot.hasData) {
            //                 return const SizedBox.shrink();
            //               }
            //
            //               final minutes =
            //                   ((snapshot.data ?? 0) * 5).toStringAsFixed(0);
            //
            //               return Container(
            //                 padding: EdgeInsets.symmetric(
            //                   horizontal: 14.w,
            //                   vertical: 12.h,
            //                 ),
            //                 decoration: BoxDecoration(
            //                   color: Colors.orange.withValues(alpha: 0.08),
            //                   borderRadius: BorderRadius.circular(18.r),
            //                 ),
            //                 child: Row(
            //                   children: [
            //                     Icon(
            //                       Icons.flash_on_rounded,
            //                       color: Colors.orange.shade700,
            //                       size: 18.sp,
            //                     ),
            //                     SizedBox(width: 10.w),
            //                     Expanded(
            //                       child: Text(
            //                         "Arriving in $minutes minutes",
            //                         style: theme.textTheme.bodyMedium?.copyWith(
            //                           fontWeight: FontWeight.w600,
            //                           color: Colors.orange.shade800,
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               );
            //             },
            //           );
            //         },
            //       );
            //     },
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${d.day} ${months[d.month]} ${d.year}';
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case OrderStatus.confirmed:
      case OrderStatus.packed:
      case OrderStatus.outForDelivery:
        bg = scheme.primary.withValues(alpha: 0.12);
        fg = scheme.primary;
        break;
      case OrderStatus.delivered:
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        break;
      case OrderStatus.cancelled:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      default: // pending
        bg = AppColors.warningBg;
        fg = AppColors.warningDark;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.025),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 16.h),
            child,
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Order item row
// ─────────────────────────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final ProductModel product;
  final OrderProductDetail? detail;

  const _OrderItemRow({required this.product, this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final qty = detail?.quantity ?? 1;
    final pricePerPack = detail?.pricePerPack ?? product.price;
    final packSize = detail?.packSize ?? 1;
    final lineTotal = pricePerPack * qty;
    final mrpPerPack = detail?.mrpPerPack ?? pricePerPack;
    final lineMrpTotal = mrpPerPack * qty;

    final name = detail?.name.isNotEmpty == true ? detail!.name : product.name;
    final imageUrl =
        detail?.imageUrl?.isNotEmpty == true ? detail!.imageUrl : (product.imageUrls.isNotEmpty ? product.imageUrls.first : null);
    final unitLabel = detail?.unit.isNotEmpty == true ? detail!.unit : (packSize > 1 ? 'Pack of $packSize' : product.unit);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: 64.w,
              height: 64.w,
              color: scheme.surfaceContainerHighest,
              child: imageUrl != null
                  ? ImageBuilder(
                      url: imageUrl,
                      width: 64.w,
                      height: 64.w,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.shopping_bag, color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text("$unitLabel  ×  $qty",
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                SizedBox(height: 6.h),
                // price breakdown box
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Item Total", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            AppConfig.formatPrice(lineTotal),
                            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.brandSeed),
                          ),
                        ],
                      ),
                      if (lineMrpTotal > lineTotal)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("MRP", style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                              Text(
                                AppConfig.formatPrice(lineMrpTotal),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Bill detail row
// ─────────────────────────────────────────────────────────────────────────────

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _BillRow(this.label, this.value, {this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row (icon + label + value)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: scheme.onSurfaceVariant),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              SizedBox(height: 2.h),
              Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery agent tile
// ─────────────────────────────────────────────────────────────────────────────

class DeliveryAgentTile extends ConsumerWidget {
  final String deliveryAgentId;
  const DeliveryAgentTile({super.key, required this.deliveryAgentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final deliveryAgentAsync = ref.watch(deliveryAgentProvider(deliveryAgentId));

    return deliveryAgentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return Card(
          surfaceTintColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundImage: data.profileImageUrl.isNotEmpty ? NetworkImage(data.profileImageUrl) : null,
                  onBackgroundImageError: data.profileImageUrl.isNotEmpty ? (_, __) {} : null,
                  child: data.profileImageUrl.isEmpty ? const Icon(Icons.person, color: AppColors.textSecondary) : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Delivery Agent", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(data.fullName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.two_wheeler, size: 16.sp, color: scheme.onSurfaceVariant),
                    SizedBox(height: 2.h),
                    Text(data.bikeNumber, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderStep {
  final String label;
  final IconData icon;
  const _OrderStep({required this.label, required this.icon});
}

class OrderProgressBar extends ConsumerWidget {
  final String orderStatus;

  const OrderProgressBar({super.key, required this.orderStatus});

  static const _steps = [
    _OrderStep(label: 'Placed', icon: Icons.receipt_long_outlined),
    _OrderStep(label: 'Confirmed', icon: Icons.check_circle_outline),
    _OrderStep(label: 'On the Way', icon: Icons.delivery_dining),
    _OrderStep(label: 'Delivered', icon: Icons.home_outlined),
  ];

  int _getStep(String status) {
    switch (status.toLowerCase()) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.confirmed:
      case OrderStatus.packed:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (orderStatus == OrderStatus.cancelled) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: scheme.error, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Order Cancelled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final step = _getStep(orderStatus);

    return Column(
      children: [
        // Dots + connector lines
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final isFilled = step > (i ~/ 2) + 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2.h,
                  color: isFilled ? scheme.primary : scheme.surfaceContainerHighest,
                ),
              );
            }
            final dotIndex = i ~/ 2;
            return _StepDot(
              icon: _steps[dotIndex].icon,
              isActive: step > dotIndex,
              isCurrent: step == dotIndex + 1,
            );
          }),
        ),
        SizedBox(height: 6.h),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            _steps.length,
            (i) => _StatusStepLabel(
              label: _steps[i].label,
              isActive: step > i,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isCurrent;

  const _StepDot({
    required this.icon,
    required this.isActive,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = isCurrent ? 28.w : 24.w;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
        border: isCurrent ? Border.all(color: scheme.primary, width: 2) : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.30),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 13.sp,
        color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
      ),
    );
  }
}

class _StatusStepLabel extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusStepLabel({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: isActive ? scheme.primary : scheme.onSurfaceVariant,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        fontSize: 10.sp,
      ),
    );
  }
}
