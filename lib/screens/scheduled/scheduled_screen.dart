import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/screens/product/Products_Grid.dart';
import 'package:sure_wholesaler/widgets/components.dart';

class ScheduledScreen extends ConsumerStatefulWidget {
  const ScheduledScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ScheduledScreenState();
}

class _ScheduledScreenState extends ConsumerState<ScheduledScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
// load all the products and show them in a grid view with pagination and loading indicator at the bottom when loading more products

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Delivery'),
      ),
      body: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Search scheduled delivery products...',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),
            ProductsGrid(
              deliveryType: DeliveryType.scheduled,
              searchQuery: _searchQuery,
            ),
          ],
        ),
      ),
    );
  }
}
