import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/product_firestore_ds.dart';
import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/repositories/product_repository.dart';
import 'package:sure_wholesaler/services/warehouse_service.dart';

import 'category_notifier.dart';

typedef SelectedWarehouseReader = List<String> Function();

/// Streams the delivery types that have at least one active variant in Firestore
final availableDeliveryTypesProvider = StreamProvider<List<DeliveryType>>((ref) {
  return VariantFirestoreDsImpl().watchAvailableDeliveryTypes();
});

/// Repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    ProductFirestoreDsImpl(),
    VariantFirestoreDsImpl(),
  );
});

/// Main products state provider
final productsProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>((ref) {
  ref.watch(resolvedWarehouseProvider);
  return ProductNotifier(
    ref.read(productRepositoryProvider),
    getSelectedWarehouse: () => ref.read(resolvedWarehouseProvider),
  );
});

/// Products by category provider
final productsByCategoryProvider = StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository.getProductsByCategory(categoryId, warehouseIds: warehouseIds);
});

/// Related products — same category, same warehouse, excluding the given product
final relatedProductsProvider = StreamProvider.family<List<ProductModel>, ProductModel>((ref, product) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository
      .getProductsByCategory(product.categoryId, warehouseIds: warehouseIds)
      .map((list) => list.where((p) => p.id != product.id).toList());
});

/// Other products from the same warehouse (different category, excluding current product)
final sameWarehouseProductsProvider = StreamProvider.family<List<ProductModel>, ProductModel>((ref, product) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository
      .getActiveProducts(warehouseIds: warehouseIds)
      .map((list) => list.where((p) => p.id != product.id && p.categoryId != product.categoryId).toList());
});

/// Products by multiple categories provider
final productsByCategoriesProvider = StreamProvider.family<List<ProductModel>, List<String>>((ref, categoryIds) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository.getProductsByCategories(categoryIds, warehouseIds: warehouseIds);
});

/// Products by category stream provider (real-time)
final productsByCategoryStreamProvider = StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);

  // Get all subcategory IDs for this root category
  final subcategories = ref.watch(subcategoriesProvider(categoryId));

  if (subcategories.isEmpty) {
    return repository.watchProductsByCategory(categoryId, warehouseIds: warehouseIds);
  }

  // If it's a root category, fetch products for Parent + all Children
  final allCategoryIds = [categoryId, ...subcategories.map((s) => s.docId)];
  return repository.watchProductsByCategories(allCategoryIds, warehouseIds: warehouseIds);
});

/// Subcategory filter params
class SubcategoryParams {
  final String categoryId;
  final String subcategoryId;

  const SubcategoryParams({
    required this.categoryId,
    required this.subcategoryId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubcategoryParams &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          subcategoryId == other.subcategoryId;

  @override
  int get hashCode => categoryId.hashCode ^ subcategoryId.hashCode;
}

/// Products by subcategory stream provider (real-time)
final productsBySubcategoryStreamProvider = StreamProvider.family<List<ProductModel>, SubcategoryParams>((ref, params) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository.watchProductsBySubcategory(params.categoryId, params.subcategoryId, warehouseIds: warehouseIds);
});

/// Products by brand stream provider (real-time)
final productsByBrandStreamProvider = StreamProvider.family<List<ProductModel>, String>((ref, brandId) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository.watchProductsByBrand(brandId, warehouseIds: warehouseIds);
});

/// Single product by ID provider
final productByIdProvider = FutureProvider.family<ProductModel?, String>((ref, productId) async {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return await repository.getProductById(productId, warehouseIds: warehouseIds).first;
});

/// Single product stream provider (real-time)
final productByIdStreamProvider = StreamProvider.family<ProductModel?, String>((ref, productId) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository.watchProductById(productId, warehouseIds: warehouseIds);
});

/// Products with offers provider
final productsWithOffersProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return await repository.getProductsWithOffers(warehouseIds: warehouseIds).first;
});

