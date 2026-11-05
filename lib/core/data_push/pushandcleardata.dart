import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/core/data_push/brand_data_push.dart';
import 'package:sure_wholesaler/core/data_push/cart_data_push.dart';
import 'package:sure_wholesaler/core/data_push/categoty_data_push.dart';
import 'package:sure_wholesaler/core/data_push/coupon_data_push.dart';
import 'package:sure_wholesaler/core/data_push/inventory_data_push.dart';
import 'package:sure_wholesaler/core/data_push/product_data_push.dart';
import 'package:sure_wholesaler/core/data_push/slider_data_push.dart';
import 'package:sure_wholesaler/core/data_push/stock_alert_data_push.dart';
import 'package:sure_wholesaler/core/data_push/warehouse_data_push.dart';

class Pushandcleardata {
  Future<void> pushandcleardata() async {
    try {
      debugPrint('=== Starting full data reset and seed ===');

      await clearAllSeedCollections();

      // ── Catalog (order matters: warehouses → variants → products → inventories)
      debugPrint('[1/9] Pushing warehouses...');
      await WarehouseDataPush().pushWarehouses();

      debugPrint('[2/9] Pushing products & pack variants...');
      await ProductDataPush().pushProductsAndVariants();

      debugPrint('[3/9] Pushing inventories...');
      await InventoryDataPush().pushInventories();

      debugPrint('[4/10] Pushing brands...');
      await BrandDataPush().pushBrands();

      // ── Supporting data
      debugPrint('[5/10] Pushing categories...');
      await CategoryDataPush().pushCategories();

      debugPrint('[6/10] Pushing coupons...');
      await CouponDataPush().pushCoupons();

      debugPrint('[7/10] Pushing stock alerts...');
      await StockAlertDataPush().pushStockAlerts();

      debugPrint('[8/10] Pushing sliders...');
      await SliderDataPush().pushData();

      debugPrint('[9/9] Pushing wallet data...');

      debugPrint('=== Full data push completed successfully ===');
    } catch (e, st) {
      debugPrint('Error during data push: $e\n$st');
      rethrow;
    }
  }

  /// Clears all seed collections in dependency order (dependents first).
  Future<void> clearAllSeedCollections() async {
    debugPrint('--- Clearing all collections ---');

    // Dependents first so foreign-key-like references are gone before parents
    debugPrint('  Clearing inventories...');
    await InventoryDataPush().clearInventories();

    debugPrint('  Clearing products & pack variants...');
    await ProductDataPush().clearProductsAndVariants();

    debugPrint('  Clearing brands...');
    await BrandDataPush().clearBrands();

    debugPrint('  Clearing warehouses...');
    await WarehouseDataPush().clearWarehouses();

    debugPrint('  Clearing categories...');
    await CategoryDataPush().clearCategories();

    debugPrint('  Clearing coupons...');
    await CouponDataPush().clearCoupons();

    debugPrint('  Clearing carts...');
    await CartDataPush().clearCarts();

    debugPrint('  Clearing stock alerts...');
    await StockAlertDataPush().clearStockAlerts();

    debugPrint('  Clearing sliders...');
    await SliderDataPush().clearData();

    // debugPrint('  Clearing wallet transactions...');
    // await WalletDataPushService().clearWalletTransactions();

    debugPrint('--- All collections cleared ---');
  }
}
