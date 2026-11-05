import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:sure_wholesaler/notifiers/address_notifier.dart';
import 'package:sure_wholesaler/widgets/AddNewAddressBottomSheet.dart';

class MyAddressesLeftSheet extends ConsumerStatefulWidget {
  const MyAddressesLeftSheet({super.key});

  @override
  ConsumerState<MyAddressesLeftSheet> createState() =>
      _MyAddressesLeftSheetState();
}

class _MyAddressesLeftSheetState extends ConsumerState<MyAddressesLeftSheet> {
  int _selectedAddressIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressesAsync = ref.watch(addressProvider);

    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.r),
            bottomRight: Radius.circular(20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        size: 24.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Select Address',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),

              Divider(color: theme.colorScheme.outlineVariant),
              SizedBox(height: 16.h),

              /// Address list
              addressesAsync.when(
                loading: () => Expanded(
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
                error: (error, _) => Expanded(
                  child: Center(
                    child: Text(
                      'Error loading addresses',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                data: (addresses) {
                  if (addresses.isNotEmpty && _selectedAddressIndex == 0) {
                    final defaultIndex =
                        addresses.indexWhere((a) => a.isDefault);
                    if (defaultIndex != -1) {
                      _selectedAddressIndex = defaultIndex;
                    }
                  }

                  if (addresses.isEmpty) {
                    return Expanded(
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

                  return Expanded(
                    child: ListView.builder(
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        final isSelected = _selectedAddressIndex == index;

                        return Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAddressIndex = index;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _selectedAddressIndex,
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedAddressIndex = v!;
                                    });
                                  },
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              address.name,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          ),
                                          if (address.isDefault)
                                            _Tag(
                                              text: 'DEFAULT',
                                              background: theme
                                                  .colorScheme.primaryContainer,
                                              foreground: theme.colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          if (isSelected && !address.isDefault)
                                            _Tag(
                                              text: 'SELECTED',
                                              background: theme.colorScheme
                                                  .secondaryContainer,
                                              foreground: theme.colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        address.address,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${address.city} - ${address.pinCode}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      Text(
                                        address.state,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 14.sp,
                                            color: theme.colorScheme.outline,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            address.phone,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!address.isDefault)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              ref
                                                  .read(
                                                      addressProvider.notifier)
                                                  .deleteAddress(address.id!);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              SizedBox(height: 16.h),

              /// Add new address
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.transparentColor,
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

              /// Done button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),

              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small label/tag widget
class _Tag extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
