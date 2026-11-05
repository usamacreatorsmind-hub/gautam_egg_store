import 'package:sure_wholesaler/firebase/coupen_firestore_ds.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';

abstract class CouponRepository {
  Stream<List<CouponModel>> watchCoupons();
  Stream<List<CouponModel>> watchCouponsByCode(List<String> codes);
  Stream<CouponModel?> watchCouponByCode(String code);
  Future<String> createCoupon(CouponModel coupon);
  Future<void> updateCoupon(String couponId, Map<String, dynamic> data);
  Future<void> deleteCoupon(String couponId);
}

class CouponRepositoryImpl implements CouponRepository {
  final CouponFirestoreDs _ds;

  CouponRepositoryImpl(this._ds);

  @override
  Stream<List<CouponModel>> watchCoupons() => _ds.watchCoupons();

  @override
  Stream<List<CouponModel>> watchCouponsByCode(List<String> codes) =>
      _ds.watchCouponsByCode(codes);

  @override
  Stream<CouponModel?> watchCouponByCode(String code) =>
      _ds.watchCouponByCode(code);

  @override
  Future<String> createCoupon(CouponModel coupon) => _ds.createCoupon(coupon);

  @override
  Future<void> updateCoupon(String couponId, Map<String, dynamic> data) =>
      _ds.updateCoupon(couponId, data);

  @override
  Future<void> deleteCoupon(String couponId) => _ds.deleteCoupon(couponId);
}
