import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:sure_wholesaler/models/category_model.dart';
import 'package:sure_wholesaler/notifiers/category_notifier.dart';
import 'package:sure_wholesaler/widgets/image_builder.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

import '../../notifiers/product_notifier.dart';
import '../../widgets/Product_Card_Widget.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  StateController<String>? _searchNotifier;

  @override
  void initState() {
    super.initState();
    _searchNotifier = ref.read(categorySearchQueryProvider.notifier);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _searchNotifier?.state = '';
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(categorySearchQueryProvider.notifier).state = value.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(categorySearchQueryProvider.notifier).state = '';
  }

  void _openCategory(BuildContext context, CategoryModel category) {
    if (category.hasParent) {
      // It's a sub-category: go to products page with sub-category filter
      context.push(
        '/category-items/${category.parentId}',
        extra: {
          'categoryName': category.name,
          'subcategoryId': category.docId,
          'sortBy': 'Popularity',
        },
      );
      return;
    }

    // It's a root category: show everything in it
    context.push(
      '/category-items/${category.docId}',
      extra: {
        'categoryName': category.name,
        'sortBy': 'Popularity',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categoriesState = ref.watch(categoryProvider);
    final rootCategories = ref.watch(categoryTreeProvider);
    final searchQuery = ref.watch(categorySearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Categories',
          style: theme.textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(52.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 13.sp, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.sp),
                prefixIcon: Icon(Icons.search_rounded, color: scheme.primary, size: 20.sp),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18.sp, color: scheme.onSurfaceVariant),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: categoriesState.when(
        loading: () => const Center(child: AppLoader()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: scheme.error),
              SizedBox(height: 12.h),
              const Text('Failed to load categories'),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: () => ref.read(categoryProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (_) {
          if (searchQuery.isNotEmpty) {
            final results = ref.watch(filteredCategoriesProvider);
            if (results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48.sp, color: scheme.onSurfaceVariant),
                    SizedBox(height: 12.h),
                    Text('No results for "$searchQuery"', style: theme.textTheme.bodyMedium),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant),
              itemBuilder: (context, i) {
                final cat = results[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: ImageBuilder(
                      image: NetworkImage(cat.imageUrl ?? ''),
                      width: 44.w,
                      height: 44.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(cat.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: cat.parentName != null
                      ? Text(cat.parentName!, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant))
                      : null,
                  trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  onTap: () => _openCategory(context, cat),
                );
              },
            );
          }

          if (rootCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 48.sp, color: scheme.onSurfaceVariant),
                  SizedBox(height: 12.h),
                  Text('No categories found', style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          final selectedIndex = ref.watch(selectedRootCategoryIndexProvider);
          final safeIndex = selectedIndex.clamp(0, rootCategories.length - 1);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryRail(
                categories: rootCategories,
                selectedIndex: safeIndex,
                onTap: (i) {
                  final cat = rootCategories[i];
                  final hasChildren = cat.children?.isNotEmpty == true || ref.read(subcategoriesProvider(cat.docId)).isNotEmpty;
                  if (!hasChildren) {
                    _openCategory(context, cat);
                  } else {
                    ref.read(selectedRootCategoryIndexProvider.notifier).state = i;
                  }
                },
              ),
              VerticalDivider(
                thickness: 1,
                width: 1,
                color: scheme.outlineVariant,
              ),
              Expanded(
                child: _ContentPanel(
                  selectedCategory: rootCategories[safeIndex],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Left rail ──────────────────────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CategoryRail({
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 64.w, // ✅ reduced from 76
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final category = categories[index];

          return InkWell(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(vertical: 8.h), // tighter
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                border: isSelected
                    ? Border(
                        left: BorderSide(
                          color: scheme.primary,
                          width: 3, // ✅ strong indicator
                        ),
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: isSelected ? scheme.primary.withValues(alpha: 0.10) : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: ImageBuilder(
                        image: NetworkImage(category.imageUrl ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 9.sp,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Right content panel ────────────────────────────────────────────────────────

class _ContentPanel extends ConsumerWidget {
  final CategoryModel selectedCategory;

  const _ContentPanel({required this.selectedCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subcategories = selectedCategory.children?.isNotEmpty == true
        ? selectedCategory.children!
        : ref.watch(subcategoriesProvider(selectedCategory.docId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
          child: Text(
            selectedCategory.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Expanded(
          child: subcategories.isNotEmpty
              ? GridView.builder(
                  padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 12.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6.h,
                    crossAxisSpacing: 6.w,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: subcategories.length,
                  itemBuilder: (context, i) {
                    final sub = subcategories[i];
                    return _SubcategoryCard(
                      category: sub,
                      onTap: () => context.push(
                        '/category-items/${selectedCategory.docId}',
                        extra: {
                          'categoryName': sub.name,
                          'subcategoryId': sub.docId,
                          'sortBy': 'Popularity',
                        },
                      ),
                    );
                  },
                )
              : _CategoryProductsGrid(categoryId: selectedCategory.docId),
        ),
      ],
    );
  }
}

class _CategoryProductsGrid extends ConsumerWidget {
  final String categoryId;
  const _CategoryProductsGrid({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryStreamProvider(categoryId));

    return productsAsync.when(
      loading: () => const Center(child: AppLoader(size: 24)),
      error: (e, _) => const Center(child: Text('Empty', style: TextStyle(fontSize: 10))),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.grey.shade300, size: 40.sp),
                SizedBox(height: 8.h),
                Text(
                  'No products found',
                  style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 20.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCardWidget(
              product: products[index],
            );
          },
        );
      },
    );
  }
}

// ── Subcategory card ───────────────────────────────────────────────────────────

class _SubcategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _SubcategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ImageBuilder(
                image: NetworkImage(category.imageUrl ?? ''),
                width: double.infinity,
                height: double.infinity,
                borderRadius: 10,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
              height: 1.2,
            ),
          ),
          if ((category.productCount ?? 0) > 0)
            Text(
              '${category.productCount} items',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 8.5.sp,
              ),
            ),
        ],
      ),
    );
  }
}
