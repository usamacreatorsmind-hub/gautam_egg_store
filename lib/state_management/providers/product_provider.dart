// // // providers/product_provider.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:sure_wholesaler/core/services/product_service.dart';
// import 'package:sure_wholesaler/models/product_model.dart';
// import 'package:sure_wholesaler/services/product_service.dart';

// part 'product_provider.g.dart';

// // Product state class
// @Freezed()
// class ProductState with _$ProductState {
//   const factory ProductState({
//     @Default([]) List<ProductModel> products,
//     @Default([]) List<ProductModel> displayedProducts,
//     @Default(false) bool isLoading,
//     @Default(false) bool isLoadingMore,
//     @Default(1) int currentPage,
//     @Default(true) bool hasMoreData,
//     String? error,
//     String? searchQuery,
//   }) = _ProductState;
// }

// // Product service provider
// @riverpod
// ProductService productService(ProductServiceRef ref) {
//   return ProductService();
// }

// // All products provider
// @riverpod
// class ProductsNotifier extends _$ProductsNotifier {
//   final int _itemsPerPage = 12;

//   @override
//   ProductState build() {
//     // Initial state
//     return ProductState();
//   }

//   /// Fetch all products
//   Future<void> fetchProducts() async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       final service = ref.read(productServiceProvider);
//       final products = await service.fetchProducts();

//       state = state.copyWith(
//         products: products,
//         displayedProducts: _getPaginatedProducts(products, 1),
//         isLoading: false,
//         currentPage: 1,
//         hasMoreData: products.length > _itemsPerPage,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }

//   /// Load more products
//   Future<void> loadMoreProducts() async {
//     if (state.isLoadingMore || !state.hasMoreData) return;

//     try {
//       state = state.copyWith(isLoadingMore: true);

//       await Future.delayed(const Duration(milliseconds: 500));

//       final newPage = state.currentPage + 1;
//       final newDisplayedProducts = _getPaginatedProducts(
//         state.products,
//         newPage,
//       );

//       state = state.copyWith(
//         displayedProducts: [
//           ...state.displayedProducts,
//           ...newDisplayedProducts,
//         ],
//         currentPage: newPage,
//         isLoadingMore: false,
//         hasMoreData: (newPage * _itemsPerPage) < state.products.length,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoadingMore: false,
//         error: e.toString(),
//       );
//     }
//   }

//   List<ProductModel> _getPaginatedProducts(
//     List<ProductModel> allProducts, 
//     int page
//   ) {
//     final startIndex = (page - 1) * _itemsPerPage;
//     final endIndex = startIndex + _itemsPerPage;
    
//     if (startIndex >= allProducts.length) {
//       return [];
//     }
    
//     return allProducts.sublist(
//       startIndex,
//       endIndex < allProducts.length ? endIndex : allProducts.length,
//     );
//   }
// }

// // Category products provider
// @riverpod
// class CategoryProductsNotifier extends _$CategoryProductsNotifier {
//   final int _itemsPerPage = 10;

//   @override
//   ProductState build() {
//     return ProductState();
//   }

//   /// Fetch products by category
//   Future<void> fetchProductsByCategory(List<String> categoryIds) async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       final service = ref.read(productServiceProvider);
//       final products = await service.fetchProductsByCategory(categoryIds);

//       state = state.copyWith(
//         products: products,
//         displayedProducts: _getPaginatedProducts(products, 1),
//         isLoading: false,
//         currentPage: 1,
//         hasMoreData: products.length > _itemsPerPage,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }

//   /// Load more products
//   Future<void> loadMoreProducts() async {
//     if (state.isLoadingMore || !state.hasMoreData) return;

//     try {
//       state = state.copyWith(isLoadingMore: true);

//       await Future.delayed(const Duration(milliseconds: 500));

//       final newPage = state.currentPage + 1;
//       final newDisplayedProducts = _getPaginatedProducts(
//         state.products,
//         newPage,
//       );

//       state = state.copyWith(
//         displayedProducts: [
//           ...state.displayedProducts,
//           ...newDisplayedProducts,
//         ],
//         currentPage: newPage,
//         isLoadingMore: false,
//         hasMoreData: (newPage * _itemsPerPage) < state.products.length,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoadingMore: false,
//         error: e.toString(),
//       );
//     }
//   }

//   List<ProductModel> _getPaginatedProducts(
//     List<ProductModel> allProducts, 
//     int page
//   ) {
//     final startIndex = (page - 1) * _itemsPerPage;
//     final endIndex = startIndex + _itemsPerPage;
    
//     if (startIndex >= allProducts.length) {
//       return [];
//     }
    
//     return allProducts.sublist(
//       startIndex,
//       endIndex < allProducts.length ? endIndex : allProducts.length,
//     );
//   }
// }

// // Search products provider
// @riverpod
// class SearchProductsNotifier extends _$SearchProductsNotifier {
//   final int _itemsPerPage = 10;

//   @override
//   ProductState build() {
//     return ProductState();
//   }

//   /// Search products
//   Future<void> searchProducts(String query) async {
//     try {
//       state = state.copyWith(
//         isLoading: true, 
//         error: null,
//         searchQuery: query,
//       );

//       final service = ref.read(productServiceProvider);
//       final products = await service.searchProducts(query);

//       state = state.copyWith(
//         products: products,
//         displayedProducts: _getPaginatedProducts(products, 1),
//         isLoading: false,
//         currentPage: 1,
//         hasMoreData: products.length > _itemsPerPage,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }

//   /// Load more search results
//   Future<void> loadMoreProducts() async {
//     if (state.isLoadingMore || !state.hasMoreData) return;

//     try {
//       state = state.copyWith(isLoadingMore: true);

//       await Future.delayed(const Duration(milliseconds: 500));

//       final newPage = state.currentPage + 1;
//       final newDisplayedProducts = _getPaginatedProducts(
//         state.products,
//         newPage,
//       );

//       state = state.copyWith(
//         displayedProducts: [
//           ...state.displayedProducts,
//           ...newDisplayedProducts,
//         ],
//         currentPage: newPage,
//         isLoadingMore: false,
//         hasMoreData: (newPage * _itemsPerPage) < state.products.length,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoadingMore: false,
//         error: e.toString(),
//       );
//     }
//   }

//   /// Clear search
//   void clearSearch() {
//     state = ProductState();
//   }

//   List<ProductModel> _getPaginatedProducts(
//     List<ProductModel> allProducts, 
//     int page
//   ) {
//     final startIndex = (page - 1) * _itemsPerPage;
//     final endIndex = startIndex + _itemsPerPage;
    
//     if (startIndex >= allProducts.length) {
//       return [];
//     }
    
//     return allProducts.sublist(
//       startIndex,
//       endIndex < allProducts.length ? endIndex : allProducts.length,
//     );
//   }
// }