import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:riverpod/src/framework.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/services/warehouse_service.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_models.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_service.dart';

import 'package:sure_wholesaler/firebase/order_firestore_ds.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/address_notifier.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/models/order_summary_args.dart';
import 'package:sure_wholesaler/repositories/order_repository.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_utils.dart';
import 'package:sure_wholesaler/widgets/AddNewAddressBottomSheet.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';
import 'package:sure_wholesaler/core/theme/app_theme.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

// ... imports stay the same

class CheckoutScreen extends ConsumerStatefulWidget {
  CheckoutScreen(
      {super.key,
      required this.products,
      required this.warehouseId,
      required this.deliveryType,
      required this.isSubscription});
  final List<ProductModel> products;
  final String? warehouseId;
  DeliveryType deliveryType;
  final bool isSubscription;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isFetchingLocation = false;
  UserAddressModel? _currentLocationAddress;
  int? _selectedAddressIndex = 0;
  RepeatSchedule? _selectedRepeatSchedule;
  double _warehouseRadiusKm = 15.0;

  Future<bool> isReachableAddress(
    UserAddressModel address,
  ) async {
    if (widget.warehouseId == null) {
      print('No warehouse ID provided, skipping reachability check');
      return true;
    }

    final warehouse = await ref
        .read(warehouseServiceProvider)
        .streamWarehouseById(widget.warehouseId!)
        .first;

    if (warehouse == null) return false;

    final allowedRadiusKm = widget.deliveryType == DeliveryType.scheduled
        ? warehouse.scheduledDeliveryRadius
        : warehouse.quickdeliveryRadiusKm;

    _warehouseRadiusKm = allowedRadiusKm;

    final distanceKm = await LocationUtils.distanceInKm(
      warehouse.latitude,
      warehouse.longitude,
      address.latitude,
      address.longitude,
    );
    print(
        ' this is the distance in km $distanceKm and allowed radius is $allowedRadiusKm');

    return (distanceKm ?? double.infinity) <= allowedRadiusKm;
  }

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
        timestamp: locationData.time != null
            ? DateTime.fromMillisecondsSinceEpoch(locationData.time!.toInt())
            : null,
      );

      // Convert to UserAddressModel using the new method
      setState(() {
        _currentLocationAddress = customLocationData.toUserAddressModel(
          userId: FirebaseAuth.instance.currentUser!.uid,
          name: 'Current Location',
        );
        _selectedAddressIndex = 0; // Auto-select the fetched location
      });
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          title: 'Error',
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

    ref.listen<AsyncValue<List<UserAddressModel>>>(addressProvider,
        (previous, next) {
      if (next.hasValue &&
          next.value?.isNotEmpty == true &&
          _selectedAddressIndex == null) {
        final addresses = next.value!;
        final defaultIndex = addresses.indexWhere((a) => a.isDefault);
        setState(() {
          _selectedAddressIndex = defaultIndex != -1 ? defaultIndex : 0;
        });
      }
    });

    return Scaffold(
      // Moved Button to bottom for better UX
      bottomNavigationBar: _buildBottomAction(addressesAsync),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text("Select Delivery Address"),
            centerTitle: true,
            floating: true,
          ),

          // 1. Current Location Trigger
          SliverToBoxAdapter(
            child: ListTile(
              leading: _isFetchingLocation
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const AppLoader(strokeWidth: 2))
                  : Icon(Icons.my_location_sharp,
                      color: theme.colorScheme.primary),
              title: Text("Use current Location",
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
              onTap: _isFetchingLocation ? null : _fetchUserLocation,
            ),
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                children: [
                  Text("Saved Addresses",
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
                  onTap: () {
                    setState(() {
                      _selectedAddressIndex = index;
                    });
                  },
                ),
                childCount: addresses.length,
              ),
            ),
            loading: () =>
                const SliverToBoxAdapter(child: Center(child: AppLoader())),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text("Error: $e"))),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // New: Schedule selection for subscriptions
          if (widget.isSubscription)
            SliverToBoxAdapter(
              child: _buildScheduleSelectionCard(context),
            ),
        ],
      ),
    );
  }

  bool _hasValidAddress(AsyncValue<List<UserAddressModel>> addressesAsync) {
    if (_selectedAddressIndex == -1) return _currentLocationAddress != null;
    if (_selectedAddressIndex == null) return false;
    final list = addressesAsync.value;

    final bool addressSelected =
        list != null && _selectedAddressIndex! < list.length;

    if (widget.isSubscription) {
      return addressSelected && _selectedRepeatSchedule != null;
    }
    return addressSelected;
  }

  Widget _buildBottomAction(AsyncValue<List<UserAddressModel>> addressesAsync) {
    final scheme = Theme.of(context).colorScheme;
    final canProceed = _hasValidAddress(addressesAsync);
    final user = ref.watch(userProvider).value;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.transparent),
      child: ElevatedButton(
        onPressed:
            canProceed ? () => _handleCheckout(addressesAsync, user!) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        child: Text(
          "Continue to Summary",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _handleCheckout(
      AsyncValue<List<UserAddressModel>> addressesAsync, UserModel user) async {
    UserAddressModel? selectedAddress;

    if (_selectedAddressIndex == -1) {
      selectedAddress = _currentLocationAddress;
    } else if (_selectedAddressIndex != null && _selectedAddressIndex! >= 0) {
      final list = addressesAsync.value;
      if (list != null && _selectedAddressIndex! < list.length) {
        selectedAddress = list[_selectedAddressIndex!];
      }
    }

    if (selectedAddress == null || user == null) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please select a delivery address',
      );
      return;
    }

    // New: Check for selected schedule if it's a subscription
    if (widget.isSubscription && _selectedRepeatSchedule == null) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please select a repeat schedule',
      );
      return;
    }

    final reachable = await isReachableAddress(selectedAddress);
    // if (!reachable) {
    //   if (mounted) {
    //     print(
    //         'Address ${selectedAddress.address} is outside the delivery range of $_warehouseRadiusKm km.');
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(
    //           'This address is outside our ${_warehouseRadiusKm.toInt()} km delivery range.',
    //         ),
    //         backgroundColor: Theme.of(context).colorScheme.error,
    //       ),
    //     );
    //   }
    //   return;
    // }

    if (mounted) {
      context.pushNamed(
        RouteNames.orderSummaryScreen,
        extra: OrderSummaryArgs(
          products: widget.products,
          deliveryAddress:
              FullDeliveryAddress(address: selectedAddress, user: user),
          deliveryType: widget.deliveryType,
          isSubscription: widget.isSubscription,
          warehouseId: widget.warehouseId,
          repeatSchedule: _selectedRepeatSchedule, // Pass the selected schedule
        ),
      );
    }
  }

  void _openAddAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (context) => const AddNewAddressBottomSheet(),
    );
  }

  // New: Widget to display and select subscription schedule
  Widget _buildScheduleSelectionCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String summaryText;
    if (_selectedRepeatSchedule == null) {
      summaryText = 'Tap to select a repeat schedule';
    } else {
      summaryText = _selectedRepeatSchedule!.displayString;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: InkWell(
        onTap: _navigateToScheduleScreen,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(Icons.repeat, color: scheme.primary, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Schedule',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      summaryText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _selectedRepeatSchedule == null
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToScheduleScreen() async {
    final result = await context.pushNamed(
      RouteNames.selectRepeatSchedule,
      extra: _selectedRepeatSchedule, // Pass current selection as initial
    );
    if (result is RepeatSchedule) {
      setState(() => _selectedRepeatSchedule = result);
    }
  }
}

Widget _buildProductCard(ProductModel product) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(
          color: AppColors.colorBlack,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Product Image Placeholder
        Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
              errorBuilder: (c, e, s) =>
                  Icon(Icons.inventory_2, color: AppColors.textDisabled),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                "Unit Price: ${product.formattedPrice} / Pack of ${product.defaultPackVariant.packSize}",
                style:
                    TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              product.formattedPrice,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ],
        ),
      ],
    ),
  );
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
          padding: EdgeInsets.all(8.w),
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
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                      "${address.address}, ${address.locality}, ${address.city}, ${address.state} - ${address.pinCode}",
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                    if (address.phone.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 14.sp, color: scheme.onSurfaceVariant),
                          SizedBox(width: 4.w),
                          Text(
                            address.phone,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
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
