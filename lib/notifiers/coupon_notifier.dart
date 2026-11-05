import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/firebase/coupen_firestore_ds.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';
import 'package:sure_wholesaler/repositories/coupon_repository.dart';

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepositoryImpl(CouponFirestoreDsImpl());
});

final couponsStreamProvider = StreamProvider<List<CouponModel>>((ref) {
  return ref.watch(couponRepositoryProvider).watchCoupons();
});

final couponsByCodesProvider =
    StreamProvider.family<List<CouponModel>, List<String>>((ref, codes) {
  return ref.watch(couponRepositoryProvider).watchCouponsByCode(codes);
});

final couponByCodeProvider =
    StreamProvider.family<CouponModel?, String>((ref, code) {
  return ref.watch(couponRepositoryProvider).watchCouponByCode(code);
});

final activeCouponsProvider = Provider<List<CouponModel>>((ref) {
  return ref.watch(couponsStreamProvider).maybeWhen(
        data: (coupons) => coupons
            .where((c) => c.isActive && !c.isExpired && !c.isUsageExceeded)
            .toList(),
        orElse: () => [],
      );
});

final validateCouponProvider =
    Provider.family<CouponModel?, ({String code, double amount})>(
        (ref, params) {
  return ref.watch(couponsStreamProvider).maybeWhen(
        data: (coupons) {
          try {
            final coupon = coupons.firstWhere(
              (c) => c.code.toUpperCase() == params.code.toUpperCase(),
            );
            return coupon.canApply(params.amount) ? coupon : null;
          } catch (_) {
            return null;
          }
        },
        orElse: () => null,
      );
});

class AppliedCouponNotifier extends Notifier<CouponModel?> {
  @override
  CouponModel? build() => null;

  void apply(CouponModel coupon) => state = coupon;
  void remove() => state = null;
}

final appliedCouponProvider =
    NotifierProvider<AppliedCouponNotifier, CouponModel?>(
  AppliedCouponNotifier.new,
);

final applyCouponProvider = Provider((ref) {
  return (String code, double amount) {
    final coupon = ref.read(
      validateCouponProvider((code: code, amount: amount)),
    );
    if (coupon != null) {
      ref.read(appliedCouponProvider.notifier).apply(coupon);
      return true;
    }
    return false;
  };
});

final removeCouponProvider = Provider((ref) {
  return () => ref.read(appliedCouponProvider.notifier).remove();
});

final discountProvider = Provider.family<double, double>((ref, amount) {
  final coupon = ref.watch(appliedCouponProvider);
  if (coupon == null) return 0;
  return coupon.calculateDiscount(amount);
});

final finalAmountProvider = Provider.family<double, double>((ref, amount) {
  final discount = ref.watch(discountProvider(amount));
  return amount - discount;
});
