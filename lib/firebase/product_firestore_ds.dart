import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';

abstract class ProductFirestoreDs {
  Stream<List<Map<String, dynamic>>> getProducts();
  Stream<Map<String, dynamic>?> getProductById(String productId);
  Stream<List<Map<String, dynamic>>> getProductsByCategory(String categoryId);
  Stream<List<Map<String, dynamic>>> getProductsBySubcategory(String categoryId, String subcategoryId);
  Stream<List<Map<String, dynamic>>> getProductsByCategories(List<String> categoryIds);
  Stream<List<Map<String, dynamic>>> getProductsWhere({required String field, required dynamic value});
  Stream<List<Map<String, dynamic>>> getActiveProducts();
  Stream<List<Map<String, dynamic>>> getProductsWithFilters({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasOffer,
    String? sortBy,
    bool descending = false,
  });
  Stream<List<Map<String, dynamic>>> searchProducts(String query);
  Stream<List<Map<String, dynamic>>> getProductsPaginated({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? categoryId,
  });
  Stream<List<Map<String, dynamic>>> getLowStockProducts();
  Stream<List<Map<String, dynamic>>> getProductsWithOffers();
  Stream<List<Map<String, dynamic>>> watchProducts();
  Stream<Map<String, dynamic>?> watchProductById(String productId);
  Stream<List<Map<String, dynamic>>> watchProductsByCategory(String categoryId);
  Stream<List<Map<String, dynamic>>> watchProductsBySubcategory(String categoryId, String subcategoryId);
  Future<void> updateStock(String productId, int newStock);
  Future<void> incrementStock(String productId, int delta);
  Stream<List<Map<String, dynamic>>> watchProductsByBrand(String brandId);
  Stream<List<Map<String, dynamic>>> watchProductsByCategories(List<String> categoryIds);
}

class ProductFirestoreDsImpl implements ProductFirestoreDs {
  final FirebaseFirestore _firestore;
  final String _collectionName = Collections.products;

  ProductFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _productCollection => _firestore.collection(_collectionName);

  @override
  Stream<List<Map<String, dynamic>>> getProducts() {
    return _productCollection.orderBy('name').snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Stream<Map<String, dynamic>?> getProductById(String productId) async* {
    final doc = await _productCollection.doc(productId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      yield data;
    } else {
      yield null;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) {
    return _productCollection.where('categoryId', isEqualTo: categoryId).where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsBySubcategory(String categoryId, String subcategoryId) async* {
    final snapshot = await _productCollection
        .where('categoryId', isEqualTo: categoryId)
        .where('subCategoryId', isEqualTo: subcategoryId)
        .where('isActive', isEqualTo: true)
        .get();
    yield snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsByCategories(List<String> categoryIds) async* {
    if (categoryIds.isEmpty) {
      yield [];
      return;
    }
    Query query = _productCollection.where('isActive', isEqualTo: true);

    if (categoryIds.length == 1) {
      query = query.where('categoryId', isEqualTo: categoryIds[0]);
    } else {
      query = query.where('categoryId', whereIn: categoryIds);
    }

    final snapshot = await query.get();
    yield snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsWhere({required String field, required dynamic value}) async* {
    final snapshot = await _productCollection.where(field, isEqualTo: value).get();
    yield snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> getActiveProducts() async* {
    yield* getProductsWhere(field: 'isActive', value: true);
  }

  double? _extractPrice(Map<String, dynamic> data) {
    return (data['price'] as num?)?.toDouble();
  }

  int _extractStock(Map<String, dynamic> data) {
    return (data['currentStock'] as num?)?.toInt() ?? 0;
  }

  int _extractMinStockAlert(Map<String, dynamic> data) {
    return (data['minStockAlert'] as num?)?.toInt() ?? 0;
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsWithFilters({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasOffer,
    String? sortBy,
    bool descending = false,
  }) async* {
    Query query = _productCollection.where('isActive', isEqualTo: true);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (hasOffer == true) {
      query = query.where('offerType', isNull: false);
    }

    if (sortBy != null) {
      query = query.orderBy(sortBy, descending: descending);
    } else {
      query = query.orderBy('name');
    }

    final snapshot = await query.get();
    var results = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      return data;
    }).toList();

    if (minPrice != null || maxPrice != null || inStock == true) {
      results = results.where((data) {
        final price = _extractPrice(data);
        if (minPrice != null && (price == null || price < minPrice)) {
          return false;
        }
        if (maxPrice != null && (price == null || price > maxPrice)) {
          return false;
        }
        if (inStock == true && _extractStock(data) <= 0) {
          return false;
        }
        return true;
      }).toList();
    }

    yield results;
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsWithOffers() async* {
    final snapshot = await _productCollection.where('isActive', isEqualTo: true).where('offerType', isNull: false).get();
    yield snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> searchProducts(String query) {
    if (query.isEmpty) return Stream.value([]);

    return _productCollection
        .where('isActive', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsPaginated({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? categoryId,
  }) async* {
    // Use orderBy('name') alone (single-field auto-index) and filter isActive
    // client-side to avoid requiring a composite Firestore index.
    Query query = categoryId != null
        ? _productCollection.where('categoryId', isEqualTo: categoryId).orderBy('name').limit(limit)
        : _productCollection.orderBy('name').limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    final activeDocs = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isActive'] == true;
    }).toList();

    if (kDebugMode) {
      debugPrint('getProductsPaginated: ${activeDocs.length} active products');
    }

    yield activeDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['_documentSnapshot'] = doc;
      return data;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> getLowStockProducts() {
    return _productCollection.where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).where((data) {
        final stock = _extractStock(data);
        final min = _extractMinStockAlert(data);
        return stock <= min;
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchProducts() {
    return _productCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Stream<Map<String, dynamic>?> watchProductById(String productId) {
    return _productCollection.doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }
      return null;
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchProductsByCategory(String categoryId) {
    return _productCollection.where('categoryId', isEqualTo: categoryId).where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchProductsBySubcategory(String categoryId, String subcategoryId) {
    // According to Web Developer approach:
    // 1. Products only have 'categoryId' field.
    // 2. This field contains the ID of the specific category/subcategory selected.
    // So we just need to match the subcategoryId against the 'categoryId' field.
    return _productCollection.where('categoryId', isEqualTo: subcategoryId).where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Future<void> updateStock(String productId, int newStock) async {
    final snap = await _firestore
        .collection(Collections.variants)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.update({'stock': newStock});
  }

  @override
  Future<void> incrementStock(String productId, int delta) async {
    final snap = await _firestore
        .collection(Collections.variants)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.update({'stock': FieldValue.increment(delta)});
  }

  @override
  Stream<List<Map<String, dynamic>>> watchProductsByBrand(String brandId) {
    return _productCollection.where('brandId', isEqualTo: brandId).where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchProductsByCategories(List<String> categoryIds) {
    if (categoryIds.isEmpty) return Stream.value([]);
    return _productCollection.where('categoryId', whereIn: categoryIds).where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['_documentSnapshot'] = doc;
        return data;
      }).toList();
    });
  }
}
