import 'package:sure_wholesaler/models/inventory_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/models/stock_alert_model.dart';
import 'package:sure_wholesaler/models/warehouse_model.dart';

// ---------------------------------------------------------------------------
// CatalogSeedData — Expanded Grocery Catalog (by Brand & Category)
//
// Categories:
//   1. Staples (cat_staples) -> Oils, Rice, Flour
//   2. Dairy (cat_dairy) -> Milk, Ghee
//   3. Beverages (cat_beverages) -> Tea, Coffee
//   4. Snacks (cat_snacks) -> Biscuits, Chips
//
// Brands:
//   Fortune, Amul, Tata, Britannia, Aashirvaad
// ---------------------------------------------------------------------------

class CatalogSeedData {
  CatalogSeedData._();

  static final DateTime _now = DateTime.now();
  static DateTime get now => _now;

  // ── Warehouse Constants ───────────────────────────────────────────────────

  static const String whPurnia = 'wh_purnia';
  static const _scheduledOnlyDelivery = [DeliveryType.scheduled];
  static const Map<String, List<DeliveryType>> _warehouseDeliveryTypes = {
    whPurnia: _scheduledOnlyDelivery,
  };

  // ── Delivery & Tax Configs ────────────────────────────────────────────────

  static const _quickDeliveryProfile = DeliveryChargeProfile(
    deliveryTypeApplied: 'KM',
    baseDeliveryCharge: 0,
    deliveryChargePerKm: 0,
    fixedDeliveryCharge: 0,
    fixedDeliveryChargeForKm: 0,
    freeDeliveryThreshold: 0,
    freeDeliveryDays: 0,
  );

  static const _scheduledDeliveryProfile = DeliveryChargeProfile(
    deliveryTypeApplied: 'KM',
    baseDeliveryCharge: 10,
    deliveryChargePerKm: 3,
    fixedDeliveryCharge: 20,
    fixedDeliveryChargeForKm: 12,
    freeDeliveryThreshold: 999,
    freeDeliveryDays: 0,
  );

  static const _deliveryConfig = WarehouseDeliveryConfig(
    scheduled: _scheduledDeliveryProfile,
    quick: _quickDeliveryProfile,
  );

  static const _scheduledDeliveryBoyProfile = DeliveryBoyChargeProfile(
    baseDeliveryCharge: 10,
    deliveryChargePerKm: 2,
    fixedDeliveryCharge: 20,
    fixedDeliveryChargeForKm: 10,
    deliveryCharge: 20,
    estimatedDeliveryBoyPayout: 18,
  );

  static const _deliveryBoyConfig = WarehouseDeliveryBoyConfig(
    scheduled: _scheduledDeliveryBoyProfile,
    quick: DeliveryBoyChargeProfile(
      baseDeliveryCharge: 0,
      deliveryChargePerKm: 0,
      fixedDeliveryCharge: 0,
      fixedDeliveryChargeForKm: 0,
      deliveryCharge: 0,
      estimatedDeliveryBoyPayout: 0,
    ),
  );

  static const _taxConfig = WarehouseTaxConfig(
    gstPercentage: 5,
    handlingCharge: 10,
    paymentGatewayChargePercentage: 2,
    platformCharge: 5,
  );

  // ── Warehouses ─────────────────────────────────────────────────────────────

  static final List<Warehouse> warehouses = [
    _w(
      id: whPurnia,
      name: 'Purnia Hub',
      latitude: 25.7771,
      longitude: 87.4753,
      scheduledDeliveryRadius: 5000,
      quickdeliveryRadiusKm: 570,
    ),
  ];

  // ── Image URLs ─────────────────────────────────────────────────────────────
// ───────────────── IMAGE URLS ─────────────────

  static const String _iphoneImg =
      'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400';

  static const String _laptopImg =
      'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400';

  static const String _headphoneImg =
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400';

  static const String _shoeImg =
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400';

  static const String _watchImg =
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400';

  static const String _chairImg =
      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400';

  static const String _faceImg =
      'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400';

// ───────────────── VARIANTS ─────────────────

