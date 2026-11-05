import 'package:sure_wholesaler/notifiers/category_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/models/pack_variant_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';
import 'package:sure_wholesaler/widgets/NoProductWidget.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/widgets/Product_Card_Widget.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';
import 'package:sure_wholesaler/widgets/components.dart';

import '../../core/constants/app_constants.dart';
import '../../services/warehouse_service.dart';

enum ProductSort {
  popularity,
  newest,
  priceLowToHigh,
  priceHighToLow,
  discountHighToLow,
}

class ProductFilter {
  RangeValues? priceRange;
  int? minDiscount;
  bool inStock = false;
  bool expressDelivery = false;
  List<String> selectedBrands = [];

  bool get hasActiveFilters => priceRange != null || minDiscount != null || inStock || expressDelivery || selectedBrands.isNotEmpty;

  void reset() {
    priceRange = null;
    minDiscount = null;
    inStock = false;
    expressDelivery = false;
    selectedBrands = [];
  }
}

class CategoryItems extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? brandId;
  final String? brandName;
  final String? initialSortBy;
  final int? initialMinDiscount;
  final bool? initialInStock;
  final bool? initialExpressDelivery;
  final RangeValues? initialPriceRange;

  const CategoryItems({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.brandName,
    this.brandId,
    this.initialSortBy,
    this.initialMinDiscount,
    this.initialInStock,
    this.initialExpressDelivery,
    this.initialPriceRange,
  });

  @override
  ConsumerState<CategoryItems> createState() => _CategoryItemsState();
}

class _CategoryItemsState extends ConsumerState<CategoryItems> {
  late String _sortBy;
  bool _isGridView = true;
  late final ProductFilter _filter;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy ?? 'Popularity';
    _filter = ProductFilter();
    _selectedSubcategoryId = widget.subcategoryId;

    if (widget.initialMinDiscount != null) {
      _filter.minDiscount = widget.initialMinDiscount;
    }
    if (widget.initialInStock != null) {
      _filter.inStock = widget.initialInStock!;
    }
    if (widget.initialExpressDelivery != null) {
      _filter.expressDelivery = widget.initialExpressDelivery!;
    }
    if (widget.initialPriceRange != null) {
      _filter.priceRange = widget.initialPriceRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('CategoryItems → brandId: ${widget.brandId}, categoryId: ${widget.categoryId}');
    }

