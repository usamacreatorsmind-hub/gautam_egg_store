import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/core/services/notification_service.dart';
import 'package:sure_wholesaler/services/auth_service.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;
  final String verificationId;
  final int? resendToken;

  const OTPVerificationScreen({
    super.key,
    required this.mobileNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = AppConfig.firestore;

  late String _currentVerificationId;
  int? _currentResendToken;

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _currentResendToken = widget.resendToken;
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 60.h,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: scheme.primary,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: scheme.primary, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -50.h,
            left: -50.w,
            child: Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 100.h,
            right: -80.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 32.h),

                          Text(
                            'Verify Your Number',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),

                          SizedBox(height: 12.h),

                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: 'Enter the 4-digit code sent to\n'),
                                TextSpan(
                                  text: '${AppConfig.phonePrefix} ${widget.mobileNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                    fontSize: 18.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 48.h),

                          // OTP Input Card
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxWidth: 400.w),
                            padding: EdgeInsets.all(28.w),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(32.r),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.shadow.withValues(alpha: 0.05),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Pinput(
                                  length: 4,
                                  controller: _pinController,
                                  focusNode: _pinFocusNode,
                                  defaultPinTheme: defaultPinTheme,
                                  focusedPinTheme: focusedPinTheme,
                                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                                  onCompleted: (pin) => _verifyOTP(),
                                  cursor: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 9),
                                        width: 22,
                                        height: 1,
                                        color: scheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 40.h),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60.h,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                      elevation: 0,
                                      backgroundColor: scheme.primary,
                                      foregroundColor: scheme.onPrimary,
                                    ),
                                    onPressed: _isLoading ? null : _verifyOTP,
                                    child: _isLoading
                                        ? LoadingAnimationWidget.staggeredDotsWave(color: scheme.onPrimary, size: 30)
                                        : const Text("Verify & Proceed",
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Resend Logic
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _canResend
                                ? TextButton.icon(
                                    onPressed: _isLoading ? null : _resendOTP,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text(
                                      "Resend Code",
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  )
                                : Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 14.w,
                                          height: 14.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: _secondsRemaining / 60,
                                            color: scheme.primary.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          'Resend in ${_secondsRemaining}s',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
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

  Future<void> _verifyOTP() async {
    final otp = _pinController.text;
    if (otp.length != 4) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please enter all 4 digits',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fullNumber = '${AppConfig.phonePrefix}${widget.mobileNumber}';
      final success = await AuthService().verifyOTP(fullNumber, otp);

      if (success) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          unawaited(NotificationService.saveUserTokenToFireStore(user.uid));
        }

        HapticFeedback.mediumImpact();
        if (mounted) context.navigateAfterAuth();
      }
    } catch (e) {
      HapticFeedback.vibrate();
      AppNotifications.showError(
        context,
        title: 'Error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      final fullNumber = '${AppConfig.phonePrefix}${widget.mobileNumber}';
      await AuthService().sendOTP(fullNumber);

      if (mounted) {
        setState(() => _isLoading = false);
        _startTimer();
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: 'OTP resent successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifications.showError(
          context,
          title: 'Error',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}