  static final List<PackVariant> variants = [
    // Apple iPhone
    _v(
      'iphone_128',
      'prod_iphone',
      'IPH15-128',
      {'storage': '128GB', 'color': 'Black'},
      69999,
      79999,
      200,
      1,
      _iphoneImg,
    ),

    _v(
      'iphone_256',
      'prod_iphone',
      'IPH15-256',
      {'storage': '256GB', 'color': 'Blue'},
      79999,
      89999,
      200,
      1,
      _iphoneImg,
    ),

    // Samsung Laptop
    _v(
      'laptop_8',
      'prod_laptop',
      'GALBOOK-8',
      {'ram': '8GB', 'storage': '512GB'},
      54999,
      64999,
      1500,
      1,
      _laptopImg,
    ),

    _v(
      'laptop_16',
      'prod_laptop',
      'GALBOOK-16',
      {'ram': '16GB', 'storage': '1TB'},
      69999,
      79999,
      1500,
      1,
      _laptopImg,
    ),

    // Sony Headphone
    _v(
      'sony_headphone',
      'prod_headphone',
      'SONY-WH1000',
      {'type': 'Wireless'},
      8999,
      11999,
      300,
      1,
      _headphoneImg,
    ),

    // Nike Shoes
    _v(
      'nike_42',
      'prod_shoes',
      'NIKE-42',
      {'size': '42'},
      4999,
      6999,
      800,
      1,
      _shoeImg,
    ),

    // Samsung Watch
    _v(
      'watch_black',
      'prod_watch',
      'WATCH-BLK',
      {'color': 'Black'},
      4999,
      6999,
      100,
      1,
      _watchImg,
    ),

    // IKEA Chair
    _v(
      'chair_grey',
      'prod_chair',
      'IKEA-CHAIR',
      {'color': 'Grey'},
      7999,
      9999,
      5000,
      1,
      _chairImg,
    ),

    // Loreal Beauty
    _v(
      'facewash',
      'prod_facewash',
      'LOR-FACE',
      {'size': '100ml'},
      499,
      699,
      100,
      1,
      _faceImg,
    ),
  ];

  // ── Products ───────────────────────────────────────────────────────────────

// ───────────────── PRODUCTS ─────────────────

  static final List<ProductModel> products = [
// Electronics > Mobiles > Apple

    _p(
      id: 'prod_iphone',
      name: 'Apple iPhone 15',
      sku: 'IPH15',
      cat: 'cat_electronics',
      sub: 'mobiles',
      brandId: 'brand_apple',
      brandName: 'Apple',
      desc: 'Latest Apple smartphone.',
      img: _iphoneImg,
      tags: ['iphone', 'mobile', 'smartphone'],
      opts: {
        'storage': ['128GB', '256GB'],
        'color': ['Black', 'Blue']
      },
      categoryName: 'cat_electronics',
      subCategoryName: 'mobile',
    ),

// Electronics > Laptop > Samsung

    _p(
      id: 'prod_laptop',
      name: 'Samsung Galaxy Book',
      sku: 'GALBOOK',
      cat: 'cat_electronics',
      sub: 'laptops',
      brandId: 'brand_samsung',
      brandName: 'Samsung',
      desc: 'Premium performance laptop.',
      img: _laptopImg,
      tags: ['laptop', 'computer'],
      opts: {
        'ram': ['8GB', '16GB'],
        'storage': ['512GB', '1TB']
      },
      categoryName: 'electronics',
      subCategoryName: 'laptops',
    ),

// Electronics > Accessories > Sony

    _p(
      id: 'prod_headphone',
      name: 'Sony Wireless Headphone',
      sku: 'SONY-WH',
      cat: 'cat_electronics',
      sub: 'accessories',
      brandId: 'brand_sony',
      brandName: 'Sony',
      desc: 'Noise cancellation headphones.',
      img: _headphoneImg,
      tags: ['audio', 'headphone'],
      opts: {
        'type': ['Wireless']
      },
      categoryName: 'Electronics',
      subCategoryName: 'Accessories',
    ),

// Fashion > Footwear > Nike

    _p(
      id: 'prod_shoes',
      name: 'Nike Air Shoes',
      sku: 'NIKE-AIR',
      cat: 'cat_fashion',
      sub: 'footwear',
      brandId: 'brand_nike',
      brandName: 'Nike',
      desc: 'Sports running shoes.',
      img: _shoeImg,
      tags: ['shoes', 'fashion'],
      opts: {
        'size': ['42']
      },
      categoryName: 'Fashion',
      subCategoryName: 'Footwear',
    ),

// Electronics > Wearables > Samsung

    _p(
      id: 'prod_watch',
      name: 'Samsung Smart Watch',
      sku: 'SM-WATCH',
      cat: 'cat_electronics',
      sub: 'wearables',
      brandId: 'brand_samsung',
      brandName: 'Samsung',
      desc: 'Smart health watch.',
      img: _watchImg,
      tags: ['watch', 'smart'],
      opts: {
        'color': ['Black']
      },
      categoryName: 'Electronics',
      subCategoryName: 'Wearables',
    ),

// Home > Furniture > IKEA

    _p(
      id: 'prod_chair',
      name: 'IKEA Office Chair',
      sku: 'IKEA-CHAIR',
      cat: 'cat_home',
      sub: 'furniture',
      brandId: 'brand_ikea',
      brandName: 'IKEA',
      desc: 'Ergonomic office chair.',
      img: _chairImg,
      tags: ['chair', 'furniture'],
      opts: {
        'color': ['Grey']
      },
      categoryName: 'Home',
      subCategoryName: 'Furniture',
    ),

// Beauty > Skincare > Loreal

    _p(
      id: 'prod_facewash',
      name: 'Loreal Face Wash',
      sku: 'LOR-FACE',
      cat: 'cat_beauty',
      sub: 'skincare',
      brandId: 'brand_loreal',
      brandName: 'L’Oreal',
      desc: 'Daily skincare cleanser.',
      img: _faceImg,
      tags: ['beauty', 'skincare'],
      opts: {
        'size': ['100ml']
      },
      categoryName: 'Beauty',
      subCategoryName: 'Skincare',
    ),
  ];

