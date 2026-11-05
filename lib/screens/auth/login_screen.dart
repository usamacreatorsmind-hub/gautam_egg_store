import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/asset_constants.dart';
import 'package:sure_wholesaler/core/providers/policy_provider.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
    _getPhoneNumberHint();
  }

  Future<void> _getPhoneNumberHint() async {
    try {
      final res = await SmartAuth.instance.requestPhoneNumberHint();
      if (res.hasData) {
        String phone = res.requireData.replaceAll(RegExp(r'\D'), '');
        if (phone.length > 10) {
          phone = phone.substring(phone.length - 10);
        }
        _mobileController.text = phone;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting phone hint: $e');
    }
  }

  Future<void> _launchPrivacyUrl() async {
    try {
      final policy = await ref.read(policyProvider.future);
      final uri = Uri.parse(policy.privacyUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _launchTermsUrl() async {
    try {
      final policy = await ref.read(policyProvider.future);
      final uri = Uri.parse(policy.termsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Circular Elements
          Positioned(
            top: -120.h,
            right: -80.w,
            child: Container(
              width: 320.r,
              height: 320.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -100.h,
            left: -80.w,
            child: Container(
              width: 280.r,
              height: 280.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: 40.h),
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AssetConstants.appLogo,
                              height: 64.r,
                              width: 64.r,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.egg_rounded,
                                size: 54.r,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Brand Section
                          Text(
                            AppConfig.appName,
                            style: textTheme.displaySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "Fresh. Green. Delivered.",
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const Spacer(flex: 1),

                          // Login Card
                          Container(
                            padding: EdgeInsets.all(32.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Login",
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1A1C1E),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Enter your mobile number to get started",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 32.h),
                                  _buildPhoneInput(scheme, theme),
                                  SizedBox(height: 32.h),
                                  _buildSubmitButton(scheme),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 1),
                          _buildFooterLinks(scheme),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks(ColorScheme scheme) {
    return Wrap(
      spacing: 8.w,
      alignment: WrapAlignment.center,
      children: [
        _footerAction(Icons.help_outline, "Help", scheme, () => context.push(AppRoutes.helpSupport)),
        _footerAction(Icons.description_outlined, "Privacy", scheme, _launchPrivacyUrl),
        _footerAction(Icons.privacy_tip_outlined, "Terms", scheme, _launchTermsUrl),
      ],
    );
  }

  Widget _footerAction(IconData icon, String label, ColorScheme scheme, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: scheme.primary.withValues(alpha: 0.6)),
      label: Text(
        label,
        style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _footerItem(IconData icon, String label, VoidCallback onTap, ColorScheme scheme,) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color:scheme.primary),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildPhoneInput(ColorScheme scheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: TextFormField(
        onTap: () {
          if (_mobileController.text.isEmpty) _getPhoneNumberHint();
        },
        controller: _mobileController,
        focusNode: _focusNode,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _handleLogin(),
        maxLength: 10,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1C1E),
          letterSpacing: 1,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _FirstDigitAllowedFormatter(),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter mobile number';
          }
          if (value.length != 10) {
            return 'Please enter 10 digit mobile number';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Mobile Number',
          hintStyle: TextStyle(
            fontSize: 19,
            color: Colors.grey.shade500,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
          counterText: '',
          prefixIcon: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16.w),
                Text(
                  "+91",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                VerticalDivider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                  indent: 12.h,
                  endIndent: 12.h,
                ),
                SizedBox(width: 8.w),
              ],
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18.h),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme scheme) {
    return SizedBox(
      width: double.infinity,
      height: 58.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Sending OTP...',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get OTP',
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward_rounded, size: 20.sp),
                ],
              ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    var mobile = _mobileController.text.trim();
    // Remove leading zero if present (e.g., 09876543210 -> 9876543210)
    if (mobile.startsWith('0')) {
      mobile = mobile.substring(1);
    }

    final fullNumber = '${AppConfig.phonePrefix}$mobile';

    try {
      await AuthService().sendOTP(fullNumber);

      if (mounted) {
        setState(() => _isLoading = false);
        context.push(
          AppRoutes.otpVerification,
          extra: {
            'mobileNumber': mobile,
            'verificationId': 'msg91_flow',
          },
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

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);
    final mobile = _mobileController.text.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '${AppConfig.phonePrefix}$mobile',
        verificationCompleted: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            AppNotifications.showError(
              context,
              title: 'Error',
              message: e.message ?? 'Verification failed',
            );
          }
        },
        codeSent: (verificationId, _) {
          if (mounted) {
            setState(() => _isLoading = false);
            context.pushReplacement(
              AppRoutes.otpVerification,
              extra: {
                'mobileNumber': mobile,
                'verificationId': verificationId,
              },
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _FirstDigitAllowedFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    return RegExp(r'^[06789]').hasMatch(text) ? newValue : oldValue;
  }
}
