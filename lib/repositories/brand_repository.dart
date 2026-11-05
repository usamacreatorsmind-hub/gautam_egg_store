import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/brand_model.dart';

abstract class BrandRepository {
  Future<List<BrandModel>> getAllBrands();
  Future<BrandModel?> getBrandById(String brandId);
  Future<void> addBrand(BrandModel brand);
  Future<void> updateBrand(
    String brandId,
    Map<String, dynamic> data,
  );

  Future<void> deactivateBrand(String brandId);
  Future<void> deleteBrand(String brandId);

  Stream<List<BrandModel>> watchBrands();
}

class BrandRepositoryImpl extends BrandRepository {
  final FirebaseFirestore _firestore;

  BrandRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  static const _collection = 'brands';

  /// 🔹 Get all active brands
  @override
  Future<List<BrandModel>> getAllBrands() async {
    final snapshot = await _firestore.collection(_collection).where('isActive', isEqualTo: true).orderBy('name').get();

    return snapshot.docs
        .map((doc) {
          try {
            return BrandModel.fromFirestore(doc);
          } catch (_) {
            return null;
          }
        })
        .whereType<BrandModel>()
        .toList();
  }

  /// 🔹 Get brand by ID
  @override
  Future<BrandModel?> getBrandById(String brandId) async {
    final doc = await _firestore.collection(_collection).doc(brandId).get();

    if (!doc.exists) return null;
    return BrandModel.fromFirestore(doc);
  }

  /// 🔹 Add new brand
  @override
  Future<void> addBrand(BrandModel brand) async {
    await _firestore.collection(_collection).add(brand.toFirestore());
  }

  /// 🔹 Update brand
  @override
  Future<void> updateBrand(
    String brandId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(_collection).doc(brandId).update(data);
  }

  /// 🔹 Soft delete (recommended)
  @override
  Future<void> deactivateBrand(String brandId) async {
    await _firestore.collection(_collection).doc(brandId).update({'isActive': false});
  }

  /// 🔹 Hard delete (use carefully)
  @override
  Future<void> deleteBrand(String brandId) async {
    await _firestore.collection(_collection).doc(brandId).delete();
  }

  /// 🔹 Stream brands (real-time UI)
  @override
  Stream<List<BrandModel>> watchBrands() {
    return _firestore.collection(_collection).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return BrandModel.fromFirestore(doc);
              } catch (e) {
                debugPrint('Error parsing brand ${doc.id}: $e');
                return null;
              }
            })
            .whereType<BrandModel>()
            .toList();
      },
    );
  }
}