    final productsAsync = widget.brandId != null
        ? ref.watch(productsByBrandStreamProvider(widget.brandId!))
        : widget.categoryId == 'all'
            ? ref.watch(allActiveProductsStreamProvider)
            : _selectedSubcategoryId != null
                ? ref.watch(
                    productsBySubcategoryStreamProvider(
                      SubcategoryParams(
                        categoryId: widget.categoryId,
                        subcategoryId: _selectedSubcategoryId!,
                      ),
                    ),
                  )
                : ref.watch(productsByCategoryStreamProvider(widget.categoryId));

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (products) {
          final filteredProducts = _filterProducts(products);
          final sortedProducts = _sortProducts(filteredProducts);

          if (products.isEmpty) {
            return const NoProductWidget();
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              _buildFilterBar(context, sortedProducts.length, products),
              _buildActiveFilters(context),
              SubCategoryChips(
                categoryId: widget.categoryId,
                selectedSubcategoryId: _selectedSubcategoryId,
                onSelected: (id) => setState(() => _selectedSubcategoryId = id),
              ),
              if (sortedProducts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No products match your filters'),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(8.w),
                  sliver: _isGridView ? _buildGridView(sortedProducts) : _buildListView(sortedProducts),
                ),
            ],
          );
        },
      ),
    );
  }

  // ================= APP BAR =================
  SliverAppBar _buildAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      title: Text(
        widget.brandName ?? widget.categoryName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: scheme.onPrimary,
        ),
      ),
      backgroundColor: scheme.primary,
      floating: true,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: scheme.onPrimary),
          onPressed: () {
            context.push('/search');
          },
        ),
        IconButton(
          icon: Icon(
            _isGridView ? Icons.list : Icons.grid_view,
            color: scheme.onPrimary,
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
      ],
    );
  }

  // ================= FILTER BAR =================
  SliverToBoxAdapter _buildFilterBar(BuildContext context, int count, List<ProductModel> allProducts) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$count Products',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            _buildFilterButton(context, allProducts),
            SizedBox(width: 8.w),
            _buildSortDropdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, List<ProductModel> allProducts) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasFilters = _filter.hasActiveFilters;

    return InkWell(
      onTap: () => _showFilterBottomSheet(context, allProducts),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFilters ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8.r),
          color: hasFilters ? scheme.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 16.sp,
              color: hasFilters ? scheme.primary : null,
            ),
            SizedBox(width: 4.w),
            Text(
              'Filter',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
                color: hasFilters ? scheme.primary : null,
              ),
            ),
            if (hasFilters) ...[
              SizedBox(width: 4.w),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Flexible(
      flex: 3,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _sortBy,
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, size: 18.sp),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
              color: scheme.onSurface,
            ),
            items: const [
              'Popularity',
              'Newest',
              'Price: Low to High',
              'Price: High to Low',
              'Discount: High to Low',
            ]
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
          ),
        ),
      ),
    );
  }

  // ================= ACTIVE FILTERS =================
  SliverToBoxAdapter _buildActiveFilters(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeChips = <Widget>[];

    if (_filter.priceRange != null) {
      activeChips.add(_activeFilterChip(
        '${AppConfig.currencySymbol}${_filter.priceRange!.start.round()} - ${AppConfig.currencySymbol}${_filter.priceRange!.end.round()}',
        () => setState(() => _filter.priceRange = null),
      ));
    }

    if (_filter.minDiscount != null) {
      activeChips.add(_activeFilterChip(
        '${_filter.minDiscount}%+ Discount',
        () => setState(() => _filter.minDiscount = null),
      ));
    }

    if (_filter.inStock) {
      activeChips.add(_activeFilterChip(
        'In Stock',
        () => setState(() => _filter.inStock = false),
      ));
    }

    if (_filter.expressDelivery) {
      activeChips.add(_activeFilterChip(
        'Express',
        () => setState(() => _filter.expressDelivery = false),
      ));
    }

    for (final brand in _filter.selectedBrands) {
      activeChips.add(_activeFilterChip(
        brand,
        () => setState(() => _filter.selectedBrands.remove(brand)),
      ));
    }

    if (activeChips.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        height: 40.h,
        margin: EdgeInsets.only(top: 10.h),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          scrollDirection: Axis.horizontal,
          itemCount: activeChips.length + 1,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Center(
                child: InkWell(
                  onTap: () => setState(() => _filter.reset()),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: scheme.error,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              );
            }
            return activeChips[index - 1];
          },
        ),
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onDelete) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500)),
      deleteIcon: Icon(Icons.close_rounded, size: 14.sp),
      onDeleted: onDelete,
      backgroundColor: scheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      side: BorderSide(color: scheme.primary.withOpacity(0.2)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: EdgeInsets.only(left: 4.w, right: 0),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }

  // ================= GRID VIEW =================
  Widget _buildGridView(List<ProductModel> products) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Changed from 4 to 2 to show products clearly
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.72, // Optimized ratio for 2 columns
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return ProductCardWidget(
            product: product,
            onTap: () => _onProductTap(product),
            onAddToCart: () => _onAddToCart(product),
          );
        },
        childCount: products.length,
      ),
    );
  }

  // ================= LIST VIEW =================
  Widget _buildListView(List<ProductModel> products) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: ProductCardWidget(
              product: product,
              onTap: () => _onProductTap(product),
              onAddToCart: () => _onAddToCart(product),
              layout: ProductCardLayout.list,
            ),
          );
        },
        childCount: products.length,
      ),
    );
  }

  // ================= SORT & FILTER =================
  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (!_filter.hasActiveFilters) return products;

    final filtered = products.where((p) {
      final variants = p.activePackVariants;
      if (variants.isEmpty) return false;

      // Price Filter: Using cleanPrice (human-readable price)
      if (_filter.priceRange != null) {
        final price = p.cleanPrice;
        if (price < _filter.priceRange!.start || price > _filter.priceRange!.end) {
          return false;
        }
      }

      // Discount Filter: Check if any active variant meets the minimum discount
      if (_filter.minDiscount != null) {
        final hasEnoughDiscount = variants.any((v) => (v.discountPercent ?? 0) >= _filter.minDiscount!);
        if (!hasEnoughDiscount) return false;
      }

      // Stock Filter: Check if any active variant is in stock
      if (_filter.inStock) {
        final isInStock = variants.any((v) => v.stock > 0);
        if (!isInStock) return false;
      }

      // Express Delivery Filter
      if (_filter.expressDelivery) {
        final isExpress = variants.any((v) => v.isQuickAvailable);
        if (!isExpress) return false;
      }

      // Brand Filter: Case-insensitive match on brandName or Tags
      if (_filter.selectedBrands.isNotEmpty) {
        final pBrand = p.brandName?.trim().toLowerCase();
        final pTags = p.tags.map((t) => t.trim().toLowerCase()).toList();

        final matches = _filter.selectedBrands.any((selected) {
          final s = selected.trim().toLowerCase();
          return s == pBrand || pTags.contains(s);
        });

        if (!matches) return false;
      }

      return true;
    }).toList();

    if (kDebugMode) {
      debugPrint('Filtered products: ${products.length} -> ${filtered.length}');
    }

    return filtered;
  }

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    final list = List<ProductModel>.from(products);

    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => a.cleanPrice.compareTo(b.cleanPrice));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.cleanPrice.compareTo(a.cleanPrice));
        break;
      case 'Discount: High to Low':
        list.sort((a, b) => (b.discountPercent ?? 0).compareTo(a.discountPercent ?? 0));
        break;
      case 'Newest':
      case 'Newest First':
        list.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'Popularity':
      default:
        // Default Firestore order or some other metric
        break;
    }

    return list;
  }

  // ================= FILTER BOTTOM SHEET =================
  void _showFilterBottomSheet(BuildContext context, List<ProductModel> allProducts) {
    // Determine dynamic max price for the slider
    double maxP = 2000;
    for (var p in allProducts) {
      if (p.cleanPrice > maxP) maxP = p.cleanPrice;
    }
    // Round up to nearest 500
    maxP = ((maxP / 500).ceil() * 500).toDouble();

    final brands = allProducts.map((p) => p.brandName?.trim()).whereType<String>().where((b) => b.isNotEmpty).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        filter: _filter,
        availableBrands: brands,
        maxPrice: maxP,
        onApply: () => setState(() {}),
      ),
    );
  }

  // ================= ACTIONS =================
  void _onProductTap(ProductModel product) {
    context.push('/product/${product.id}', extra: product);
  }

  void _onAddToCart(ProductModel product) {
    final activeVariants = product.activePackVariants;
    if (activeVariants.isEmpty) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'No pack variants available',
      );
      return;
    }

    final variant = activeVariants.first;
    if (variant.stock <= 0) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'This product is out of stock',
      );
      return;
    }

    final deliveryType = variant.availableDeliveryTypes.isNotEmpty ? variant.availableDeliveryTypes.first : DeliveryType.quick;
    final warehouseId = variant.inventory?.warehouseId ??
        ref.read(cartProvider).value?.warehouseId ??
        ref.read(resolvedWarehouseProvider).firstOrNull ??
        'default';
    ref.read(cartProvider.notifier).addToCart(
          CartItem.fromVariant(variant: variant, deliveryType: deliveryType, warehouseId: warehouseId),
        );

    AppNotifications.showPremiumNotification(
      context,
      title: 'Success',
      message: '${product.name} (Pack of ${variant.packSize}) added to cart',
      buttonLabel: 'VIEW CART',
      onButtonPressed: () {
        final tab = deliveryType == DeliveryType.scheduled ? 1 : 0;
        context.push('/cart?tab=$tab');
      },
    );
  }
}

