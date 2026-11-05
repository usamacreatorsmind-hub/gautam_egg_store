import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/firebase/favorite_proudcts_ds.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';

abstract class FavoriteProductsRepository {
  /// Real-time stream of favorited product IDs.
  Stream<List<String>> watchFavoriteIds();

  /// Real-time stream of full ProductModel objects for all favorited products.
  /// Products are fetched individually so the list stays live.
  Stream<List<ProductModel>> watchFavoriteProducts();

  /// Toggle favorite status for a product.
  Future<void> toggleFavorite(String productId);

  /// Returns true if the product is currently favorited.
  Future<bool> isFavorite(String productId);
}

class FavoriteProductsRepositoryImpl implements FavoriteProductsRepository {
  final FavoriteProductsDataSource _ds;
  final FirebaseFirestore _firestore;

  FavoriteProductsRepositoryImpl(this._ds, this._firestore);

  @override
  Stream<List<String>> watchFavoriteIds() => _ds.watchFavoriteIds();

  @override
  Stream<List<ProductModel>> watchFavoriteProducts() {
    return _ds.watchFavoriteIds().asyncMap((ids) async {
      if (ids.isEmpty) return <ProductModel>[];

      // Firestore whereIn supports up to 30 items per query.
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 30) {
        chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
      }

      final productResults = await Future.wait(chunks.map((chunk) async {
        final snap = await _firestore
            .collection(Collections.products)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        return snap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
      }));

      final List<ProductModel> allProducts =
          productResults.expand((l) => l).toList();

      // --- Fetch and attach variants to ensure prices are not 0.00 ---
      final variantIds = allProducts
          .expand((p) => p.variantIds)
          .where((id) => id.isNotEmpty)
          .toList();

      if (variantIds.isNotEmpty) {
        final variantChunks = <List<String>>[];
        for (var i = 0; i < variantIds.length; i += 30) {
          variantChunks.add(variantIds.sublist(
              i, i + 30 > variantIds.length ? variantIds.length : i + 30));
        }

        final variantDocs = await Future.wait(variantChunks.map((chunk) =>
            _firestore
                .collection(Collections.variants)
                .where(FieldPath.documentId, whereIn: chunk)
                .get()));

        final allVariants = variantDocs
            .expand((snap) => snap.docs)
            .map((d) => PackVariant.fromMap(d.data(),
                productId: d.data()['productId'] ?? ''))
            .toList();

        for (var i = 0; i < allProducts.length; i++) {
          final p = allProducts[i];
          final pVariants =
              allVariants.where((v) => v.productId == p.id).toList();
          if (pVariants.isNotEmpty) {
            allProducts[i] = p.withVariants(pVariants);
          }
        }
      }

      // Preserve the order returned by Firestore favorites (most recent first).
      allProducts.sort((a, b) {
        final ai = ids.indexOf(a.id ?? '');
        final bi = ids.indexOf(b.id ?? '');
        return ai.compareTo(bi);
      });

      return allProducts;
    });
  }

  @override
  Future<void> toggleFavorite(String productId) =>
      _ds.toggleFavorite(productId);

  @override
  Future<bool> isFavorite(String productId) => _ds.isFavorite(productId);
}
