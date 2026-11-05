import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/data_push/brand_data_push.dart';
import 'package:sure_wholesaler/core/data_push/categoty_data_push.dart';
import 'package:sure_wholesaler/core/data_push/coupon_data_push.dart';
import 'package:sure_wholesaler/core/data_push/inventory_data_push.dart';
import 'package:sure_wholesaler/core/data_push/product_data_push.dart';
import 'package:sure_wholesaler/core/data_push/pushandcleardata.dart';
import 'package:sure_wholesaler/core/data_push/slider_data_push.dart';
import 'package:sure_wholesaler/core/data_push/stock_alert_data_push.dart';
import 'package:sure_wholesaler/core/data_push/warehouse_data_push.dart';

class DataPushScreen extends StatefulWidget {
  const DataPushScreen({super.key});

  @override
  State<DataPushScreen> createState() => _DataPushScreenState();
}

class _DataPushScreenState extends State<DataPushScreen> {
  bool _isRunning = false;
  final List<_LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  void _log(String message, {_LogType type = _LogType.info}) {
    setState(() {
      _logs.add(_LogEntry(message: message, type: type, time: DateTime.now()));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runWithGuard(Future<void> Function() task) async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _logs.clear();
    });
    try {
      await task();
      _log('Done!', type: _LogType.success);
    } catch (e) {
      _log('Error: $e', type: _LogType.error);
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _pushAll() => _runWithGuard(() async {
        _log('Clearing all collections...');
        await Pushandcleardata().clearAllSeedCollections();
        _log('Collections cleared', type: _LogType.success);

        _log('Pushing categories...');
        await CategoryDataPush().pushCategories();
        _log('Categories done', type: _LogType.success);

        _log('Pushing brands...');
        await BrandDataPush().pushBrands();
        _log('Brands done', type: _LogType.success);

        _log('Pushing warehouses...');
        await WarehouseDataPush().pushWarehouses();
        _log('Warehouses done', type: _LogType.success);

        _log('Pushing products & variants...');
        await ProductDataPush().pushProductsAndVariants();
        _log('Products & variants done', type: _LogType.success);

        _log('Pushing inventories...');
        await InventoryDataPush().pushInventories();
        _log('Inventories done', type: _LogType.success);

        _log('Pushing coupons...');
        await CouponDataPush().pushCoupons();
        _log('Coupons done', type: _LogType.success);

        _log('Pushing sliders...');
        await SliderDataPush().pushData();
        _log('Sliders done', type: _LogType.success);

        _log('Pushing stock alerts...');
        await StockAlertDataPush().pushStockAlerts();
        _log('Stock alerts done', type: _LogType.success);
      });

  Future<void> _clearAll() => _runWithGuard(() async {
        _log('Clearing all collections...');
        await Pushandcleardata().clearAllSeedCollections();
        _log('All cleared', type: _LogType.success);
      });

  Future<void> _migrateDefaultToAdminDb() => _runWithGuard(() async {
        final defaultDb = FirebaseFirestore.instance;
        final adminDb = AppConfig.firestore;

        final collections = [
          'brands',
          'carts',
          'categories',
          'orders',
          'products',
          'variants',
          'warehouses',
          'inventories',
          'coupons',
          'sliders',
          'stock_alerts',
          'users',
        ];

        for (final colName in collections) {
          _log('Migrating collection: $colName...');
          final snapshot = await defaultDb.collection(colName).get();
          if (snapshot.docs.isEmpty) {
            _log('Collection $colName is empty, skipping.', type: _LogType.info);
            continue;
          }

          const chunkSize = 400;
          for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
            final batch = adminDb.batch();
            final end = (i + chunkSize > snapshot.docs.length) ? snapshot.docs.length : i + chunkSize;
            
            for (final doc in snapshot.docs.sublist(i, end)) {
              batch.set(
                adminDb.collection(colName).doc(doc.id),
                doc.data(),
                SetOptions(merge: true),
              );
            }
            await batch.commit();
          }
          _log('Migrated $colName successfully', type: _LogType.success);
        }
        _log('All data successfully migrated from (default) to admineggstore!', type: _LogType.success);
      });

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Push (Admin)'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Action Buttons ──
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _isRunning ? null : _pushAll,
                  icon: _isRunning
                      ? FadeShimmer.round(
                          size: 18,
                          baseColor: Colors.white30,
                          highlightColor: Colors.white70,
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _isRunning ? 'Pushing...' : 'Push All Data',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _isRunning ? null : _migrateDefaultToAdminDb,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text(
                    'Migrate (default) ➔ admineggstore',
                    style: TextStyle(fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SectionButton(
                        label: 'Categories',
                        icon: Icons.category_outlined,
                        disabled: _isRunning,
                        onTap: () => _runWithGuard(() async {
                          _log('Pushing categories...');
                          await CategoryDataPush().pushCategories();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SectionButton(
                        label: 'Brands',
                        icon: Icons.branding_watermark_outlined,
                        disabled: _isRunning,
                        onTap: () => _runWithGuard(() async {
                          _log('Pushing brands...');
                          await BrandDataPush().pushBrands();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SectionButton(
                        label: 'Warehouses',
                        icon: Icons.warehouse_outlined,
                        disabled: _isRunning,
                        onTap: () => _runWithGuard(() async {
                          _log('Pushing warehouses...');
                          await WarehouseDataPush().pushWarehouses();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SectionButton(
                        label: 'Products',
                        icon: Icons.inventory_2_outlined,
                        disabled: _isRunning,
                        onTap: () => _runWithGuard(() async {
                          _log('Pushing products & variants...');
                          await ProductDataPush().pushProductsAndVariants();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SectionButton(
                        label: 'Inventory',
                        icon: Icons.storage_outlined,
                        disabled: _isRunning,
                        onTap: () => _runWithGuard(() async {
                          _log('Pushing inventories...');
                          await InventoryDataPush().pushInventories();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SectionButton(
                        label: 'Coupons',
                        icon: Icons.local_offer_outlined,
                        disabled: _isRunning,
                        onTap: () => _runWithGuard(() async {
                          _log('Pushing coupons...');
                          await CouponDataPush().pushCoupons();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isRunning ? null : _clearAll,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear All Collections'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Log Output ──
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Press "Push All Data" to seed Firestore',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) => _LogTile(entry: _logs[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  const _SectionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: disabled ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

enum _LogType { info, success, error }

class _LogEntry {
  final String message;
  final _LogType type;
  final DateTime time;

  _LogEntry({required this.message, required this.type, required this.time});
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;

  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.type) {
      _LogType.success => (Icons.check_circle_outline, Colors.green),
      _LogType.error => (Icons.error_outline, Colors.red),
      _LogType.info => (Icons.chevron_right, Colors.grey.shade600),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            '${entry.time.hour.toString().padLeft(2, '0')}:'
            '${entry.time.minute.toString().padLeft(2, '0')}:'
            '${entry.time.second.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
