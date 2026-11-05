import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/app_constants.dart';
import '../../models/brand_model.dart';

class BrandDataPush {
  final FirebaseFirestore _firestore;

  BrandDataPush({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: AppConfig.databaseId,
            );

  // IDs must match _toBrandId() logic in CatalogSeedData
  final List<BrandModel> brands = [
    // ── Electronics ──
    _b(
      'brand_apple',
      'Apple',
      'Premium smartphones, laptops and accessories',
    ),

    _b(
      'brand_samsung',
      'Samsung',
      'Smartphones, TVs and electronic products',
    ),

    _b(
      'brand_sony',
      'Sony',
      'Audio, gaming and entertainment devices',
    ),

    _b(
      'brand_bose',
      'Bose',
      'Premium audio headphones and speakers',
    ),

    // ── Fashion ──
    _b(
      'brand_nike',
      'Nike',
      'Sportswear, shoes and lifestyle products',
    ),

    _b(
      'brand_adidas',
      'Adidas',
      'Sports shoes and apparel',
    ),

    _b(
      'brand_puma',
      'Puma',
      'Footwear and fashion accessories',
    ),

    _b(
      'brand_zara',
      'Zara',
      'Modern fashion and clothing',
    ),

    // ── Home & Living ──
    _b(
      'brand_ikea',
      'IKEA',
      'Furniture and home essentials',
    ),

    _b(
      'brand_dyson',
      'Dyson',
      'Home appliances and technology',
    ),

    // ── Beauty ──
    _b(
      'brand_loreal',
      'L\'Oreal',
      'Beauty and personal care products',
    ),

    _b(
      'brand_nivea',
      'Nivea',
      'Skin care and personal care products',
    ),

    // ── General Marketplace ──
    _b(
      'brand_amazon',
      'Amazon Basics',
      'Everyday essentials and accessories',
    ),

    _b(
      'brand_boat',
      'boAt',
      'Affordable audio and smart accessories',
    ),
  ];

  static BrandModel _b(String id, String name, String description) => BrandModel(
        id: id,
        name: name,
        description: description,
        isActive: true,
      );

  Future<void> pushBrands() async {
    await clearBrands();
    debugPrint('Pushing ${brands.length} brands...');

    const chunkSize = 400;
    for (var i = 0; i < brands.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = brands.sublist(
        i,
        (i + chunkSize > brands.length) ? brands.length : i + chunkSize,
      );
      for (final brand in chunk) {
        batch.set(
          _firestore.collection(Collections.brands).doc(brand.id),
          brand.toFirestore(),
        );
      }
      await batch.commit();
    }

    debugPrint('Brands pushed successfully (${brands.length})');
  }

  Future<void> clearBrands() async {
    debugPrint('Clearing brands...');
    final snapshot = await _firestore.collection(Collections.brands).get();
    if (snapshot.docs.isEmpty) return;

    const chunkSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      final end = (i + chunkSize > snapshot.docs.length) ? snapshot.docs.length : i + chunkSize;
      for (final doc in snapshot.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    debugPrint('Brands cleared');
  }
}
