import 'package:sure_wholesaler/firebase/variant_firestore_ds.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';

abstract class VariantRepository {
  Stream<List<PackVariant>> getVariantsByProduct(String productId);
  Stream<List<PackVariant>> getVariantsByDeliveryType(
      String productId, DeliveryType deliveryType);
  Stream<List<PackVariant>> getVariantsByProductAndWarehouse(
      String productId, String warehouseId);
  Stream<PackVariant?> getVariantById(String variantId);
  Stream<List<PackVariant>> getVariantsByIds(List<String> variantIds);
  Future<String> createVariant(PackVariant variant);
  Future<void> updateVariant(String variantId, Map<String, dynamic> data);
  Future<void> decrementStock(String variantId, int qty);
  Future<void> incrementStock(String variantId, int qty);
  Stream<List<PackVariant>> watchVariantsByProduct(String productId);
  Stream<List<DeliveryType>> watchAvailableDeliveryTypes();
}

class VariantRepositoryImpl implements VariantRepository {
  final VariantFirestoreDs _ds;

  VariantRepositoryImpl(this._ds);

  @override
  Stream<List<PackVariant>> getVariantsByProduct(String productId) =>
      _ds.getVariantsByProduct(productId);

  @override
  Stream<List<PackVariant>> getVariantsByDeliveryType(
          String productId, DeliveryType deliveryType) =>
      _ds.getVariantsByDeliveryType(productId, deliveryType);

  @override
  Stream<List<PackVariant>> getVariantsByProductAndWarehouse(
          String productId, String warehouseId) =>
      _ds.getVariantsByProductAndWarehouses(productId, [warehouseId]);

  @override
  Stream<PackVariant?> getVariantById(String variantId) =>
      _ds.getVariantById(variantId);

  @override
  Stream<List<PackVariant>> getVariantsByIds(List<String> variantIds) =>
      _ds.getVariantsByIds(variantIds);

  @override
  Future<String> createVariant(PackVariant variant) =>
      _ds.createVariant(variant);

  @override
  Future<void> updateVariant(String variantId, Map<String, dynamic> data) =>
      _ds.updateVariant(variantId, data);

  @override
  Future<void> decrementStock(String variantId, int qty) =>
      _ds.decrementStock(variantId, qty);

  @override
  Future<void> incrementStock(String variantId, int qty) =>
      _ds.incrementStock(variantId, qty);

  @override
  Stream<List<PackVariant>> watchVariantsByProduct(String productId) =>
      _ds.watchVariantsByProduct(productId);

  @override
  Stream<List<DeliveryType>> watchAvailableDeliveryTypes() =>
      _ds.watchAvailableDeliveryTypes();
}
