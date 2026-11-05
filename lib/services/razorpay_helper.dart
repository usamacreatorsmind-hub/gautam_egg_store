import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';

class RazorPayHelper {
  final Razorpay _razorpay;

  final Function(String paymentId, String? orderId, String? signature) onSuccess;
  final Function(String error) onError;
  final Function(String wallet) onExternalWallet;

  RazorPayHelper({
    required this.onSuccess,
    required this.onError,
    required this.onExternalWallet,
  }) : _razorpay = Razorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void initiatePayment({
    required double amount,
    required String name,
    required String description,
    required Map<String, String> prefill,
    String? orderId,
  }) {
    // Convert to Rupees first using project's clean price logic,
    // then multiply by 100 for Razorpay (Paisa).
    final amountInRupees = AppConfig.getCleanPrice(amount);

    final options = {
      'key': AppConfig.RAZ_KEY,
      'amount': (amountInRupees * 100).toInt(),
      'name': name,
      'description': description,
      'prefill': prefill,
      if (orderId != null) 'order_id': orderId,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError('Failed to open payment gateway: ${e.toString()}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId ?? '';
    if (paymentId.isEmpty) {
      onError('Invalid payment response');
      return;
    }

    onSuccess(paymentId, response.orderId, response.signature);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError('${response.code} - ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet(response.walletName ?? '');
  }
}