class SubCategoryChips extends ConsumerWidget {
  final String? categoryId;
  final String? selectedSubcategoryId;
  final Function(String?) onSelected;

  const SubCategoryChips({
    this.categoryId,
    this.selectedSubcategoryId,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null || categoryId == 'all') return const SliverToBoxAdapter(child: SizedBox.shrink());

    final subcategories = ref.watch(subcategoriesProvider(categoryId!));

    if (subcategories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        height: 44.h,
        margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          scrollDirection: Axis.horizontal,
          itemCount: subcategories.length + 1,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            if (index == 0) {
              final isSelected = selectedSubcategoryId == null;
              return AppChip(
                label: 'All',
                isSelected: isSelected,
                onTap: () => onSelected(null),
              );
            }
            final sub = subcategories[index - 1];
            final isSelected = selectedSubcategoryId == sub.docId;
            return AppChip(
              label: sub.name,
              isSelected: isSelected,
              onTap: () => onSelected(sub.docId),
            );
          },
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final ProductFilter filter;
  final List<String> availableBrands;
  final double maxPrice;
  final VoidCallback onApply;

  const _FilterBottomSheet({
    required this.filter,
    required this.availableBrands,
    required this.maxPrice,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late RangeValues _currentRange;
  late int? _selectedDiscount;
  late bool _inStock;
  late bool _expressOnly;
  late List<String> _selectedBrands;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.filter.priceRange ?? RangeValues(0, widget.maxPrice);
    _selectedDiscount = widget.filter.minDiscount;
    _inStock = widget.filter.inStock;
    _expressOnly = widget.filter.expressDelivery;
    _selectedBrands = List.from(widget.filter.selectedBrands);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentRange = RangeValues(0, widget.maxPrice);
                    _selectedDiscount = null;
                    _inStock = false;
                    _expressOnly = false;
                    _selectedBrands = [];
                  });
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: 16.h),

