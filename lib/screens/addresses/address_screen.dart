import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_models.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_service.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/notifiers/address_notifier.dart';
import 'package:sure_wholesaler/widgets/AddNewAddressBottomSheet.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

// ... imports stay the same

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({
    super.key,
  });

  @override
  ConsumerState<AddressScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<AddressScreen> {
  bool _isFetchingLocation = false;
  UserAddressModel? _currentLocationAddress; // Store fetched location
  int? _selectedAddressIndex = 0; // 0+ for saved, -1 for current location

  @override
  void initState() {
    super.initState();
    final addressesState = ref.read(addressProvider);
    if (addressesState.hasValue && addressesState.value?.isNotEmpty == true) {
      final addresses = addressesState.value!;
      final defaultIndex = addresses.indexWhere((a) => a.isDefault);
      _selectedAddressIndex = defaultIndex != -1 ? defaultIndex : 0;
    }
  }

  Future<void> _fetchUserLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final locationData = await LocationService.getCurrentLocation();
      final placemark = await LocationService.getFullAddress(
        locationData.latitude!,
        locationData.longitude!,
      );

      // Create LocationData from GPS and geocoding results
      final customLocationData = LocationData(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        address: placemark.street ?? placemark.name ?? '',
        city: placemark.locality ?? placemark.subAdministrativeArea ?? '',
        state: placemark.administrativeArea ?? '',
        country: placemark.country ?? 'India',
        postalCode: placemark.postalCode ?? '',
        accuracy: locationData.accuracy,
        altitude: locationData.altitude,
        speed: locationData.speed,
        heading: locationData.heading,
        timestamp: locationData.time != null ? DateTime.fromMillisecondsSinceEpoch(locationData.time!.toInt()) : null,
      );

      // Convert to UserAddressModel using the new method
      setState(() {
        _currentLocationAddress = customLocationData.toUserAddressModel(
          userId: FirebaseAuth.instance.currentUser!.uid,
          name: 'Current Location',
        );
        _selectedAddressIndex = -1; // Auto-select the fetched location
      });
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          title: 'Location Error',
          message: 'Failed to get location: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<List<UserAddressModel>>>(addressProvider, (previous, next) {
      if (next.hasValue && next.value?.isNotEmpty == true && _selectedAddressIndex == null) {
        final addresses = next.value!;
        final defaultIndex = addresses.indexWhere((a) => a.isDefault);
        setState(() {
          _selectedAddressIndex = defaultIndex != -1 ? defaultIndex : 0;
        });
      }
    });

    return Scaffold(
      // Moved Button to bottom for better UX
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text("Checkout"),
            // actions: [
            //   IconButton(
            //     onPressed: () async {
            //       await context.push(AppRoutes.addressOnMap);
            //     },
            //     icon: const Icon(Icons.add_location_alt_outlined),
            //     tooltip: 'Add New Address',
            //   ),
            // ],
            centerTitle: true,
            floating: true,
          ),

          // 1. Current Location Trigger
          SliverToBoxAdapter(
            child: ListTile(
              leading: _isFetchingLocation
                  ? SizedBox(width: 20.w, height: 20.w, child: const AppLoader(strokeWidth: 2))
                  : Icon(Icons.my_location_sharp, color: theme.colorScheme.primary),
              title: Text("Use current Location", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
              onTap: _isFetchingLocation ? null : _fetchUserLocation,
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(height: 1),
          ),

          // 2. Fetched Location Display (if exists)
          if (_currentLocationAddress != null)
            SliverToBoxAdapter(
              child: _AddressTile(
                address: _currentLocationAddress!,
                index: -1,
                selectedIndex: _selectedAddressIndex ?? -2,
                onTap: () => setState(() => _selectedAddressIndex = -1),
              ),
            ),

          // 3. Saved Addresses Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Text("Saved Addresses", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openAddAddressSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Add New"),
                  ),
                ],
              ),
            ),
          ),

          // 4. Saved Addresses List
          addressesAsync.when(
            data: (addresses) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _AddressTile(
                  address: addresses[index],
                  index: index,
                  selectedIndex: _selectedAddressIndex ?? -2,
                  onTap: () => setState(() => _selectedAddressIndex = index),
                ),
                childCount: addresses.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: AppLoader())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text("Error: $e"))),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        ],
      ),
    );
  }

  void _openAddAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (context) => const AddNewAddressBottomSheet(),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  final UserAddressModel address;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = index == selectedIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? scheme.surface : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: isSelected ? scheme.primary : AppColors.transparentColor,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        _buildBadge(
                          context,
                          index == -1 ? "GPS" : "Saved",
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "${address.address}, ${address.locality}",
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                    Text(
                      "${address.city}, ${address.state} - ${address.pinCode}",
                      style: theme.textTheme.bodySmall,
                    ),
                    if (address.phone.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14.sp, color: scheme.onSurfaceVariant),
                          SizedBox(width: 4.w),
                          Text(
                            address.phone,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
