import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/firebase/product_firestore_ds.dart';
import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';

abstract class ProductRepository {
  Stream<List<ProductModel>> getProducts({List<String>? warehouseIds});
  Stream<ProductModel?> getProductById(String productId, {List<String>? warehouseIds});
  Stream<List<ProductModel>> getProductsByCategory(String categoryId, {List<String>? warehouseIds});
  Stream<List<ProductModel>> getProductsBySubcategory(String categoryId, String subcategoryId, {List<String>? warehouseIds});
  Stream<List<ProductModel>> getProductsByCategories(List<String> categoryIds, {List<String>? warehouseIds});
  Stream<List<ProductModel>> getProductsWhere({
    required String field,
    required dynamic value,
    List<String>? warehouseIds,
  });
  Stream<List<ProductModel>> getActiveProducts({List<String>? warehouseIds});
  Stream<List<ProductModel>> getProductsWithFilters({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasOffer,
    String? sortBy,
    bool descending = false,
    DeliveryType? deliveryType,
    List<String>? warehouseIds,
  });
  Stream<List<ProductModel>> searchProducts(String query, {List<String>? warehouseIds});
  Future<ProductPaginatedResult> getProductsPaginated({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? categoryId,
    DeliveryType? deliveryType,
    List<String>? warehouseIds,
  });
  Stream<List<ProductModel>> getLowStockProducts({List<String>? warehouseIds});
  Stream<List<ProductModel>> getProductsWithOffers({List<String>? warehouseIds});
  Stream<List<ProductModel>> watchProducts({List<String>? warehouseIds});
  Stream<ProductModel?> watchProductById(String productId, {List<String>? warehouseIds});
  Stream<List<ProductModel>> watchProductsByCategory(String categoryId, {List<String>? warehouseIds});
  Stream<List<ProductModel>> watchProductsByBrand(String brandId, {List<String>? warehouseIds});
  Stream<List<ProductModel>> watchProductsByCategories(List<String> categoryIds, {List<String>? warehouseIds});
  Stream<List<ProductModel>> watchProductsBySubcategory(String categoryId, String subcategoryId, {List<String>? warehouseIds});
  Future<void> updateStock(String productId, int newStock);
  Future<void> incrementStock(String productId, int delta);
  Stream<List<PackVariant>> getVariantsByProduct(String productId);
  Stream<List<PackVariant>> getVariantsByDeliveryType(String productId, DeliveryType deliveryType);
  Stream<List<PackVariant>> getVariantsByProductAndWarehouse(String productId, String warehouseId);
}

class ProductPaginatedResult {
  final List<ProductModel> products;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  ProductPaginatedResult({
    required this.products,
    this.lastDocument,
    required this.hasMore,
  });
}

class ProductRepositoryImpl implements ProductRepository {
  final ProductFirestoreDs _firestoreDs;
  final VariantFirestoreDs _variantDs;

  ProductRepositoryImpl(this._firestoreDs, this._variantDs);

  ProductModel _mapToModel(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final docSnapshot = data['_documentSnapshot'];
    data.remove('_documentSnapshot');

    if (docSnapshot is DocumentSnapshot<Map<String, dynamic>>) {
      return ProductModel.fromFirestore(docSnapshot);
    }

    return ProductModel.fromMap(data, id);
  }

  Future<List<ProductModel>> _attachVariants(List<ProductModel> products) async {
    return Future.wait(products.map((product) async {
      if (product.id == null) return product;

      if (product.packVariants.isNotEmpty) {
        return product;
      }

      try {
        final variants = await _variantDs.getVariantsByProduct(product.id!).first;
        if (variants.isEmpty) return product;
        return product.withVariants(variants);
      } catch (e) {
        return product;
      }
    }));
  }

  Future<List<ProductModel>> _attachVariantsForWarehouses(
    List<ProductModel> products,
    List<String>? warehouseIds,
  ) async {
    return _attachVariants(products);
  }

  List<ProductModel> _filterProductsForWarehouses(
    List<ProductModel> products,
    List<String>? warehouseIds,
  ) {
    return products;
  }

