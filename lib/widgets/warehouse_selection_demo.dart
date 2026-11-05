// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sure_wholesaler/models/warehouse_model.dart';
// import 'package:sure_wholesaler/services/location_aware_cart_service.dart';
// import 'package:sure_wholesaler/services/product_availability_service.dart';
// import 'package:sure_wholesaler/services/warehouse_service.dart';
// import 'package:sure_wholesaler/widgets/app_loader.dart';

// /// Demo widget showing location-based warehouse selection
// class WarehouseSelectionDemo extends ConsumerWidget {
//   const WarehouseSelectionDemo({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final nearestWarehouse = ref.watch(nearestWarehouseProvider);
//     final availableWarehouses = ref.watch(userAvailableWarehousesProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Warehouse Selection Demo'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // User's nearest warehouse
//             Text(
//               'Location-Based Warehouse Selection',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 16),

//             // Nearest warehouse info
//             nearestWarehouse.when(
//               data: (warehouse) => warehouse != null
//                   ? _WarehouseCard(
//                       title: 'Your Nearest Warehouse',
//                       warehouse: warehouse,
//                       subtitle: 'Automatically selected for quick delivery',
//                     )
//                   : const Text('No warehouse found near your location'),
//               loading: () => const AppLoader(),
//               error: (error, stack) => Text('Error: $error'),
//             ),

//             const SizedBox(height: 24),

//             // All available warehouses
//             Text(
//               'All Available Warehouses',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 8),

//             availableWarehouses.when(
//               data: (warehouses) => warehouses.isNotEmpty
//                   ? Column(
//                       children: warehouses
//                           .map((warehouse) => _WarehouseCard(
//                                 title: warehouse.name,
//                                 warehouse: warehouse,
//                                 subtitle:
//                                     'Within ${warehouse.serviceRadiusKm}km radius',
//                               ))
//                           .toList(),
//                     )
//                   : const Text('No warehouses available in your area'),
//               loading: () => const AppLoader(),
//               error: (error, stack) => Text('Error: $error'),
//             ),

//             const SizedBox(height: 24),

//             // Cart info
//             Text(
//               'Cart Behavior',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               '• Items are automatically added to your nearest warehouse\n'
//               '• Separate carts maintained per warehouse\n'
//               '• Quick delivery only available within warehouse radius\n'
//               '• Scheduled delivery available from any warehouse',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _WarehouseCard extends StatelessWidget {
//   final String title;
//   final Warehouse warehouse;
//   final String subtitle;

//   const _WarehouseCard({
//     required this.title,
//     required this.warehouse,
//     required this.subtitle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 4),
//             Text(warehouse.name),
//             Text(
//               subtitle,
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: Colors.grey,
//                   ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.location_on, size: 16, color: Colors.blue),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${warehouse.latitude.toStringAsFixed(4)}, ${warehouse.longitude.toStringAsFixed(4)}',
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Example of how to use warehouse selection in product screens
// class ProductWithWarehouseSelection extends ConsumerWidget {
//   final String productId;

//   const ProductWithWarehouseSelection({
//     super.key,
//     required this.productId,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final availableWarehouses =
//         ref.watch(availableWarehousesForProductProvider(productId));

//     return availableWarehouses.when(
//       data: (warehouses) {
//         if (warehouses.isEmpty) {
//           return const Center(
//             child: Text('This product is not available in your area'),
//           );
//         }

//         return Column(
//           children: [
//             Text('Available at ${warehouses.length} warehouse(s):'),
//             ...warehouses.map((warehouseDistance) => ListTile(
//                   title: Text(warehouseDistance.warehouse.name),
//                   subtitle: Text(
//                       '${warehouseDistance.distanceKm.toStringAsFixed(1)} km away'),
//                   trailing: warehouseDistance.distanceKm <=
//                           warehouseDistance.warehouse.serviceRadiusKm
//                       ? const Icon(Icons.flash_on,
//                           color: Colors.green) // Quick delivery available
//                       : const Icon(Icons.schedule,
//                           color: Colors.blue), // Only scheduled
//                 )),
//           ],
//         );
//       },
//       loading: () => const AppLoader(),
//       error: (error, stack) => Text('Error: $error'),
//     );
//   }
// }
