import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/inventory_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';

abstract class VariantFirestoreDs {
  /// Fetch all variants for a product
  Stream<List<PackVariant>> getVariantsByProduct(String productId);

  /// Fetch variants for a product that support a specific delivery type
  Stream<List<PackVariant>> getVariantsByDeliveryType(
      String productId, DeliveryType deliveryType);

  /// Fetch variants for a product available at specific warehouses
  Stream<List<PackVariant>> getVariantsByProductAndWarehouses(
      String productId, List<String> warehouseIds);

  /// Fetch a single variant by its doc ID
  Stream<PackVariant?> getVariantById(String variantId);

  /// Fetch multiple variants by their doc IDs
  Stream<List<PackVariant>> getVariantsByIds(List<String> variantIds);

  /// Create a new variant doc, returns the generated doc ID
  Future<String> createVariant(PackVariant variant);

  /// Update an existing variant doc
  Future<void> updateVariant(String variantId, Map<String, dynamic> data);

  /// Decrement stock atomically (used when placing an order)
  Future<void> decrementStock(String variantId, int qty);

  /// Increment stock atomically (used when cancelling an order)
  Future<void> incrementStock(String variantId, int qty);

  /// Watch all variants for a product in real time
  Stream<List<PackVariant>> watchVariantsByProduct(String productId);

  /// Returns the distinct DeliveryTypes that have at least one active variant
  Stream<List<DeliveryType>> watchAvailableDeliveryTypes();
}

class VariantFirestoreDsImpl implements VariantFirestoreDs {
  final FirebaseFirestore _firestore;
  final String _collection = Collections.variants;
  final String _inventoryCollection = Collections.inventories;

  VariantFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _variantCollection =>
      _firestore.collection(_collection);
  CollectionReference get _inventories =>
      _firestore.collection(_inventoryCollection);

