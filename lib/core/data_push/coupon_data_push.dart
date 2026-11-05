import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';
import '../constants/app_constants.dart';

class CouponDataPush {
  final List<CouponModel> coupons = <CouponModel>[
    CouponModel(
      code: 'WELCOME50',
      type: CouponType.percentage,
      value: 50,
      maxDiscount: 100,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      activeDate: DateTime.now(),
      minOrder: 200,
      maxUsage: 1000,
      usedCount: 0,
      isActive: true,
      applyOn: ApplyOn.allProducts,
      maxUsagePerUser: 1,
    ),
    CouponModel(
      code: 'FLAT100',
      type: CouponType.flat,
      value: 100,
      expiryDate: DateTime.now().add(const Duration(days: 15)),
      activeDate: DateTime.now(),
      minOrder: 1000,
      maxUsage: 500,
      usedCount: 0,
      isActive: true,
      applyOn: ApplyOn.allProducts,
      maxUsagePerUser: 1,
    ),
    CouponModel(
      code: 'BOGOEGGS',
      type: CouponType.bogo,
      buyQty: 1,
      getQty: 1,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      activeDate: DateTime.now(),
      minOrder: 0,
      maxUsage: 200,
      usedCount: 0,
      isActive: true,
      applyOn: ApplyOn.products,
      applicableProducts: ['p2'],
      maxUsagePerUser: 2,
    ),
    CouponModel(
      code: 'VEGFRESH10',
      type: CouponType.percentage,
      value: 10,
      maxDiscount: 80,
      expiryDate: DateTime.now().add(const Duration(days: 60)),
      activeDate: DateTime.now(),
      minOrder: 300,
      maxUsage: 1000,
      usedCount: 0,
      isActive: true,
      applyOn: ApplyOn.category,
      applicableCategory: 'cat_fruits_veg',
      maxUsagePerUser: 3,
    ),
    CouponModel(
      code: 'SUBSAVE15',
      type: CouponType.subscription,
      value: 15,
      maxDiscount: 120,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      activeDate: DateTime.now(),
      minOrder: 400,
      maxUsage: 800,
      usedCount: 0,
      isActive: true,
      applyOn: ApplyOn.products,
      applicableProducts: ['p1', 'p6'],
      maxUsagePerUser: 2,
    ),
  ];

// push couped data
  Future<void> pushCoupons() async {
    await clearCoupons();

    debugPrint("Pushing coupons...");
    await Future.wait(
      coupons.map((coupon) async {
        debugPrint('Pushing coupon: ${coupon.code}');
        await AppConfig.firestore
            .collection(Collections.coupon)
            .doc(coupon.code)
            .set(coupon.toMap());
      }),
    );
    debugPrint("Coupons pushed");
  }

  /// Wipes all documents in the coupons collection.
  /// Use only in dev/testing — NOT in production.
  Future<void> clearCoupons() async {
    final firestore = AppConfig.firestore;
    final snap = await firestore.collection(Collections.coupon).get();

    const chunkSize = 400;
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final batch = firestore.batch();
      final chunk = snap.docs.sublist(
        i,
        i + chunkSize > snap.docs.length ? snap.docs.length : i + chunkSize,
      );
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    debugPrint("Coupons cleared");
  }
}
