import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/repositories/variant_repository.dart';

final variantRepositoryProvider = Provider<VariantRepository>((ref) {
  return VariantRepositoryImpl(VariantFirestoreDsImpl());
});

/// Real-time variants for a given product, warehouse-aware.
final variantsByProductProvider = StateNotifierProvider.family<
    VariantsByProductNotifier, AsyncValue<List<PackVariant>>, String>(
  (ref, productId) =>
      VariantsByProductNotifier(ref.read(variantRepositoryProvider), productId),
);

/// Stream a single variant by its doc ID.
final variantByIdProvider =
    StreamProvider.family<PackVariant?, String>((ref, variantId) {
  return ref.read(variantRepositoryProvider).getVariantById(variantId);
});

/// Fetch variants for a product at a specific warehouse.
final variantsByWarehouseProvider = StreamProvider.family<List<PackVariant>,
    ({String productId, String warehouseId})>((ref, args) {
  return ref
      .read(variantRepositoryProvider)
      .getVariantsByProductAndWarehouse(args.productId, args.warehouseId);
});

class VariantsByProductNotifier
    extends StateNotifier<AsyncValue<List<PackVariant>>> {
  final VariantRepository _repository;
  final String productId;
  StreamSubscription<List<PackVariant>>? _subscription;

  VariantsByProductNotifier(this._repository, this.productId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchVariantsByProduct(productId).listen(
          (variants) => state = AsyncValue.data(variants),
          onError: (e, st) => state = AsyncValue.error(e, st),
        );
  }

  Future<void> decrementStock(String variantId, int qty) =>
      _repository.decrementStock(variantId, qty);

  Future<void> incrementStock(String variantId, int qty) =>
      _repository.incrementStock(variantId, qty);

  Future<void> updateVariant(String variantId, Map<String, dynamic> data) =>
      _repository.updateVariant(variantId, data);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