  PackVariant _fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    data['id'] = doc.id;
    return PackVariant.fromMap(data);
  }

  Future<Map<String, Inventory>> _inventoriesByVariantIdsAndWarehouses(
    List<String> variantIds,
    List<String> warehouseIds,
  ) async {
    if (variantIds.isEmpty) {
      return const <String, Inventory>{};
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < variantIds.length; i += 30) {
      chunks.add(
        variantIds.sublist(
          i,
          i + 30 > variantIds.length ? variantIds.length : i + 30,
        ),
      );
    }

    final inventoriesByVariant = <String, List<Inventory>>{};
    for (final chunk in chunks) {
      final snapshot =
          await _inventories.where('variantId', whereIn: chunk).get();

      for (final doc in snapshot.docs) {
        final inventory = Inventory.fromMap(
          Map<String, dynamic>.from(doc.data() as Map),
        ).copyWith(id: doc.id);
        if (warehouseIds.contains(inventory.warehouseId)) {
          inventoriesByVariant
              .putIfAbsent(inventory.variantId, () => <Inventory>[])
              .add(inventory);
        }
      }
    }

    final warehouseRank = <String, int>{
      for (var i = 0; i < warehouseIds.length; i++) warehouseIds[i]: i,
    };

    final inventories = <String, Inventory>{};
    inventoriesByVariant.forEach((variantId, matches) {
      matches.sort((a, b) {
        final aPriority = a.stock > 0 && a.isAvailable ? 0 : 1;
        final bPriority = b.stock > 0 && b.isAvailable ? 0 : 1;
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);

        final aRank = warehouseRank[a.warehouseId] ?? warehouseIds.length;
        final bRank = warehouseRank[b.warehouseId] ?? warehouseIds.length;
        if (aRank != bRank) return aRank.compareTo(bRank);

        return b.stock.compareTo(a.stock);
      });
      inventories[variantId] = matches.first;
    });

    return inventories;
  }

  Future<Map<String, Inventory>> _inventoriesByVariantIds(
    List<String> variantIds,
  ) async {
    if (variantIds.isEmpty) return const <String, Inventory>{};

    final chunks = <List<String>>[];
    for (var i = 0; i < variantIds.length; i += 30) {
      chunks.add(
        variantIds.sublist(
          i,
          i + 30 > variantIds.length ? variantIds.length : i + 30,
        ),
      );
    }

    final inventories = <String, Inventory>{};
    for (final chunk in chunks) {
      final snapshot =
          await _inventories.where('variantId', whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        final inventory = Inventory.fromMap(
          Map<String, dynamic>.from(doc.data() as Map),
        ).copyWith(id: doc.id);
        inventories.putIfAbsent(inventory.variantId, () => inventory);
      }
    }

    return inventories;
  }

  Future<List<PackVariant>> _attachInventories(
    List<PackVariant> variants,
  ) async {
    final inventories = await _inventoriesByVariantIds(
      variants.map((v) => v.id).toList(),
    );
    return variants.map((v) => v.withInventoryData(inventories[v.id])).toList();
  }

  Future<List<PackVariant>> _attachWarehouseInventories(
    List<PackVariant> variants,
    List<String> warehouseIds,
  ) async {
    final inventories = await _inventoriesByVariantIdsAndWarehouses(
      variants.map((variant) => variant.id).toList(),
      warehouseIds,
    );

    return variants
        .map((variant) => variant.withInventoryData(inventories[variant.id]))
        .toList();
  }

  @override
  Stream<List<PackVariant>> getVariantsByProduct(String productId) async* {
    final snap = await _variantCollection
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .get();
    yield await _attachInventories(snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<List<PackVariant>> getVariantsByDeliveryType(
      String productId, DeliveryType deliveryType) async* {
    final variantsSnapshot = await _variantCollection
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .get();
    final variants = variantsSnapshot.docs.map(_fromDoc).toList();
    final inventories = await _inventoriesByVariantIds(
      variants.map((variant) => variant.id).toList(),
    );

    yield variants
        .map((variant) => variant.withInventoryData(inventories[variant.id]))
        .where((variant) => variant.supports(deliveryType))
        .toList();
  }

  @override
  Stream<List<PackVariant>> getVariantsByProductAndWarehouses(
      String productId, List<String> warehouseIds) async* {
    final snap = await _variantCollection
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .get();
    yield await _attachWarehouseInventories(
        snap.docs.map(_fromDoc).toList(), warehouseIds);
  }

  @override
  Stream<PackVariant?> getVariantById(String variantId) async* {
    final doc = await _variantCollection.doc(variantId).get();
    if (!doc.exists) {
      yield null;
    } else {
      final variant = _fromDoc(doc);
      final inventories = await _inventoriesByVariantIds([variant.id]);
      yield variant.withInventoryData(inventories[variant.id]);
    }
  }

  @override
  Stream<List<PackVariant>> getVariantsByIds(List<String> variantIds) async* {
    if (variantIds.isEmpty) {
      yield [];
      return;
    }
    // Firestore whereIn supports up to 30 items
    final chunks = <List<String>>[];
    for (var i = 0; i < variantIds.length; i += 30) {
      chunks.add(variantIds.sublist(
          i, i + 30 > variantIds.length ? variantIds.length : i + 30));
    }
    final results = <PackVariant>[];
    for (final chunk in chunks) {
      final snap = await _variantCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map(_fromDoc));
    }
    yield await _attachInventories(results);
  }

  @override
  Future<String> createVariant(PackVariant variant) async {
    final ref = _variantCollection.doc();
    await ref.set(variant.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateVariant(
      String variantId, Map<String, dynamic> data) async {
    await _variantCollection.doc(variantId).update(data);
  }

  @override
  Future<void> decrementStock(String variantId, int qty) async {
    await _firestore.runTransaction((tx) async {
      final inventoryQuery = await _inventories
          .where('variantId', isEqualTo: variantId)
          .limit(1)
          .get();
      if (inventoryQuery.docs.isEmpty) {
        throw Exception('Inventory for variant $variantId not found');
      }

      final ref = inventoryQuery.docs.first.reference;
      final snap = await tx.get(ref);
      final current =
          (snap.data() as Map<String, dynamic>)['stock'] as num? ?? 0;
      if (current < qty) {
        throw Exception(
            'Insufficient stock. Available: $current, Requested: $qty');
      }
      tx.update(ref, {'stock': current.toInt() - qty});
    });
  }

  @override
  Future<void> incrementStock(String variantId, int qty) async {
    final inventoryQuery = await _inventories
        .where('variantId', isEqualTo: variantId)
        .limit(1)
        .get();
    if (inventoryQuery.docs.isEmpty) return;

    await inventoryQuery.docs.first.reference.update({
      'stock': FieldValue.increment(qty),
    });
  }

  @override
  Stream<List<PackVariant>> watchVariantsByProduct(String productId) {
    return _variantCollection
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap(
            (snap) => _attachInventories(snap.docs.map(_fromDoc).toList()));
  }

  /// One cheap limit(1) query per DeliveryType value to discover what's live.
  @override
  Stream<List<DeliveryType>> watchAvailableDeliveryTypes() async* {
    final available = <DeliveryType>[];
    for (final type in DeliveryType.values) {
      final snap = await _inventories
          .where('availableDeliveryTypes', arrayContains: type.name)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) available.add(type);
    }
    yield available;
  }
}
