import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/core/services/notification_service.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

class UserScreen extends ConsumerStatefulWidget {
  final String mobileNumber;
  const UserScreen({super.key, required this.mobileNumber});

  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends ConsumerState<UserScreen> {
  bool _isLoading = false;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _agreeToTerms = false;

  String userImgUrl = '';

  final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _pickedImage = File(file.path));
  }

  Future<void> _uploadImage(String userId) async {
    if (_pickedImage == null) return;
    final result = await ref.read(userProvider.notifier).uploadProfilePicture(
          _pickedImage!,
        );
    if (result != null) {
      userImgUrl = result;
    } else {
      throw Exception('Image upload returned no URL. Check Firebase Storage rules.');
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    if (!_agreeToTerms) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please accept the Terms & Privacy Policy',
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Await the image upload first so userImgUrl is populated
      await _uploadImage(uid);

      final user = UserModel(
        usedCoupons: {},
        isProfileCreated: true,
        userImg: userImgUrl,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        userId: uid,
        userName: _userNameController.text.trim(),
        mobileNo: widget.mobileNumber,
        fcmTokens: [],
        email: _emailController.text.trim(),
      );

      await ref.read(userProvider.notifier).saveUser(user);

      if (uid.isNotEmpty) {
        await NotificationService.saveUserTokenToFireStore(uid);
      }

      if (!mounted) return;

      AppRouter.markProfileCreated();
      HapticFeedback.mediumImpact();
      context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          title: 'Error',
          message: 'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
            child: Column(
              children: [
                SizedBox(height: 28.h),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Profile Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 70.r,
                                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                                backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) as ImageProvider : null,
                                child: _pickedImage == null ? Icon(Icons.person_add_alt_1, size: 40.r, color: scheme.primary) : null,
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.camera_alt, size: 14.sp, color: scheme.onPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 32.h),

                      _buildTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _userNameController,
                        icon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                      ),

                      SizedBox(height: 16.h),

                      _buildTextField(
                        label: 'Email Address',
                        hint: 'your@email.com',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (!_emailRegExp.hasMatch(v)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      _buildTextField(
                        label: 'Mobile Number',
                        hint: widget.mobileNumber,
                        initialValue: widget.mobileNumber,
                        icon: Icons.phone_android_outlined,
                        enabled: false,
                      ),

                      SizedBox(height: 24.h),

                      /// 🔹 Terms Checkbox
                      InkWell(
                        onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: theme.textTheme.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: 'Terms',
                                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      /// 🔹 Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                          ),
                          onPressed: _isLoading ? null : _saveData,
                          child: _isLoading
                              ? LoadingAnimationWidget.staggeredDotsWave(
                                  color: scheme.onPrimary,
                                  size: 30,
                                )
                              : const Text(
                                  'Complete Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 14.sp, color: scheme.outline),
                          SizedBox(width: 6.w),
                          Text(
                            'Secure profile creation',
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    String? initialValue,
    TextEditingController? controller,
    IconData? icon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: enabled ? scheme.onSurface : scheme.outline,
            )),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: enabled ? scheme.onSurface : scheme.outline,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            fillColor: enabled ? scheme.surface : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.r),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.r),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.r),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
