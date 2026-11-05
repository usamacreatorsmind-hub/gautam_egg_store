import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

class EditProfileFormWidget extends ConsumerStatefulWidget {
  const EditProfileFormWidget({super.key});

  @override
  ConsumerState<EditProfileFormWidget> createState() => _EditProfileFormWidgetState();
}

class _EditProfileFormWidgetState extends ConsumerState<EditProfileFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _pickedImage;
  final _mobileController = TextEditingController();

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String userImgUrl = "";
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final user = await ref.read(userProvider.notifier).getUserById(uid);

    if (user != null && mounted) {
      currentUser = user;

      _userNameController.text = user.userName;
      _emailController.text = user.email;
      _mobileController.text = user.mobileNo;

      setState(() {});
    }
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _uploadImage(currentUser!.userId);

      await ref.read(userProvider.notifier).updateUser(
            userImgUrl: userImgUrl.isNotEmpty ? userImgUrl : null,
            userName: _userNameController.text.trim(),
            email: _emailController.text.trim(),
            mobileNo: _mobileController.text.trim(),
          );

      if (mounted) {
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: 'Profile updated successfully',
        );
      }
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          /// ─────────────────────────────────────────────
          /// APP BAR
          /// ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            elevation: 0,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: scheme.onSurface,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withOpacity(0.08),
                      scheme.primaryContainer.withOpacity(0.16),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10.h),

                        /// Icon
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 70.r,
                                  backgroundColor: scheme.primary.withValues(alpha: 0.1),
                                  backgroundImage: _pickedImage != null
                                      ? FileImage(_pickedImage!) as ImageProvider
                                      : (currentUser?.userImg != null && currentUser!.userImg.isNotEmpty
                                          ? NetworkImage(currentUser!.userImg) as ImageProvider
                                          : null),
                                  child: (_pickedImage == null && (currentUser?.userImg == null || currentUser!.userImg.isEmpty))
                                      ? const Icon(Icons.person_outline, size: 48)
                                      : null,
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

                        SizedBox(height: 22.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// ─────────────────────────────────────────────
          /// FORM SECTION
          /// ─────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              18.w,
              24.h,
              18.w,
              40.h,
            ),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      enabled: true,
                      controller: _userNameController,
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 18.h),

                    _buildTextField(
                      label: 'Email Address',
                      hint: 'your@email.com',
                      enabled: true,
                      controller: _emailController,
                      icon: Icons.email_outlined,
                    ),

                    SizedBox(height: 18.h),

                    _buildTextField(
                      label: 'Mobile Number',
                      hint: 'Your mobile number',
                      enabled: false,
                      controller: _mobileController,
                      icon: Icons.phone_android_rounded,
                    ),

                    SizedBox(height: 34.h),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                        ),
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? LoadingAnimationWidget.horizontalRotatingDots(
                                color: scheme.onPrimary,
                                size: 28,
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 18.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Your information is secure',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool enabled,
    required String hint,
    TextEditingController? controller,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          enabled: enabled,
          controller: controller,
          validator: validator,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: scheme.primary,
                  )
                : null,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withOpacity(0.45),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18.w,
              vertical: 18.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22.r),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22.r),
              borderSide: BorderSide(
                color: scheme.primary,
                width: 1.8,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22.r),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