  // ── Builders & Helpers ────────────────────────────────────────────────────

  static PackVariant _v(
    String id,
    String productId,
    String sku,
    Map<String, String> attrs,
    double price,
    double mrp,
    double weight,
    int moq,
    String img,
  ) =>
      PackVariant(
        id: id,
        productId: productId,
        sku: sku,
        attributes: attrs,
        imageUrls: [img],
        price: price,
        mrp: mrp,
        weight: weight,
        weightUnit: 'g',
        pricingTiers: [
          PricingTier(minQty: moq, price: price),
          PricingTier(minQty: moq * 2, price: (price * 0.98).floorToDouble()),
        ],
        moq: moq,
        isActive: true,
        inventory: null,
        packSize: 1,
        stock: 100,
        minStockAlert: 10,
        createdAt: _now,
        updatedAt: _now,
      );

  static ProductModel _p({
    required String id,
    required String name,
    required String sku,
    required String cat,
    required String sub,
    required String brandId,
    required String brandName,
    required String desc,
    required String img,
    required String categoryName,
    required String subCategoryName,
    required List<String> tags,
    required Map<String, List<String>> opts,
  }) =>
      ProductModel(
        id: id,
        name: name,
        sku: sku,
        categoryId: cat,
        subCategoryId: sub,
        unit: 'Unit',
        brandId: brandId,
        brandName: brandName,
        supplierId: 'supplier_001',
        description: desc,
        imageUrls: [img],
        isActive: true,
        isStoryItem: false,
        gstRate: '5%',
        hsnCode: '0000',
        tags: tags,
        specifications: const {'Shelf Life': '6 Months', 'Origin': 'India'},
        selectableOptions: opts,
        variantIds:
            variants.where((v) => v.productId == id).map((v) => v.id).toList(),
        packVariants: const [],
        createdAt: _now,
        updatedAt: _now,
        categoryName: categoryName,
        subCategoryName: subCategoryName,
      );

  static final List<Inventory> inventories = [
    for (final whEntry in _warehouseDeliveryTypes.entries)
      for (final variant in variants)
        _inventoryFor(variant.id, whEntry.key, deliveryTypes: whEntry.value),
  ];

  static Inventory _inventoryFor(
    String variantId,
    String warehouseId, {
    List<DeliveryType> deliveryTypes = const [DeliveryType.scheduled],
  }) {
    final variant = variants.firstWhere((v) => v.id == variantId);
    return Inventory(
      id: '${warehouseId}_$variantId',
      warehouseId: warehouseId,
      variantId: variantId,
      stock: variant.stock,
      isAvailable: true,
      minStockAlert: variant.minStockAlert,
      availableDeliveryTypes: deliveryTypes,
      subscriptionDeliveryTypes: const [],
      createdAt: _now,
      updatedAt: _now,
    );
  }

  static Warehouse _w({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    double quickdeliveryRadiusKm = 70,
    double scheduledDeliveryRadius = 5000,
    bool isActive = true,
  }) =>
      Warehouse(
        id: id,
        name: name,
        imageUrl: '',
        latitude: latitude,
        longitude: longitude,
        isActive: isActive,
        openingTime: '06:00',
        closingTime: '22:00',
        minimumOrderValue: 50,
        maximumOrderValue: 10000,
        maxItemsPerOrder: 50,
        autoAcceptOrders: true,
        orderAutoCancelTimeMinutes: 15,
        quickdeliveryRadiusKm: quickdeliveryRadiusKm,
        scheduledDeliveryRadius: scheduledDeliveryRadius,
        deliveryConfig: _deliveryConfig,
        deliveryBoyConfig: _deliveryBoyConfig,
        taxConfig: _taxConfig,
        createdAt: _now,
        updatedAt: _now,
      );

  static final List<StockAlertModel> stockAlerts = [];
}
