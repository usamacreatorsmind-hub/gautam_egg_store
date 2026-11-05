import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/core/theme/theme_extension.dart';
import 'package:sure_wholesaler/notifiers/brand_notifier.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/widgets/components.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final theme = context.theme;
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryColor),
          ),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          title: Text(
            'Brands',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
              decorationColor: scheme.onSurface,
              decorationThickness: 1,
              decorationStyle: TextDecorationStyle.solid,
            ),
          ),
          actions: const [
            SizedBox(width: 48), // Balancing leading icon
          ]),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Search brands...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          Expanded(
            child: brands.when(
              loading: () => const Center(child: AppLoader()),
              error: (error, stackTrace) {
                if (kDebugMode == true) debugPrint('BrandsScreen error: $error');
                return Center(
                  child: Text(
                    'Something went wrong',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              },
              data: (data) {
                final filteredBrands = data.where((brand) => brand.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filteredBrands.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty ? 'No brands found' : 'No results for "$_searchQuery"',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  itemCount: filteredBrands.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final brand = filteredBrands[index];

                    return InkWell(
                      onTap: () {
                        context.push(
                          AppRoutes.categoryItemsPath('all'),
                          extra: {
                            'brandId': brand.id,
                            'brandName': brand.name,
                            'categoryName': brand.name,
                          },
                        );
                      },
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: brand.logoUrl != null && brand.logoUrl!.trim().isNotEmpty && brand.logoUrl!.startsWith('http')
                                    ? Image.network(
                                        brand.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _imageFallback(scheme),
                                      )
                                    : _imageFallback(scheme),
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            brand.name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Image fallback (theme-based)
  Widget _imageFallback(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.store,
          size: 42,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
