import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';

class ProductModel implements FirestoreModel {
  @override
  final String? id;

  // Core info
  final String name;
  final String sku;
  final String categoryId;
  final String subCategoryId;

  final String categoryName;
  final String subCategoryName;
  final String unit;

  // Brand
  final String brandId;
  final String? brandName;

  // Content
  final String? supplierId;
  final String? supplierName;
  final String? description;
  final List<String> imageUrls;
  final String? hsnCode;
  final String gstRate;

  // IDs of variant docs in the top-level `variants` collection
  final List<String> variantIds;

  // Wholesale pricing tiers at product level
  final List<PricingTier> pricingTiers;

  // Runtime-loaded variants (NOT stored in product doc, fetched separately)
  final List<PackVariant> packVariants;

  // Status & meta
  final bool isActive;
  final bool isStoryItem;

  /// Pre-computed list of available attribute options for UI filters
  /// e.g. {'colors': ['Red', 'Blue'], 'sizes': ['S', 'M', 'L']}
  final Map<String, List<String>> selectableOptions;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<String> tags;
  final Map<String, dynamic> specifications;

  // Offers
  final String? offerTitle;
  final String? offerBadgeText;
  final String? offerType;
  final int? offerBuyQty;
  final int? offerGetQty;
  final double? offerDiscountPct;

  const ProductModel({
    this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.subCategoryId,
    required this.unit,
    required this.variantIds,
    this.pricingTiers = const [],
    required this.packVariants,
    required this.isActive,
    required this.brandId,
    required this.brandName,
    required this.supplierId,
    this.supplierName,
    required this.description,
    required this.imageUrls,
    this.createdAt,
    this.updatedAt,
    required this.isStoryItem,
    required this.hsnCode,
    required this.gstRate,
    required this.tags,
    required this.specifications,
    required this.selectableOptions,
    required this.categoryName,
    required this.subCategoryName,
    this.offerTitle,
    this.offerBadgeText,
    this.offerType,
    this.offerBuyQty,
    this.offerGetQty,
    this.offerDiscountPct,
  });

  /* -------------------------------------------------------------------------- */
  /*                                  HELPERS                                   */
  /* -------------------------------------------------------------------------- */

  List<PackVariant> get activePackVariants => packVariants.where((v) => v.isActive).toList();

  PackVariant get defaultPackVariant => activePackVariants.isNotEmpty
      ? activePackVariants.first
      : packVariants.isNotEmpty
      ? packVariants.first
      : PackVariant.placeholder(id ?? '');

  PackVariant? getPackVariant(String variantId) {
    try {
      return packVariants.firstWhere((v) => v.id == variantId);
    } catch (_) {
      return null;
    }
  }

  /// Display helpers (NO extra price logic)
  double get displayPrice => defaultPackVariant.price;
  double? get displayMRP => defaultPackVariant.mrp;

  /* ---------- Convenience getters (delegate to defaultPackVariant) --------- */

  /// Selling price of the default pack variant (with fallback to basePrice)
  double get price => defaultPackVariant.price > 0 ? defaultPackVariant.price : 0.0; // Price will be handled by formatter

  /// MRP of the default pack variant (nullable)
  double? get mrp => defaultPackVariant.mrp;

  /// Available stock from the default pack variant (runtime value, populated
  /// by the repository from the corresponding Inventory record).
  int get currentStock => defaultPackVariant.stock;

  /// Low-stock alert threshold from the default pack variant (runtime value,
  /// populated by the repository from the corresponding Inventory record).
  int get minStockAlert => defaultPackVariant.minStockAlert;

  /// Discount percentage derived from MRP vs selling price
  double? get discountPercent {
    final m = mrp;
    if (m != null && m > price) {
      return ((m - price) / m) * 100;
    }
    return null;
  }

  /// The selling price (alias for [price])
  double get discountedPrice => price;

  double get cleanPrice => AppConfig.getCleanPrice(price);

  String get formattedPrice => AppConfig.formatPrice(price);
  String get formattedMRP => mrp != null ? AppConfig.formatPrice(mrp!) : '';

  /* -------------------------------------------------------------------------- */
  /*                              SERIALIZATION                                 */
  /* -------------------------------------------------------------------------- */

  factory ProductModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final productId = docId ?? data['id'] ?? '';

    // Naya images field - more robust parsing
    final dynamic rawImages = data['images'] ?? data['imageUrls'];
    List<String> imageUrls = [];
    if (rawImages is List) {
      imageUrls = rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      imageUrls = [rawImages];
    }

    // Pricing mapping
    final double basePrice = _parseNum(data['basePrice'] ?? data['price'] ?? 0.0).toDouble();
    final double mrp = _parseNum(data['mrp'] ?? basePrice * 1.2).toDouble();

    // Product-level tiers
    final List<PricingTier> productTiers = data['pricingTiers'] != null
        ? (data['pricingTiers'] as List).map((t) => PricingTier.fromMap(Map<String, dynamic>.from(t))).toList()
        : [];

    // Handling embedded pricingTiers or variants
    List<PackVariant> variants = [];
    if (data['variants'] != null && data['variants'] is List) {
      variants = (data['variants'] as List).map((e) {
        final v = Map<String, dynamic>.from(e);
        final rawPackSize = v['packSize'] ?? v['packQuantity'];
        int packSizeInt = _parseInt(rawPackSize);
        if (packSizeInt == 0) packSizeInt = 1;

        Map<String, String> attrs = v['attributes'] != null ? Map<String, String>.from(v['attributes'] as Map) : {};
        if (attrs.isEmpty && rawPackSize is String && rawPackSize.isNotEmpty && int.tryParse(rawPackSize) == null) {
          attrs = {'Size': rawPackSize};
        }

        List<PricingTier> tiers = v['pricingTiers'] != null
            ? (v['pricingTiers'] as List).map((t) => PricingTier.fromMap(Map<String, dynamic>.from(t))).toList()
            : [];

        // If this variant has no tiers, try to find matching tiers from productTiers by label
        if (tiers.isEmpty && productTiers.isNotEmpty) {
          final variantName = (attrs['Size'] ?? rawPackSize.toString()).toLowerCase().replaceAll(' ', '');
          tiers = productTiers.where((t) {
            final tierLabel = (t.label ?? '').toLowerCase().replaceAll(' ', '');
            // Check if one contains the other (e.g., "100" matches "100g")
            return tierLabel.contains(variantName) || variantName.contains(tierLabel);
          }).toList();
        }

        // Ensure a "1+" tier exists for UI consistency if there are other tiers
        if (tiers.isNotEmpty && !tiers.any((t) => t.minQty == 1)) {
          tiers.insert(0, PricingTier(minQty: 1, price: _parseNum(v['sellingPrice'] ?? v['price'] ?? basePrice).toDouble()));
        }
        tiers.sort((a, b) => a.minQty.compareTo(b.minQty));

        return PackVariant(
          id: v['id']?.toString() ?? '${productId}_${rawPackSize}',
          productId: productId,
          sku: v['sku']?.toString() ?? data['sku']?.toString() ?? '',
          price: _parseNum(v['sellingPrice'] ?? v['price'] ?? basePrice).toDouble(),
          mrp: _parseNum(v['mrp'] ?? mrp).toDouble(),
          stock: _parseInt(v['stock'] ?? data['currentStock'] ?? 100),
          isActive: v['isActive'] ?? true,
          packSize: packSizeInt,
          weightUnit: data['unit']?.toString() ?? 'pcs',
          attributes: attrs,
          imageUrls: imageUrls,
          pricingTiers: tiers,
          moq: _parseInt(v['moq'] ?? 1),
          inventory: null,
          minStockAlert: _parseInt(v['minStockAlert'] ?? data['minStockAlert'] ?? 0),
        );
      }).toList();
    }
    else if (productTiers.isNotEmpty) {
      // Legacy behavior where each tier is a variant
      variants = productTiers.map((tier) {
        return PackVariant(
          id: '${productId}_tier_${tier.minQty}',
          productId: productId,
          sku: data['sku']?.toString() ?? '',
          price: tier.price,
          mrp: mrp,
          stock: _parseInt(data['currentStock'] ?? 100),
          isActive: true,
          packSize: tier.minQty,
          weightUnit: data['unit']?.toString() ?? 'pcs',
          attributes: {},
          imageUrls: imageUrls,
          pricingTiers: productTiers,
          moq: tier.minQty,
          inventory: null,
          minStockAlert: _parseInt(data['minStockAlert'] ?? 0),
        );
      }).toList();
    }

    if (variants.isEmpty) {
      variants = [
        PackVariant(
          id: '${productId}_base',
          productId: productId,
          sku: data['sku']?.toString() ?? '',
          price: basePrice > 0 ? basePrice : _parseNum(data['price'] ?? 0).toDouble(),
          mrp: mrp,
          stock: _parseInt(data['currentStock'] ?? 100),
          isActive: true,
          packSize: 1,
          weightUnit: data['unit']?.toString() ?? 'pcs',
          attributes: {},
          imageUrls: imageUrls,
          pricingTiers: productTiers,
          moq: 1,
          inventory: null,
          minStockAlert: _parseInt(data['minStockAlert'] ?? 0),
        )
      ];
    }

    // Populate selectableOptions from variants
    final Map<String, List<String>> selectableOptions = {};
    for (final v in variants) {
      v.attributes.forEach((key, value) {
        if (!selectableOptions.containsKey(key)) {
          selectableOptions[key] = [];
        }
        if (!selectableOptions[key]!.contains(value)) {
          selectableOptions[key]!.add(value);
        }
      });
    }

    return ProductModel(
      id: productId.isNotEmpty ? productId : null,
      name: data['name']?.toString() ?? '',
      sku: data['sku']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      subCategoryId: data['subCategoryId']?.toString() ?? '',
      unit: data['unit']?.toString() ?? '',
      brandId: data['brandId']?.toString() ?? '',
      hsnCode: data['hsnCode']?.toString(),
      gstRate: data['gstRate']?.toString() ?? '0%',
      tags: List<String>.from(data['tags'] ?? []),
      specifications: data['specifications'] != null ? Map<String, dynamic>.from(data['specifications'] as Map) : const {},
      brandName: (data['brandName'] ?? data['brand'])?.toString(),
      supplierId: data['supplierId']?.toString(),
      supplierName: (data['supplierName'] ?? data['supplier'])?.toString(),
      description: data['description']?.toString(),
      imageUrls: imageUrls,
      isActive: data['isActive'] ?? true,
      isStoryItem: data['isStoryItem'] ?? false,
      variantIds: List<String>.from(data['variantIds'] ?? []),
      pricingTiers: productTiers,
      selectableOptions: selectableOptions.isNotEmpty
          ? selectableOptions
          : (data['selectableOptions'] != null
          ? (data['selectableOptions'] as Map).map((k, v) => MapEntry(k.toString(), List<String>.from(v)))
          : {}),
      packVariants: variants,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      categoryName: data['categoryName']?.toString() ?? '',
      subCategoryName: data['subCategoryName']?.toString() ?? '',
      offerTitle: data['offerTitle']?.toString(),
      offerBadgeText: data['offerBadgeText']?.toString(),
      offerType: data['offerType']?.toString(),
      offerBuyQty: _parseInt(data['offerBuyQty']),
      offerGetQty: _parseInt(data['offerGetQty']),
      offerDiscountPct: _parseNum(data['offerDiscountPct']).toDouble(),
    );
  }

  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Map<String, dynamic> toMap() => toFirestore();

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'sku': sku,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'unit': unit,
      'images': imageUrls,
      'basePrice': price,
      'isActive': isActive,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'isStoryItem': isStoryItem,
      'tags': tags,
      'specifications': specifications,
      'gstRate': gstRate,
      'updatedAt': DateTime.now().toIso8601String(),
      'pricingTiers': pricingTiers.map((t) => t.toMap()).toList(),
      if (brandId != null) 'brandId': brandId,
      if (brandName != null) 'brandName': brandName,
      if (supplierId != null) 'supplierId': supplierId,
      if (supplierName != null) 'supplierName': supplierName,
      if (description != null) 'description': description,
      if (hsnCode != null) 'hsnCode': hsnCode,
      if (offerTitle != null) 'offerTitle': offerTitle,
      if (offerBadgeText != null) 'offerBadgeText': offerBadgeText,
      if (offerType != null) 'offerType': offerType,
      if (offerBuyQty != null) 'offerBuyQty': offerBuyQty,
      if (offerGetQty != null) 'offerGetQty': offerGetQty,
      if (offerDiscountPct != null) 'offerDiscountPct': offerDiscountPct,
    };

    if (id == null || id!.isEmpty) {
      map['createdAt'] = DateTime.now().toIso8601String();
    }
    return map;
  }

  /// Returns a copy with variants attached (called by repository after fetching variants)
  ProductModel withVariants(List<PackVariant> variants) {
    return ProductModel(
      id: id,
      name: name,
      sku: sku,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      unit: unit,
      variantIds: variantIds,
      pricingTiers: pricingTiers,
      packVariants: variants,
      isActive: isActive,
      isStoryItem: isStoryItem,
      brandId: brandId,
      brandName: brandName,
      supplierId: supplierId,
      supplierName: supplierName,
      description: description,
      imageUrls: imageUrls,
      hsnCode: hsnCode,
      gstRate: gstRate,
      tags: tags,
      specifications: specifications,
      createdAt: createdAt,
      selectableOptions: selectableOptions,
      updatedAt: updatedAt,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      offerTitle: offerTitle,
      offerBadgeText: offerBadgeText,
      offerType: offerType,
      offerBuyQty: offerBuyQty,
      offerGetQty: offerGetQty,
      offerDiscountPct: offerDiscountPct,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               UTILITIES                                    */
  /* -------------------------------------------------------------------------- */

  static num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final p = int.tryParse(value);
      if (p != null) return p;
      final match = RegExp(r'(\d+)').firstMatch(value);
      if (match != null) return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanos = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
      if (seconds != null) {
        return Timestamp(seconds as int, nanos as int).toDate();
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, sku: $sku, categoryId: $categoryId, subCategoryId: $subCategoryId, unit: $unit, brandId: $brandId, brandName: $brandName, supplierId: $supplierId, description: $description, imageUrls: $imageUrls, packVariants: $packVariants, isActive: $isActive, isStoryItem: $isStoryItem, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