          // Price Range
          Text(
            'Price Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            values: _currentRange,
            min: 0,
            max: widget.maxPrice,
            divisions: (widget.maxPrice / 50).floor(),
            labels: RangeLabels(
              '${AppConfig.currencySymbol}${_currentRange.start.round()}',
              '${AppConfig.currencySymbol}${_currentRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() => _currentRange = values);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${AppConfig.currencySymbol}${_currentRange.start.round()}'),
              Text('${AppConfig.currencySymbol}${_currentRange.end.round()}${_currentRange.end >= widget.maxPrice ? "+" : ""}'),
            ],
          ),
          SizedBox(height: 24.h),

          // Discount
          Text(
            'Minimum Discount',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            children: [10, 20, 30, 40, 50].map((d) {
              final isSelected = _selectedDiscount == d;
              return AppChip(
                label: '$d%+',
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedDiscount = isSelected ? null : d);
                },
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),

          // Toggles
          SwitchListTile(
            title: const Text('In Stock Only'),
            value: _inStock,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _inStock = val),
          ),
          SwitchListTile(
            title: const Text('Express Delivery (Quick)'),
            value: _expressOnly,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _expressOnly = val),
          ),
          SizedBox(height: 24.h),

          // Brands
          if (widget.availableBrands.isNotEmpty) ...[
            Text(
              'Brands',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: widget.availableBrands.map((brand) {
                final isSelected = _selectedBrands.contains(brand);
                return AppChip(
                  label: brand,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedBrands.remove(brand);
                      } else {
                        _selectedBrands.add(brand);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
          ],

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Apply Filters',
              onPressed: () {
                widget.filter.priceRange = _currentRange;
                widget.filter.minDiscount = _selectedDiscount;
                widget.filter.inStock = _inStock;
                widget.filter.expressDelivery = _expressOnly;
                widget.filter.selectedBrands = _selectedBrands;
                widget.onApply();
                context.pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