/// Best Deals / High Discount products
final topDiscountsProvider = StreamProvider<List<ProductModel>>((ref) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);

  // We fetch all active products and filter by discount locally for now
  // as Firestore doesn't support inequality on calculated fields.
  return repository.getActiveProducts(warehouseIds: warehouseIds).map((products) {
    return products.where((p) => (p.discountPercent ?? 0) >= 1).toList()
      ..sort((a, b) => (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0));
  });
});

/// Stream of all active products
final allActiveProductsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return repository.watchProducts(warehouseIds: warehouseIds).map((products) {
    return products.where((p) => p.isActive).toList();
  });
});

/// New Arrivals products
final newArrivalsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  return ref.watch(allActiveProductsStreamProvider).whenData((products) {
    final list = products.toList()
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    return list;
  });
});

/// Low stock products provider
final lowStockProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);
  return await repository.getLowStockProducts(warehouseIds: warehouseIds).first;
});

/// Product search query provider
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Searched products provider — client-side filtering for case-insensitive
/// substring match across name and brand (no Firestore index required).
final searchedProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(productSearchQueryProvider);
  if (query.isEmpty) return [];

  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);

  final allProducts = await repository.getActiveProducts(warehouseIds: warehouseIds).first;

  final q = query.toLowerCase();
  return allProducts
      .where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.brandName?.toLowerCase().contains(q) ?? false) ||
          p.tags.any((t) => t.toLowerCase().contains(q)) ||
          (p.description?.toLowerCase().contains(q) ?? false))
      .toList();
});

/// Product filter state
class ProductFilter {
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final bool? hasOffer;
  final String? sortBy;
  final bool descending;

  const ProductFilter({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.inStock,
    this.hasOffer,
    this.sortBy,
    this.descending = false,
  });

  ProductFilter copyWith({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? hasOffer,
    String? sortBy,
    bool? descending,
  }) {
    return ProductFilter(
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStock: inStock ?? this.inStock,
      hasOffer: hasOffer ?? this.hasOffer,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }

  bool get hasFilters => categoryId != null || minPrice != null || maxPrice != null || inStock != null || hasOffer != null;
}

/// Product filter provider
final productFilterProvider = StateProvider<ProductFilter>((ref) {
  return const ProductFilter();
});

/// Filtered products provider
final filteredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final filter = ref.watch(productFilterProvider);
  final repository = ref.read(productRepositoryProvider);
  final warehouseIds = ref.watch(resolvedWarehouseProvider);

  if (!filter.hasFilters && filter.sortBy == null) {
    return await repository.getActiveProducts(warehouseIds: warehouseIds).first;
  }

  return await repository
      .getProductsWithFilters(
        categoryId: filter.categoryId,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        inStock: filter.inStock,
        hasOffer: filter.hasOffer,
        sortBy: filter.sortBy,
        descending: filter.descending,
        warehouseIds: warehouseIds,
      )
      .first;
});

