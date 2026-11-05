import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/data_push/catalog_seed_data.dart';
import 'package:sure_wholesaler/models/category_model.dart';
import '../constants/app_constants.dart';

class CategoryDataPush {
  final now = DateTime.now();

  int _categoryCount(String categoryDocId) {
    return CatalogSeedData.products
        .where((p) => p.categoryId == categoryDocId)
        .length;
  }

  int _subcategoryCount(String subCategoryDocId) {
    return CatalogSeedData.products
        .where((p) => p.subCategoryId == subCategoryDocId)
        .length;
  }

  CategoryModel _sub({
    required String docId,
    required String id,
    required String name,
    required String description,
    required String parentId,
    required String parentName,
    required int sortOrder,
    String imageUrl = '',
  }) =>
      CategoryModel(
        docId: docId,
        id: id,
        name: name,
        description: description,
        status: 'active',
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        productCount: _subcategoryCount(id),
        parentId: parentId,
        parentName: parentName,
        isStoryItem: false,
        createdAt: now,
        updatedAt: now,
        level: 1,
      );
  List<CategoryModel> get categories => [
        /// 1 — ELECTRONICS
        CategoryModel(
          docId: 'cat_electronics',
          id: 'electronics',
          name: 'Electronics',
          description: 'Latest gadgets, devices & accessories',
          status: 'active',
          imageUrl:
              'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400',
          sortOrder: 1,
          productCount: _categoryCount('cat_electronics'),
          parentId: null,
          parentName: null,
          isStoryItem: true,
          createdAt: now,
          updatedAt: now,
          level: 0,
          children: [
            _sub(
              docId: 'sub_mobiles',
              id: 'mobiles',
              name: 'Mobiles',
              description: 'Smartphones and accessories',
              parentId: 'cat_electronics',
              parentName: 'Electronics',
              sortOrder: 1,
              imageUrl:
                  'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300',
            ),
            _sub(
              docId: 'sub_laptops',
              id: 'laptops',
              name: 'Laptops',
              description: 'Work and gaming laptops',
              parentId: 'cat_electronics',
              parentName: 'Electronics',
              sortOrder: 2,
              imageUrl:
                  'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=300',
            ),
            _sub(
              docId: 'sub_accessories',
              id: 'accessories',
              name: 'Accessories',
              description: 'Chargers, headphones and more',
              parentId: 'cat_electronics',
              parentName: 'Electronics',
              sortOrder: 3,
              imageUrl:
                  'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=300',
            ),
            _sub(
              docId: 'sub_wearables',
              id: 'wearables',
              name: 'Wearables',
              description: 'Smart watches and wearable tech',
              parentId: 'cat_electronics',
              parentName: 'Electronics',
              sortOrder: 4,
              imageUrl:
                  'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300',
            ),
          ],
        ),

        /// 2 — FASHION
        CategoryModel(
          docId: 'cat_fashion',
          id: 'fashion',
          name: 'Fashion',
          description: 'Trendy clothes, shoes & accessories',
          status: 'active',
          imageUrl:
              'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400',
          sortOrder: 2,
          productCount: _categoryCount('cat_fashion'),
          parentId: null,
          parentName: null,
          isStoryItem: true,
          createdAt: now,
          updatedAt: now,
          level: 0,
          children: [
            _sub(
              docId: 'sub_men',
              id: 'men',
              name: 'Men',
              description: 'Men clothing and style',
              parentId: 'cat_fashion',
              parentName: 'Fashion',
              sortOrder: 1,
              imageUrl:
                  'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=300',
            ),
            _sub(
              docId: 'sub_women',
              id: 'women',
              name: 'Women',
              description: 'Women clothing collection',
              parentId: 'cat_fashion',
              parentName: 'Fashion',
              sortOrder: 2,
              imageUrl:
                  'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=300',
            ),
            _sub(
              docId: 'sub_footwear',
              id: 'footwear',
              name: 'Footwear',
              description: 'Shoes and sports footwear',
              parentId: 'cat_fashion',
              parentName: 'Fashion',
              sortOrder: 3,
              imageUrl:
                  'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300',
            ),
          ],
        ),

        /// 3 — HOME & LIVING
        CategoryModel(
          docId: 'cat_home',
          id: 'home',
          name: 'Home & Living',
          description: 'Furniture and home essentials',
          status: 'active',
          imageUrl:
              'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=400',
          sortOrder: 3,
          productCount: _categoryCount('cat_home'),
          parentId: null,
          parentName: null,
          isStoryItem: true,
          createdAt: now,
          updatedAt: now,
          level: 0,
          children: [
            _sub(
              docId: 'sub_furniture',
              id: 'furniture',
              name: 'Furniture',
              description: 'Sofas, tables and chairs',
              parentId: 'cat_home',
              parentName: 'Home & Living',
              sortOrder: 1,
              imageUrl:
                  'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=300',
            ),
            _sub(
              docId: 'sub_decor',
              id: 'decor',
              name: 'Decor',
              description: 'Home decoration items',
              parentId: 'cat_home',
              parentName: 'Home & Living',
              sortOrder: 2,
              imageUrl:
                  'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=300',
            ),
          ],
        ),

        /// 4 — BEAUTY
        CategoryModel(
          docId: 'cat_beauty',
          id: 'beauty',
          name: 'Beauty',
          description: 'Cosmetics and personal care',
          status: 'active',
          imageUrl:
              'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400',
          sortOrder: 4,
          productCount: _categoryCount('cat_beauty'),
          parentId: null,
          parentName: null,
          isStoryItem: true,
          createdAt: now,
          updatedAt: now,
          level: 0,
          children: [
            _sub(
              docId: 'sub_skincare',
              id: 'skincare',
              name: 'Skincare',
              description: 'Daily skincare and personal care',
              parentId: 'cat_beauty',
              parentName: 'Beauty',
              sortOrder: 1,
              imageUrl:
                  'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300',
            ),
          ],
        ),
      ];

  Future<void> pushCategories() async {
    final firestore = AppConfig.firestore;
    final batch = firestore.batch();

    await clearCategories();
    debugPrint('Pushing categories...');

    for (final category in categories) {
      if (category.docId.isEmpty) continue;

      final docRef =
          firestore.collection(Collections.categories).doc(category.docId);
      batch.set(docRef, {
        ...category.toFirestore(),
        'createdAt': Timestamp.fromDate(category.createdAt ?? now),
        'updatedAt': Timestamp.fromDate(category.updatedAt ?? now),
      });

      if (category.children != null) {
        for (final child in category.children!) {
          if (child.docId.isEmpty) continue;

          final childRef =
              firestore.collection(Collections.categories).doc(child.docId);
          batch.set(childRef, {
            ...child.toFirestore(),
            'createdAt': Timestamp.fromDate(child.createdAt ?? now),
            'updatedAt': Timestamp.fromDate(child.updatedAt ?? now),
          });
        }
      }
    }

    await batch.commit();
    debugPrint('Categories pushed successfully');
  }

  Future<void> clearCategories() async {
    final firestore = AppConfig.firestore;
    final snap = await firestore.collection(Collections.categories).get();

    const chunkSize = 400;
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final batch = firestore.batch();
      final end =
          (i + chunkSize > snap.docs.length) ? snap.docs.length : i + chunkSize;
      for (final doc in snap.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    debugPrint('Categories cleared');
  }
}
