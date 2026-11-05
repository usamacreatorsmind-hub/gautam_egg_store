import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/models/favorite_item_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

List<List<T>> _chunks<T>(List<T> list, int size) {
  final result = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    result.add(
        list.sublist(i, (i + size) > list.length ? list.length : i + size));
  }
  return result;
}

// ── Repos (module-level singletons — stateless, safe to share) ────────────────

final _productRepo = FirestoreRepository<ProductModel>(
  collectionPath: Collections.products,
  fromFirestore: (doc) =>
      ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
);

final _variantRepo = FirestoreRepository<PackVariant>(
  collectionPath: Collections.variants,
  fromFirestore: (doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackVariant.fromMap(data, productId: data['productId'] ?? '');
  },
);

// ── Providers ──────────────────────────────────────────────────────────────────

final _currentUidProvider = Provider<String?>(
  (_) => FirebaseAuth.instance.currentUser?.uid,
);

/// Favorites subcollection repo, scoped to a specific user UID.
final favoritesRepoProvider =
    Provider.family<FirestoreRepository<FavoriteItemModel>, String>(
  (ref, uid) => FirestoreRepository<FavoriteItemModel>(
    collectionPath: '${Collections.users}/$uid/favorites',
    fromFirestore: FavoriteItemModel.fromFirestore,
  ),
);

/// Real-time stream of favorited product IDs — cheap to watch, use for heart-icon state.
final favoriteIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(_currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref
      .watch(favoritesRepoProvider(uid))
      .streamAll(orderBy: 'addedAt', descending: true)
      .map((items) => items.map((e) => e.id).toList());
});

/// Real-time stream of full ProductModel objects for all favorites (with variants and inventory).
final favoriteProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final uid = ref.watch(_currentUidProvider);
  if (uid == null) return Stream.value([]);

  final warehouseIds = ref.watch(resolvedWarehouseProvider);

  return ref
      .watch(favoritesRepoProvider(uid))
      .streamAll(orderBy: 'addedAt', descending: true)
      .asyncMap((items) async {
    final ids = items.map((e) => e.id).toList();
    if (ids.isEmpty) return <ProductModel>[];

    // Fetch products
    final productResults = await Future.wait(
      _chunks(ids, 30).map(
        (chunk) => _productRepo.query(
          (q) => q.where(FieldPath.documentId, whereIn: chunk),
        ),
      ),
    );
    final allProducts = productResults.expand((l) => l).toList();

    // Fetch variants with warehouse-aware inventory in parallel
    final variantDs = VariantFirestoreDsImpl();
    final updatedProducts = await Future.wait(allProducts.map((p) async {
      if (p.id == null) return p;

      final variants = warehouseIds.isEmpty
          ? await variantDs.getVariantsByProduct(p.id!).first
          : await variantDs
              .getVariantsByProductAndWarehouses(p.id!, warehouseIds)
              .first;

      return variants.isNotEmpty ? p.withVariants(variants) : p;
    }));

    updatedProducts.sort((a, b) {
      final ai = ids.indexOf(a.id ?? '');
      final bi = ids.indexOf(b.id ?? '');
      return ai.compareTo(bi);
    });

    return updatedProducts;
  });
});

/// Whether a specific product ID is in the favorites list.
/// Derived from [favoriteIdsProvider] — no extra Firestore call.
final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  final ids = ref.watch(favoriteIdsProvider).asData?.value ?? [];
  return ids.contains(productId);
});

// ── Notifier ───────────────────────────────────────────────────────────────────

class FavoritesNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggle(String productId) async {
    final uid = ref.read(_currentUidProvider);
    if (uid == null) return;
    final repo = ref.read(favoritesRepoProvider(uid));
    final existing = await repo.getById(productId);
    if (existing != null) {
      await repo.delete(productId);
    } else {
      await repo.set(
        FavoriteItemModel(id: productId, addedAt: DateTime.now()),
      );
    }
  }
}

final favoritesNotifierProvider =
    NotifierProvider<FavoritesNotifier, void>(FavoritesNotifier.new);