/// Paginated products state
class PaginatedProductsState {
  final List<ProductModel> products;
  final DocumentSnapshot? lastDocument;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedProductsState({
    this.products = const [],
    this.lastDocument,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedProductsState copyWith({
    List<ProductModel>? products,
    DocumentSnapshot? lastDocument,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedProductsState(
      products: products ?? this.products,
      lastDocument: lastDocument ?? this.lastDocument,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Selected warehouses filter (list of reachable warehouses)
final selectedWarehousesProvider = StateProvider<List<String>>((ref) => []);

final autoReachableWarehouseIdsProvider = Provider<List<String>>((ref) {
  final inRange = ref.watch(warehousesInRangeProvider).asData?.value ?? const [];
  return inRange.map((item) => item.warehouse.id).whereType<String>().toList();
});

final resolvedWarehouseProvider = Provider<List<String>>((ref) {
  return []; // Always return empty to disable filtering
});

/// Combined params for the paginated products provider
class ProductsParams {
  final DeliveryType? deliveryType;
  final List<String>? warehouseIds;

  const ProductsParams({this.deliveryType, this.warehouseIds});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsParams &&
          runtimeType == other.runtimeType &&
          deliveryType == other.deliveryType &&
          warehouseIds == other.warehouseIds;

  @override
  int get hashCode => deliveryType.hashCode ^ warehouseIds.hashCode;
}

/// Paginated products notifier
final paginatedProductsProvider = StateNotifierProvider.family<PaginatedProductsNotifier, PaginatedProductsState, ProductsParams>(
  (ref, params) => PaginatedProductsNotifier(
    ref.read(productRepositoryProvider),
    deliveryType: params.deliveryType,
    warehouseIds: params.warehouseIds,
  ),
);

class PaginatedProductsNotifier extends StateNotifier<PaginatedProductsState> {
  final ProductRepository _repository;
  final DeliveryType? deliveryType;
  final List<String>? warehouseIds;
  final int _pageSize = 20;
  String? _categoryId;

  PaginatedProductsNotifier(this._repository, {this.deliveryType, this.warehouseIds})
      : super(const PaginatedProductsState(isLoading: true));

  /// Load initial products
  Future<void> loadProducts({String? categoryId}) async {
    _categoryId = categoryId;
    state = const PaginatedProductsState(isLoading: true);

    try {
      final result = await _repository.getProductsPaginated(
        limit: _pageSize,
        categoryId: categoryId,
        deliveryType: deliveryType,
        warehouseIds: warehouseIds,
      );

      state = PaginatedProductsState(
        products: result.products,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      );
      if (kDebugMode) {
        debugPrint('[Products] loaded ${result.products.length} products '
            '(deliveryType: $deliveryType, category: $categoryId)');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Products] ERROR: $e\n$st');
      state = PaginatedProductsState(error: e.toString());
    }
  }

  /// Load more products
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _repository.getProductsPaginated(
        limit: _pageSize,
        lastDocument: state.lastDocument,
        categoryId: _categoryId,
        deliveryType: deliveryType,
        warehouseIds: warehouseIds,
      );

      state = state.copyWith(
        products: [...state.products, ...result.products],
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh products
  Future<void> refresh() async {
    await loadProducts(categoryId: _categoryId);
  }
}

/// Main product notifier
class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;
  final SelectedWarehouseReader _getSelectedWarehouses;
  StreamSubscription<List<ProductModel>>? _subscription;

  ProductNotifier(
    this._repository, {
    required SelectedWarehouseReader getSelectedWarehouse,
  })  : _getSelectedWarehouses = getSelectedWarehouse,
        super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final warehouseIds = _getSelectedWarehouses();
    _subscription = _repository.watchProducts(warehouseIds: warehouseIds).listen(
      (products) {
        state = AsyncValue.data(products);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  /// Refresh products manually
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final warehouseIds = _getSelectedWarehouses();
      final products = await _repository.getProducts(warehouseIds: warehouseIds).first;
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Get active products only
  Future<List<ProductModel>> getActiveProducts() async {
    final warehouseIds = _getSelectedWarehouses();
    return await _repository.getActiveProducts(warehouseIds: warehouseIds).first;
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final warehouseIds = _getSelectedWarehouses();
    return await _repository.getProductsByCategory(categoryId, warehouseIds: warehouseIds).first;
  }

  /// Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    final warehouseIds = _getSelectedWarehouses();
    return await _repository.searchProducts(query, warehouseIds: warehouseIds).first;
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    final warehouseIds = _getSelectedWarehouses();
    return await _repository.getProductById(productId, warehouseIds: warehouseIds).first;
  }

  /// Update product stock
  Future<void> updateStock(String productId, int newStock) async {
    await _repository.updateStock(productId, newStock);
  }

  /// Increment/decrement stock
  Future<void> incrementStock(String productId, int delta) async {
    await _repository.incrementStock(productId, delta);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
