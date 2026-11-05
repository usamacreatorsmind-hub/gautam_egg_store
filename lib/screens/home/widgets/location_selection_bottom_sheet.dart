import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/notifiers/address_notifier.dart';
import 'package:sure_wholesaler/utils/locationProviders.dart' as loc;
import 'package:sure_wholesaler/widgets/AddNewAddressBottomSheet.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class LocationSelectionBottomSheet extends ConsumerWidget {
  const LocationSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.8.sh),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Text(
              "Select delivery location",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
          
          // Current Location
          ListTile(
            onTap: () {
              ref.read(loc.manualLocationProvider.notifier).state = null;
              ref.invalidate(loc.currentLocationProvider);
              Navigator.pop(context);
            },
            leading: Icon(Icons.my_location, color: AppColors.brandSeed, size: 22.sp),
            title: Text(
              "Use current location",
              style: TextStyle(
                color: AppColors.brandSeed,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Text(
              "Using GPS",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ),
          
          const Divider(),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Text(
              "SAVED ADDRESSES",
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.grey[500],
              ),
            ),
          ),

          Flexible(
            child: addressesAsync.when(
              data: (addresses) {
                if (addresses.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Center(
                      child: Text(
                        "No saved addresses",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _LocationTile(
                      address: address,
                      onTap: () {
                        ref.read(loc.manualLocationProvider.notifier).state = 
                            address.toLocationData();
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: AppLoader()),
              ),
              error: (e, _) => Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text("Error loading addresses")),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: OutlinedButton.icon(
                onPressed: () {
                   Navigator.pop(context);
                   showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddNewAddressBottomSheet(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Add new address"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandSeed,
                  side: const BorderSide(color: AppColors.brandSeed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final UserAddressModel address;
  final VoidCallback onTap;

  const _LocationTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.home_outlined, color: Colors.grey[600], size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    address.fullAddress(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
