import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';

abstract class CouponFirestoreDs {
  /// Read all coupons (real-time)
  Stream<List<CouponModel>> watchCoupons();

  /// Read multiple coupons by code list
  Stream<List<CouponModel>> watchCouponsByCode(List<String> codes);

  /// Read single coupon by code
  Stream<CouponModel?> watchCouponByCode(String code);

  /// Create a new coupon
  Future<String> createCoupon(CouponModel coupon);

  /// Update an existing coupon
  Future<void> updateCoupon(String couponId, Map<String, dynamic> data);

  /// Delete coupon (optional but useful)
  Future<void> deleteCoupon(String couponId);
}

class CouponFirestoreDsImpl implements CouponFirestoreDs {
  final FirebaseFirestore _firestore;
  final String _collection = Collections.coupon;

  CouponFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference<Map<String, dynamic>> get _couponCollection => _firestore.collection(_collection);

  CouponModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final map = <String, dynamic>{
      ...data,
      'id': doc.id,
    };
    if (!map.containsKey('code') || map['code'] == null || map['code'].toString().trim().isEmpty) {
      map['code'] = doc.id;
    }
    return CouponModel.fromMap(map);
  }

  /// ✅ REAL-TIME LIST
  @override
  Stream<List<CouponModel>> watchCoupons() {
    return _couponCollection.snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDoc).toList(),
        );
  }

  /// ✅ REAL-TIME SINGLE COUPON
  @override
  Stream<CouponModel?> watchCouponByCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    return _couponCollection.snapshots().map((snapshot) {
      for (final doc in snapshot.docs) {
        if (doc.id.trim().toUpperCase() == cleanCode) {
          return _fromDoc(doc);
        }
        final docCode = (doc.data()['code'] ?? '').toString().trim().toUpperCase();
        if (docCode == cleanCode) {
          return _fromDoc(doc);
        }
      }
      return null;
    });
  }

  /// ✅ CREATE (Future, not Stream)
  @override
  Future<String> createCoupon(CouponModel coupon) async {
    try {
      final docRef = await _couponCollection.add(coupon.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create coupon: $e');
    }
  }

  /// ✅ UPDATE
  @override
  Future<void> updateCoupon(String couponId, Map<String, dynamic> data) async {
    try {
      await _couponCollection.doc(couponId).update(data);
    } catch (e) {
      throw Exception('Failed to update coupon: $e');
    }
  }

  /// ✅ DELETE (important for admin)
  @override
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _couponCollection.doc(couponId).delete();
    } catch (e) {
      throw Exception('Failed to delete coupon: $e');
    }
  }

  @override
  Stream<List<CouponModel>> watchCouponsByCode(List<String> codes) {
    if (codes.isEmpty) return Stream.value([]);
    return _couponCollection.where('code', whereIn: codes).snapshots().map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }
}
