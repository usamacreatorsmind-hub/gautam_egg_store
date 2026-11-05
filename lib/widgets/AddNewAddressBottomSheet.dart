import 'dart:async';

import 'package:sure_wholesaler/widgets/select_address_on_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import '../models/address_model.dart';
import '../notifiers/address_notifier.dart';
import '../utils/location_base_classes/location_service.dart';
import 'app_loader.dart';

class AddNewAddressBottomSheet extends ConsumerStatefulWidget {
  const AddNewAddressBottomSheet({super.key});

  @override
  ConsumerState<AddNewAddressBottomSheet> createState() => _AddNewAddressBottomSheetState();
}

class _AddNewAddressBottomSheetState extends ConsumerState<AddNewAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _receiverNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _tagController = TextEditingController(text: 'Home');

  String _selectedTag = 'Home';
  final List<String> _tags = ['Home', 'Office', 'Other'];

  bool _isSaving = false;
  bool _isFetchingLocation = false;
  String _errorMessage = '';

  bool _isFromCurrentLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _tagController.text = _selectedTag;
  }

  void _onPickLocation() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectAddressOnMapScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (picked == null || !mounted) return;

    final placemark = picked['placemark'] as geocoding.Placemark?;
    setState(() {
      _latitude = picked['latitude'] as double?;
      _longitude = picked['longitude'] as double?;
      _isFromCurrentLocation = true;
      if (picked['address'] != null) {
        _addressController.text = picked['address'];
      }
    });

    if (placemark != null) {
      _fillAddressFieldsFromPlacemark(placemark);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final location = await LocationService.getCurrentLocation();
      final placemark = await LocationService.getFullAddress(
        location.latitude!,
        location.longitude!,
      );

      _fillAddressFieldsFromPlacemark(placemark);

      _latitude = location.latitude;
      _longitude = location.longitude;
      _isFromCurrentLocation = true;

      if (mounted) {
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: 'Location fetched successfully',
        );
      }
    } catch (_) {
      if (mounted) {
        AppNotifications.showError(
          context,
          title: 'Error',
          message: 'Failed to fetch location',
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _fillAddressFieldsFromPlacemark(geocoding.Placemark placemark) {
    _addressController.text =
        [placemark.street, placemark.subLocality, placemark.locality].where((e) => e != null && e.isNotEmpty).join(', ');

    _cityController.text = placemark.locality ?? placemark.subAdministrativeArea ?? '';
    _pinCodeController.text = placemark.postalCode ?? '';
    _stateController.text = placemark.administrativeArea ?? '';
  }

  Future<void> _saveAddress() async {
    setState(() => _errorMessage = '');

    if (!_isFromCurrentLocation) {
      setState(() {
        _errorMessage = 'Please select location on map or use GPS first.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final address = UserAddressModel(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        name: '${_tagController.text.trim()} (${_receiverNameController.text.trim()})',
        address: _addressController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: _phoneController.text.trim(),
        isDefault: false,
        latitude: _latitude!,
        longitude: _longitude!,
      );

      await ref.read(addressProvider.notifier).saveAddress(address);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Enter delivery details',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              /// Location Action Card
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.brandSeed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.brandSeed.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LocationActionTile(
                            icon: Icons.my_location_rounded,
                            label: _isFetchingLocation ? 'Fetching...' : 'Use GPS',
                            isLoading: _isFetchingLocation,
                            onTap: _fetchCurrentLocation,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _LocationActionTile(
                            icon: Icons.map_outlined,
                            label: 'Pick on Map',
                            onTap: _onPickLocation,
                          ),
                        ),
                      ],
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 14.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Location pinned successfully',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.successDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              Text(
                'RECEIVER DETAILS',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 16.h),

              _ModernField(
                label: 'Full Name',
                hint: 'e.g. John Doe',
                controller: _receiverNameController,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? 'Enter receiver name' : null,
              ),

              _ModernField(
                label: 'Mobile Number',
                hint: '10-digit number',
                controller: _phoneController,
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length != 10 ? 'Enter valid 10-digit number' : null,
              ),

              SizedBox(height: 24.h),

              Text(
                'ADDRESS DETAILS',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 16.h),

              _ModernField(
                label: 'House No. / Building / Area',
                hint: 'Complete address details',
                controller: _addressController,
                maxLines: 2,
                prefixIcon: Icons.home_work_outlined,
                validator: (v) => v!.isEmpty ? 'Enter address' : null,
              ),

              Row(
                children: [
                  Expanded(
                    child: _ModernField(
                      label: 'PIN Code',
                      hint: '6-digit',
                      controller: _pinCodeController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.length != 6 ? 'Invalid' : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _ModernField(
                      label: 'City',
                      hint: 'Your city',
                      controller: _cityController,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              _ModernField(
                label: 'State',
                hint: 'Your state',
                controller: _stateController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              SizedBox(height: 20.h),

              Text(
                'SAVE ADDRESS AS',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 12.h),

              Row(
                children: _tags.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTag = tag;
                            _tagController.text = tag;
                          });
                        }
                      },
                      selectedColor: AppColors.brandSeed.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.brandSeed : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13.sp,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(
                          color: isSelected ? AppColors.brandSeed : Colors.grey[300]!,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),

              if (_errorMessage.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 20.h),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 16.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: AppColors.error, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 32.h),

              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandSeed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isSaving
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 32.sp,
                        )
                      : Text(
                          'Save Address',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _LocationActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: AppLoader(strokeWidth: 2, color: AppColors.brandSeed),
                )
              else
                Icon(icon, color: AppColors.brandSeed, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandSeed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const _ModernField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400], fontWeight: FontWeight.normal),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20.sp, color: AppColors.brandSeed) : null,
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.brandSeed, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