  @override
  Stream<List<ProductModel>> getProducts({List<String>? warehouseIds}) {
    return _firestoreDs.getProducts().asyncMap((data) async {
      final products = data.map(_mapToModel).toList();
      final resolvedProducts = await _attachVariantsForWarehouses(products, warehouseIds);
      return _filterProductsForWarehouses(resolvedProducts, warehouseIds);
    });
  }

  @override
  Stream<ProductModel?> getProductById(String productId, {List<String>? warehouseIds}) {
    return _firestoreDs.watchProductById(productId).asyncMap((data) async {
      if (data == null) return null;
      final product = _mapToModel(data);
      final products = await _attachVariantsForWarehouses([product], warehouseIds);
      return products.first;
    });
  }

  @override
  Stream<List<ProductModel>> getProductsByCategory(String categoryId, {List<String>? warehouseIds}) {
    return _firestoreDs.getProductsByCategory(categoryId).asyncMap((data) {
      final products = data.map(_mapToModel).toList();
      return _attachVariantsForWarehouses(products, warehouseIds).then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> getProductsBySubcategory(String categoryId, String subcategoryId, {List<String>? warehouseIds}) {
    return _firestoreDs.getProductsBySubcategory(categoryId, subcategoryId).asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> getProductsByCategories(List<String> categoryIds, {List<String>? warehouseIds}) {
    return _firestoreDs.getProductsByCategories(categoryIds).asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> getProductsWhere({
    required String field,
    required dynamic value,
    List<String>? warehouseIds,
  }) {
    return _firestoreDs.getProductsWhere(field: field, value: value).asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> getActiveProducts({List<String>? warehouseIds}) {
    return _firestoreDs.getActiveProducts().asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> getProductsWithFilters({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasOffer,
    String? sortBy,
    bool descending = false,
    DeliveryType? deliveryType,
    List<String>? warehouseIds,
  }) {
    return _firestoreDs
        .getProductsWithFilters(
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStock: inStock,
      hasOffer: hasOffer,
      sortBy: sortBy,
      descending: descending,
    )
        .asyncMap((data) async {
      List<ProductModel> products = await _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds);

      products = _filterProductsForWarehouses(products, warehouseIds);

      if (deliveryType != null) {
        products = products.where((p) => p.packVariants.any((v) => v.supports(deliveryType))).toList();
      }

      return products;
    });
  }

  @override
  Stream<List<ProductModel>> searchProducts(String query, {List<String>? warehouseIds}) {
    return _firestoreDs.searchProducts(query).asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Future<ProductPaginatedResult> getProductsPaginated({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? categoryId,
    DeliveryType? deliveryType,
    List<String>? warehouseIds,
  }) async {
    final dataList = await _firestoreDs
        .getProductsPaginated(
          limit: limit,
          lastDocument: lastDocument,
          categoryId: categoryId,
        )
        .first;

    DocumentSnapshot? lastDoc;
    if (dataList.isNotEmpty) {
      lastDoc = dataList.last['_documentSnapshot'] as DocumentSnapshot?;
    }

    final rawProducts = dataList.map(_mapToModel).toList();
    List<ProductModel> products = warehouseIds != null && warehouseIds.isNotEmpty
        ? await _attachVariantsForWarehouses(rawProducts, warehouseIds)
        : await _attachVariants(rawProducts);

    if (warehouseIds != null && warehouseIds.isNotEmpty) {
      final warehouseFiltered = products.where((p) => p.packVariants.any((v) => v.inventory != null)).toList();
      if (warehouseFiltered.isNotEmpty) products = warehouseFiltered;
    }

    if (deliveryType != null) {
      products = products.where((p) {
        if (p.packVariants.isEmpty) return true;
        final hasDeliveryConfig = p.packVariants.any((v) => v.availableDeliveryTypes.isNotEmpty);
        if (!hasDeliveryConfig) return true;
        return p.packVariants.any((v) => v.supports(deliveryType));
      }).toList();
    }

    return ProductPaginatedResult(
      products: products,
      lastDocument: lastDoc,
      hasMore: dataList.length >= limit,
    );
  }

  @override
  Stream<List<ProductModel>> getLowStockProducts({List<String>? warehouseIds}) {
    return _firestoreDs.getLowStockProducts().asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> getProductsWithOffers({List<String>? warehouseIds}) {
    return _firestoreDs.getProductsWithOffers().asyncMap((data) {
      return _attachVariantsForWarehouses(data.map(_mapToModel).toList(), warehouseIds)
          .then((value) => _filterProductsForWarehouses(value, warehouseIds));
    });
  }

  @override
  Stream<List<ProductModel>> watchProducts({List<String>? warehouseIds}) {
    return _firestoreDs.watchProducts().asyncMap(
          (dataList) => _attachVariantsForWarehouses(
            dataList.map(_mapToModel).toList(),
            warehouseIds,
          ).then((value) => _filterProductsForWarehouses(value, warehouseIds)),
        );
  }

  @override
  Stream<ProductModel?> watchProductById(String productId, {List<String>? warehouseIds}) {
    return _firestoreDs.watchProductById(productId).asyncMap((data) async {
      if (data == null) return null;
      final products = await _attachVariantsForWarehouses([_mapToModel(data)], warehouseIds);
      return products.first;
    });
  }

  @override
  Stream<List<ProductModel>> watchProductsByCategory(String categoryId, {List<String>? warehouseIds}) {
    return _firestoreDs.watchProductsByCategory(categoryId).asyncMap(
          (dataList) => _attachVariantsForWarehouses(
            dataList.map(_mapToModel).toList(),
            warehouseIds,
          ).then((value) => _filterProductsForWarehouses(value, warehouseIds)),
        );
  }

  @override
  Stream<List<ProductModel>> watchProductsBySubcategory(String categoryId, String subcategoryId, {List<String>? warehouseIds}) {
    return _firestoreDs.watchProductsBySubcategory(categoryId, subcategoryId).asyncMap(
          (dataList) => _attachVariantsForWarehouses(
            dataList.map(_mapToModel).toList(),
            warehouseIds,
          ).then((value) => _filterProductsForWarehouses(value, warehouseIds)),
        );
  }

  @override
  Future<void> updateStock(String productId, int newStock) async {
    await _firestoreDs.updateStock(productId, newStock);
  }

  @override
  Future<void> incrementStock(String productId, int delta) async {
    await _firestoreDs.incrementStock(productId, delta);
  }

  @override
  Stream<List<ProductModel>> watchProductsByBrand(String brandId, {List<String>? warehouseIds}) {
    return _firestoreDs.watchProductsByBrand(brandId).asyncMap(
          (dataList) => _attachVariantsForWarehouses(
            dataList.map(_mapToModel).toList(),
            warehouseIds,
          ).then((value) => _filterProductsForWarehouses(value, warehouseIds)),
        );
  }

  @override
  Stream<List<ProductModel>> watchProductsByCategories(List<String> categoryIds, {List<String>? warehouseIds}) {
    return _firestoreDs.watchProductsByCategories(categoryIds).asyncMap(
          (dataList) => _attachVariantsForWarehouses(
            dataList.map(_mapToModel).toList(),
            warehouseIds,
          ).then((value) => _filterProductsForWarehouses(value, warehouseIds)),
        );
  }

  @override
  Stream<List<PackVariant>> getVariantsByProduct(String productId) {
    return _variantDs.getVariantsByProduct(productId);
  }

  @override
  Stream<List<PackVariant>> getVariantsByDeliveryType(String productId, DeliveryType deliveryType) {
    return _variantDs.getVariantsByDeliveryType(productId, deliveryType);
  }

  @override
  Stream<List<PackVariant>> getVariantsByProductAndWarehouse(String productId, String warehouseId) {
    return _variantDs.getVariantsByProductAndWarehouses(
      productId,
      [warehouseId],
    );
  }
}
