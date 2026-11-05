import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/notifiers/coupon_notifier.dart';
import 'package:sure_wholesaler/screens/offer/coupon_card_widget.dart';

class OfferScreen extends ConsumerWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final couponAsync = ref.watch(couponsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers & Coupons'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(couponsStreamProvider.future),
        child: couponAsync.when(
          loading: () => Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: scheme.primary,
              size: 50.sp,
            ),
          ),
          error: (e, stack) {
            debugPrint("Error loading coupons: $e\n$stack");
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48.sp, color: scheme.error),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load offers',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please check your internet connection or try again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.sp),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(couponsStreamProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (coupons) {
            if (coupons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_offer_outlined, size: 60.sp, color: scheme.primary.withValues(alpha: 0.5)),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'No offer available yet',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Text(
                        'Check back later for exciting discounts and deals!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              itemCount: coupons.length,
              itemBuilder: (context, index) => CouponCardWidget(
                coupon: coupons[index],
              ),
            );
          },
        ),
      ),
    );
  }
}
