// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:sure_wholesaler/viewmodels/product_view_model.dart';
// import '../models/product_model.dart';

// class BrandProductsScreen extends StatelessWidget {
//   const BrandProductsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Brand products'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Product Grid - 2 columns
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 12,
//                   mainAxisSpacing: 16,
//                   childAspectRatio: 0.7,
//                 ),
//                 itemCount: 6, // Your image shows 6 products
//                 itemBuilder: (context, index) {
//                   // This would come from your ProductModel list
//                   // For now, using mock data based on your image
//                   return _buildProductCard(context, index);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProductCard(BuildContext context, int index) {
//     // Mock data based on your image
//     final List<Map<String, dynamic>> mockProducts = [
//       {
//         'name': '9am Super Gold Mixed Pickle 900g + Gas Ligh...',
//         'mrp': 197.00,
//         'price': 115.00,
//         'discountPercent': 41.62,
//         'delivery': '1-2 Days',
//         'offer': null,
//       },
//       {
//         'name': '9am Super Gold Mango Pickle 900g',
//         'mrp': 197.00,
//         'price': 115.00,
//         'discountPercent': 41.62,
//         'delivery': '1-2 Days',
//         'offer': null,
//       },
//       {
//         'name': '9am Tomato Ketchup 850g',
//         'mrp': 122.00,
//         'price': 57.00,
//         'discountPercent': 53.28,
//         'delivery': '1-2 Days',
//         'offer': null,
//       },
//       {
//         'name': '9am Baking Powder 100g',
//         'mrp': 38.00,
//         'price': 22.00,
//         'discountPercent': 42.11,
//         'delivery': '1-2 Days',
//         'offer': null,
//       },
//       {
//         'name': '9am Mixed Jam 2U x 450g',
//         'mrp': null,
//         'price': null,
//         'discountPercent': null,
//         'delivery': '1-2 Days',
//         'offer': 'Pack of 2',
//       },
//       {
//         'name': '9am Vanilla Custard Powder 100g + 35g Free',
//         'mrp': null,
//         'price': null,
//         'discountPercent': null,
//         'delivery': '1-2 Days',
//         'offer': null,
//       },
//     ];

//     final product = mockProducts[index];

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Delivery time badge
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: const BoxDecoration(
//               color: Color(0xFFE8F5E9),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(8),
//                 topRight: Radius.circular(8),
//               ),
//             ),
//             child: Text(
//               product['delivery'],
//               style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF2E7D32),
//               ),
//             ),
//           ),

//           // Product image placeholder
//           Container(
//             height: 100,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF5F5F5),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             margin: const EdgeInsets.all(8),
//             child: Center(
//               child: Icon(
//                 Icons.image,
//                 size: 40,
//                 color: Colors.grey[400],
//               ),
//             ),
//           ),

//           // Product name
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Text(
//               product['name'],
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 height: 1.3,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),

//           const SizedBox(height: 8),

//           // Offer tag if available
//           if (product['offer'] != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF8E1),
//                   borderRadius: BorderRadius.circular(4),
//                   border: Border.all(color: const Color(0xFFFFD54F), width: 0.5),
//                 ),
//                 child: Text(
//                   product['offer'],
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: Color(0xFFF57C00),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),

//           const Spacer(),

//           // Price section (only for products with price)
//           if (product['price'] != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text(
//                         'MRP ₹${product['mrp']!.toStringAsFixed(2)}',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: Colors.grey[600],
//                           decoration: TextDecoration.lineThrough,
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${product['discountPercent']!.toStringAsFixed(2)}%',
//                         style: const TextStyle(
//                           fontSize: 10,
//                           color: Color(0xFF4CAF50),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '₹${product['price']!.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black,
//                         ),
//                       ),
//                       Container(
//                         width: 60,
//                         height: 24,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF4CAF50),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: const Center(
//                           child: Text(
//                             'Add',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//           // For products without price (just delivery)
//           if (product['price'] == null)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//               child: Container(
//                 height: 24,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF5F5F5),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     'Add',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }

// // If you want to integrate with real data from ProductModel:
// class BrandProductsRealDataScreen extends StatefulWidget {
//   const BrandProductsRealDataScreen({super.key});

//   @override
//   State<BrandProductsRealDataScreen> createState() => _BrandProductsRealDataScreenState();
// }

// class _BrandProductsRealDataScreenState extends State<BrandProductsRealDataScreen> {
//   final ProductViewModel _viewModel = ProductViewModel();
//   List<ProductModel> _products = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   Future<void> _loadProducts() async {
//     await _viewModel.fetchProducts();
//     setState(() {
//       _products = _viewModel.products;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Brand products'),
//         centerTitle: true,
//       ),
//       body: _viewModel.isLoading
//           ? const Center(child: AppLoader())
//           : _viewModel.error != null
//               ? Center(child: Text('Error: ${_viewModel.error}'))
//               : _products.isEmpty
//                   ? const Center(child: Text('No products available'))
//                   : SingleChildScrollView(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             GridView.builder(
//                               shrinkWrap: true,
//                               physics: const NeverScrollableScrollPhysics(),
//                               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 crossAxisSpacing: 12,
//                                 mainAxisSpacing: 16,
//                                 childAspectRatio: 0.7,
//                               ),
//                               itemCount: _products.length,
//                               itemBuilder: (context, index) {
//                                 return _buildProductCardFromModel(_products[index]);
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//     );
//   }

//   Widget _buildProductCardFromModel(ProductModel product) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Delivery time badge (static for now)
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: const BoxDecoration(
//               color: Color(0xFFE8F5E9),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(8),
//                 topRight: Radius.circular(8),
//               ),
//             ),
//             child: const Text(
//               '1-2 Days',
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF2E7D32),
//               ),
//             ),
//           ),

//           // Product image
//           Container(
//             height: 100,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF5F5F5),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             margin: const EdgeInsets.all(8),
//             child: product.imageUrl != null && product.imageUrl!.isNotEmpty
//                 ? ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: Image.network(
//                       product.imageUrl!,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Center(
//                           child: Icon(
//                             Icons.image,
//                             size: 40,
//                             color: Colors.grey[400],
//                           ),
//                         );
//                       },
//                     ),
//                   )
//                 : Center(
//                     child: Icon(
//                       Icons.image,
//                       size: 40,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//           ),

//           // Product name
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Text(
//               product.name,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 height: 1.3,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),

//           const SizedBox(height: 8),

//           // Offer tag if available
//           if (product.offerDescription != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF8E1),
//                   borderRadius: BorderRadius.circular(4),
//                   border: Border.all(color: const Color(0xFFFFD54F), width: 0.5),
//                 ),
//                 child: Text(
//                   product.offerDescription!,
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: Color(0xFFF57C00),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),

//           const Spacer(),

//           // Price section
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (product.mrp != null)
//                   Row(
//                     children: [
//                       Text(
//                         'MRP ${product.formattedMRP}',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: Colors.grey[600],
//                           decoration: TextDecoration.lineThrough,
//                         ),
//                       ),
//                       if (product.discountPercent != null && product.discountPercent! > 0) ...[
//                         const SizedBox(width: 4),
//                         Text(
//                           '${product.discountPercent!.toStringAsFixed(2)}%',
//                           style: const TextStyle(
//                             fontSize: 10,
//                             color: Color(0xFF4CAF50),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       product.formattedPrice,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black,
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         // Add to cart logic here
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('Added ${product.name} to cart'),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         width: 60,
//                         height: 24,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF4CAF50),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: const Center(
//                           child: Text(
//                             'Add',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }
