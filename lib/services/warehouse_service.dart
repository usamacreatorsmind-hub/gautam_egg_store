import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';
import 'package:sure_wholesaler/utils/locationProviders.dart' as loc;
import 'package:sure_wholesaler/utils/location_base_classes/location_utils.dart';

class WarehouseService {
  final FirestoreRepository<Warehouse> _repo = FirestoreRepository(
    collectionPath: Collections.warehouses,
    fromFirestore: Warehouse.fromFirestore,
  );

  Stream<List<Warehouse>> streamAllWarehouses() => _repo.streamAll();

  Stream<List<Warehouse>> streamActiveWarehouses() => _repo.streamQuery((q) => q.where('isActive', isEqualTo: true));

  Stream<Warehouse?> streamWarehouseById(String id) => _repo.streamById(id);

  Stream<List<WarehouseDistance>> streamWarehousesInRange(double userLat, double userLng) {
    return streamActiveWarehouses().asyncMap((warehouses) async {
      final inRange = <WarehouseDistance>[];
      for (final warehouse in warehouses) {
        final distance = await LocationUtils.distanceInKm(
          userLat,
          userLng,
          warehouse.latitude,
          warehouse.longitude,
        );

        print("this is the distance $distance");
        if (distance != null && distance <= warehouse.scheduledDeliveryRadius) {
          inRange.add(WarehouseDistance(warehouse: warehouse, distanceKm: distance));
        }
      }
      inRange.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return inRange;
    });
  }

  Stream<Warehouse?> streamNearestWarehouse(double userLat, double userLng) {
    return streamWarehousesInRange(userLat, userLng).map((list) => list.isEmpty ? null : list.first.warehouse);
  }
}

class WarehouseDistance {
  final Warehouse warehouse;
  final double distanceKm;

  WarehouseDistance({required this.warehouse, required this.distanceKm});

  @override
  String toString() => '${warehouse.name} (${distanceKm.toStringAsFixed(1)} km)';
}

final warehouseServiceProvider = Provider<WarehouseService>((ref) => WarehouseService());

final nearestWarehouseProvider = StreamProvider<Warehouse?>((ref) {
  final locationData = ref.watch(loc.effectiveLocationProvider);
  final service = ref.read(warehouseServiceProvider);

  if (locationData == null) return Stream.value(null);
  
  return service.streamNearestWarehouse(
    locationData.latitude,
    locationData.longitude,
  ).timeout(
    const Duration(seconds: 15),
    onTimeout: (sink) => sink.add(null),
  );
});

final warehousesInRangeProvider = StreamProvider<List<WarehouseDistance>>((ref) {
  final locationData = ref.watch(loc.effectiveLocationProvider);
  final service = ref.read(warehouseServiceProvider);

  if (locationData == null) return Stream.value(<WarehouseDistance>[]);
  
  return service.streamWarehousesInRange(
    locationData.latitude,
    locationData.longitude,
  ).timeout(
    const Duration(seconds: 15),
    onTimeout: (sink) => sink.add(<WarehouseDistance>[]),
  );
});

final allWarehousesProvider = StreamProvider<List<Warehouse>>(
  (ref) => ref.read(warehouseServiceProvider).streamAllWarehouses(),
);

final activeWarehousesProvider = StreamProvider<List<Warehouse>>(
  (ref) => ref.read(warehouseServiceProvider).streamActiveWarehouses(),
);

final warehouseLatLngbyIdProvider = StreamProvider.family<LatLng?, String>(
  (ref, warehouseId) {
    final service = ref.read(warehouseServiceProvider);
    return service.streamWarehouseById(warehouseId).map((warehouse) {
      if (warehouse == null) return null;
      return LatLng(warehouse.latitude, warehouse.longitude);
    });
  },
);
