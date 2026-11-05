import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/services/warehouse_service.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_manager.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_utils.dart';

class LocationAwareCartService {
  final WarehouseService _warehouseService;
  final LocationManager _locationManager;

  LocationAwareCartService(this._warehouseService, this._locationManager);

  Future<Warehouse?> getRecommendedWarehouseForCart() async {
    try {
      final locationData =
          await _locationManager.getCurrentLocationWithAddress().first;
      if (locationData == null) return null;

      return await _warehouseService
          .streamNearestWarehouse(locationData.latitude, locationData.longitude)
          .first;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isWarehouseSuitableForQuickDelivery(
    Warehouse warehouse, {
    double? userLat,
    double? userLng,
  }) async {
    if (userLat == null || userLng == null) {
      final locationData =
          await _locationManager.getCurrentLocationWithAddress().first;
      if (locationData == null) return false;
      userLat = locationData.latitude;
      userLng = locationData.longitude;
    }

    final distanceKm = await LocationUtils.distanceInKm(
      userLat,
      userLng,
      warehouse.latitude,
      warehouse.longitude,
    );
    return (distanceKm ?? double.infinity) <= warehouse.quickdeliveryRadiusKm;
  }

  Future<List<Warehouse>> getAvailableWarehousesForUser() async {
    try {
      final locationData =
          await _locationManager.getCurrentLocationWithAddress().first;
      if (locationData == null) return [];

      final warehousesInRange = await _warehouseService
          .streamWarehousesInRange(
              locationData.latitude, locationData.longitude)
          .first;

      return warehousesInRange.map((wd) => wd.warehouse).toList();
    } catch (e) {
      return [];
    }
  }
}

final locationAwareCartServiceProvider =
    Provider<LocationAwareCartService>((ref) {
  return LocationAwareCartService(
    ref.read(warehouseServiceProvider),
    LocationManager(),
  );
});

final autoSelectedWarehouseProvider = StreamProvider<Warehouse?>((ref) {
  final locationManager = LocationManager();
  final service = ref.read(warehouseServiceProvider);

  return locationManager
      .getCurrentLocationWithAddress()
      .asyncExpand((locationData) {
    if (locationData == null) return Stream.value(null);
    return service.streamNearestWarehouse(
        locationData.latitude, locationData.longitude);
  });
});

final userAvailableWarehousesProvider = StreamProvider<List<Warehouse>>((ref) {
  final locationManager = LocationManager();
  final service = ref.read(warehouseServiceProvider);

  return locationManager
      .getCurrentLocationWithAddress()
      .asyncExpand((locationData) {
    if (locationData == null) return Stream.value(<Warehouse>[]);
    return service
        .streamWarehousesInRange(locationData.latitude, locationData.longitude)
        .map((list) => list.map((wd) => wd.warehouse).toList());
  });
});

final locationAwareCartProvider =
    StateNotifierProvider<LocationAwareCartNotifier, AsyncValue<CartItemModel>>(
        (ref) {
  return LocationAwareCartNotifier(
    ref.read(cartRepositoryProvider),
    ref.read(locationAwareCartServiceProvider),
    getSelectedWarehouse: () =>
        ref.read(selectedWarehousesProvider).firstOrNull,
  );
});

class LocationAwareCartNotifier extends CartNotifier {
  final LocationAwareCartService _locationCartService;

  LocationAwareCartNotifier(
    super.repository,
    this._locationCartService, {
    required super.getSelectedWarehouse,
  });

  Future<void> addToCartWithAutoWarehouse(
    CartItem item, {
    DeliveryType? preferredDeliveryType,
  }) async {
    final deliveryType = preferredDeliveryType ?? DeliveryType.quick;

    final recommendedWarehouse =
        await _locationCartService.getRecommendedWarehouseForCart();

    if (recommendedWarehouse == null) {
      addToCart(item);
      return;
    }

    final isSuitable =
        await _locationCartService.isWarehouseSuitableForQuickDelivery(
      recommendedWarehouse,
    );

    if (!isSuitable && deliveryType == DeliveryType.quick) {
      // Warehouse too far for quick delivery; could prompt user
    }

    final itemWithWarehouse =
        item.copyWith(warehouseId: recommendedWarehouse.id);
    addToCart(itemWithWarehouse);
  }

  Future<Map<Warehouse, List<CartItem>>>
      getCartItemsByWarehouseWithLocation() async {
    final cart = state.value;
    if (cart == null) return {};

    final warehouses =
        await _locationCartService.getAvailableWarehousesForUser();
    final warehouseMap = {for (final w in warehouses) w.id: w};

    final result = <Warehouse, List<CartItem>>{};

    cart.warehouseItems.forEach((warehouseId, items) {
      final warehouse = warehouseMap[warehouseId];
      if (warehouse != null) {
        result[warehouse] = items;
      }
    });

    return result;
  }
}
