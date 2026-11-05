import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import '../models/address_model.dart';
import '../notifiers/address_notifier.dart';
import 'AddNewAddressBottomSheet.dart';

class AddPincodeBottomSheet extends ConsumerStatefulWidget {
  const AddPincodeBottomSheet({super.key});

  @override
  ConsumerState<AddPincodeBottomSheet> createState() =>
      _AddPincodeBottomSheetState();
}

class _AddPincodeBottomSheetState extends ConsumerState<AddPincodeBottomSheet> {
  int _selectedAddressIndex = -1;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pinCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressesAsync = ref.watch(addressProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              /// OR divider

              /// Select address title
              Text(
                'Select an address',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 12.h),

              /// Address states
              addressesAsync.when(
                loading: () => SizedBox(
                  height: 150.h,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingAnimationWidget.staggeredDotsWave(
                          color: theme.colorScheme.primary,
                          size: 60.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading addresses...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Error loading addresses',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return SizedBox(
                      height: 150.h,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 64.sp,
                              color: theme.colorScheme.outline,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No addresses found',
                              style: theme.textTheme.titleMedium,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Add your first address below',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: addresses.asMap().entries.map((e) {
                      final index = e.key;
                      final address = e.value;
                      final isSelected = _selectedAddressIndex == index;

                      return _AddressTile(
                        address: address,
                        isSelected: isSelected,
                        width: (MediaQuery.of(context).size.width - 48.w) / 2,
                        onTap: () {
                          setState(() {
                            _selectedAddressIndex = index;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: 16.h),

              /// Add new address
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddNewAddressBottomSheet(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add a new address'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                ),
              ),

              SizedBox(height: 16.h),

              /// Done
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_pinCodeController.text.isNotEmpty ||
                          _selectedAddressIndex != -1) {
                        Navigator.pop(context);
                      } else {
                        AppNotifications.showError(
                          context,
                          title: 'Error',
                          message: 'Please enter PIN code or select an address',
                        );
                      }
                    }
                  },
                  child: const Text('Done'),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------- PIN FIELD ----------------
class _PinCodeField extends StatelessWidget {
  final TextEditingController controller;

  const _PinCodeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        hintText: 'Enter 6-digit PIN code',
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter PIN code';
        }
        if (value.length != 6) {
          return 'PIN code must be 6 digits';
        }
        return null;
      },
      style: theme.textTheme.bodyLarge,
    );
  }
}

/// ---------------- ADDRESS TILE ----------------
class _AddressTile extends StatelessWidget {
  final UserAddressModel address;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Material(
        color: isSelected
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  address.address,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  address.city,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  address.state,
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 8.h),
                Text(
                  address.phone,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
