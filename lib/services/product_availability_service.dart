import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/repositories/product_repository.dart';
import 'package:sure_wholesaler/services/warehouse_service.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_manager.dart';

/// Service for filtering product availability based on warehouse location and delivery constraints
class ProductAvailabilityService {
  final ProductRepository _productRepository;
  final WarehouseService _warehouseService;

  ProductAvailabilityService(this._productRepository, this._warehouseService);

  /// Get products available at the nearest warehouse for a specific delivery type
  Future<List<ProductModel>> getProductsAvailableAtNearestWarehouse(
    DeliveryType deliveryType, {
    double? userLat,
    double? userLng,
  }) async {
    // Find nearest warehouse
    final nearestWarehouse = userLat != null && userLng != null
        ? await _warehouseService.streamNearestWarehouse(userLat, userLng).first
        : null;

    if (nearestWarehouse == null) {
      // Fallback: return all products (will be filtered by availability later)
      return await _productRepository.getActiveProducts().first;
    }

    // Get all products and filter variants by warehouse availability
    final allProducts = await _productRepository.getActiveProducts().first;

    return Future.wait(allProducts.map((product) async {
      if (product.id == null) return product;

      // Get variants available at the nearest warehouse
      final availableVariants = await _productRepository
          .getVariantsByProductAndWarehouse(product.id!, nearestWarehouse.id!)
          .first;

      // Filter variants based on delivery type and stock
      final eligibleVariants = availableVariants.where((variant) {
        // Must have stock
        if (variant.isOutOfStock) return false;

        // Must support the delivery type
        if (!variant.supports(deliveryType)) return false;

        return true;
      }).toList();

      // Return product with only eligible variants
      return product.withVariants(eligibleVariants);
    })).then((products) => products
        .where((product) => product.activePackVariants.isNotEmpty)
        .toList());
  }

  /// Get available warehouses for a specific product and delivery type
  Future<List<WarehouseDistance>> getAvailableWarehousesForProduct(
    String productId,
    DeliveryType deliveryType, {
    double? userLat,
    double? userLng,
  }) async {
    if (userLat == null || userLng == null) return [];

    // Get all warehouses in range
    final warehousesInRange =
        await _warehouseService.streamWarehousesInRange(userLat, userLng).first;

    // Filter warehouses that have the product available for the delivery type
    final availableWarehouses = <WarehouseDistance>[];

    for (final warehouseDistance in warehousesInRange) {
      final variants = await _productRepository
          .getVariantsByProductAndWarehouse(
              productId, warehouseDistance.warehouse.id!)
          .first;

      // Check if any variant is available for the delivery type
      final hasAvailableVariant = variants.any(
          (variant) => !variant.isOutOfStock && variant.supports(deliveryType));

      if (hasAvailableVariant) {
        availableWarehouses.add(warehouseDistance);
      }
    }

    return availableWarehouses;
  }

  /// Check if a product variant is available for quick delivery at user's location
  Future<bool> isVariantAvailableForQuickDelivery(
    String productId,
    String variantId, {
    double? userLat,
    double? userLng,
  }) async {
    if (userLat == null || userLng == null) return false;

    // Find nearest warehouse
    final nearestWarehouse =
        await _warehouseService.streamNearestWarehouse(userLat, userLng).first;

    if (nearestWarehouse == null) return false;

    // Get variant at nearest warehouse
    final variants = await _productRepository
        .getVariantsByProductAndWarehouse(productId, nearestWarehouse.id!)
        .first;

    final variant = variants.firstWhere(
      (v) => v.id == variantId,
      orElse: () => PackVariant.placeholder(productId),
    );

    // Check if variant exists, has stock, and supports quick delivery
    return variant.id != '' &&
        !variant.isOutOfStock &&
        variant.supports(DeliveryType.quick);
  }

  /// Get the recommended warehouse for a user (nearest one in service range)
  Future<Warehouse?> getRecommendedWarehouse({
    double? userLat,
    double? userLng,
  }) async {
    if (userLat == null || userLng == null) return null;

    return await _warehouseService
        .streamNearestWarehouse(userLat, userLng)
        .first;
  }
}

/// Riverpod provider for product availability service
final productAvailabilityServiceProvider =
    Provider<ProductAvailabilityService>((ref) {
  return ProductAvailabilityService(
    ref.read(productRepositoryProvider),
    ref.read(warehouseServiceProvider),
  );
});

/// Provider for products available at nearest warehouse for quick delivery
final quickDeliveryProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final availabilityService = ref.read(productAvailabilityServiceProvider);
  final locationManager = LocationManager();

  try {
    final locationData =
        await locationManager.getCurrentLocationWithAddress().first;
    if (locationData == null) return [];

    return await availabilityService.getProductsAvailableAtNearestWarehouse(
      DeliveryType.quick,
      userLat: locationData.latitude,
      userLng: locationData.longitude,
    );
  } catch (e) {
    return [];
  }
});

/// Provider for available warehouses for a specific product
final availableWarehousesForProductProvider =
    FutureProvider.family<List<WarehouseDistance>, String>(
        (ref, productId) async {
  final availabilityService = ref.read(productAvailabilityServiceProvider);
  final locationManager = LocationManager();

  try {
    final locationData =
        await locationManager.getCurrentLocationWithAddress().first;
    if (locationData == null) return [];

    return await availabilityService.getAvailableWarehousesForProduct(
      productId,
      DeliveryType.quick, // Could be made configurable
      userLat: locationData.latitude,
      userLng: locationData.longitude,
    );
  } catch (e) {
    return [];
  }
});
