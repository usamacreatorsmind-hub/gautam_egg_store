import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/warehouse_firestore_ds.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/repositories/warehouse_repository.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_manager.dart';
import 'package:sure_wholesaler/utils/location_base_classes/location_utils.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  return WarehouseRepositoryImpl(WarehouseFirestoreDsImpl());
});

/// All warehouses, real-time.
final warehouseProvider =
    StateNotifierProvider<WarehouseNotifier, AsyncValue<List<Warehouse>>>(
        (ref) {
  return WarehouseNotifier(ref.read(warehouseRepositoryProvider));
});

/// Active warehouses only.
final activeWarehousesProvider = Provider<List<Warehouse>>((ref) {
  return ref
          .watch(warehouseProvider)
          .value
          ?.where((w) => w.isActive)
          .toList() ??
      [];
});

/// Single warehouse by ID, derived from the cached list.
final warehouseByIdProvider =
    Provider.family<Warehouse?, String>((ref, warehouseId) {
  final warehouses = ref.watch(warehouseProvider).value ?? [];
  try {
    return warehouses.firstWhere((w) => w.id == warehouseId);
  } catch (_) {
    return null;
  }
});

final reachableDeliveryTypesByWarehouseProvider =
    FutureProvider.family<List<DeliveryType>, String>((ref, warehouseId) async {
  final warehouse = ref.watch(warehouseByIdProvider(warehouseId));
  if (warehouse == null) return const [];

  final locationData =
      await LocationManager().getCurrentLocationWithAddress().first;
  if (locationData == null) return const [];

  final distanceKm = await LocationUtils.distanceInKm(
    locationData.latitude,
    locationData.longitude,
    warehouse.latitude,
    warehouse.longitude,
  );

  final resolvedDistance = distanceKm ?? double.infinity;
  final reachableTypes = <DeliveryType>[];

  if (resolvedDistance <= warehouse.quickdeliveryRadiusKm) {
    reachableTypes.add(DeliveryType.quick);
  }
  if (resolvedDistance <= warehouse.scheduledDeliveryRadius) {
    reachableTypes.add(DeliveryType.scheduled);
  }

  return reachableTypes;
});

class WarehouseNotifier extends StateNotifier<AsyncValue<List<Warehouse>>> {
  final WarehouseRepository _repository;
  StreamSubscription<List<Warehouse>>? _subscription;

  WarehouseNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchWarehouses().listen(
          (warehouses) => state = AsyncValue.data(warehouses),
          onError: (e, st) => state = AsyncValue.error(e, st),
        );
  }

  Future<Warehouse?> getWarehouseById(String warehouseId) =>
      _repository.getWarehouseById(warehouseId);

  Future<String> createWarehouse(Warehouse warehouse) =>
      _repository.createWarehouse(warehouse);

  Future<void> updateWarehouse(String warehouseId, Map<String, dynamic> data) =>
      _repository.updateWarehouse(warehouseId, data);

  Future<void> deleteWarehouse(String warehouseId) =>
      _repository.deleteWarehouse(warehouseId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
