import 'dart:async';
import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/category_firestore_ds.dart';
import 'package:sure_wholesaler/models/category_model.dart';
import 'package:sure_wholesaler/repositories/category_repository.dart';

/// Repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(CategoryFirestoreDsImpl());
});

/// Main categories state provider
final categoryProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  return CategoryNotifier(ref.read(categoryRepositoryProvider));
});

/// Root categories only (parentId is null or empty)
final rootCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoriesState = ref.watch(categoryProvider);
  final categories = categoriesState.value ?? [];

  return categories.where((c) => c.parentId == null || c.parentId!.isEmpty).where((c) => c.isActive).toList()
    ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
});

/// Get subcategories for a specific parent
final subcategoriesProvider = Provider.family<List<CategoryModel>, String>((ref, parentId) {
  final categoriesState = ref.watch(categoryProvider);
  final categories = categoriesState.value ?? [];

  return categories.where((c) => c.parentId == parentId).where((c) => c.isActive).toList()
    ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
});

/// Selected category state
final selectedCategoryProvider = StateProvider<CategoryModel?>((ref) => null);

/// Selected subcategory state
final selectedSubcategoryProvider = StateProvider<CategoryModel?>((ref) => null);

/// Currently selected root category index in Categories page
final selectedRootCategoryIndexProvider = StateProvider<int>((ref) => 0);

/// Category search query
final categorySearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered categories based on search
final filteredCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categoriesState = ref.watch(categoryProvider);
  final query = ref.watch(categorySearchQueryProvider).toLowerCase();
  final categories = categoriesState.value ?? [];

  if (query.isEmpty) {
    return categories.where((c) => c.isActive).toList();
  }

  return categories.where((c) => c.isActive).where((c) => c.name.toLowerCase().contains(query)).toList();
});

/// Category tree (hierarchical structure)
/// Supports both embedded children (stored in document) and flat structure (separate documents with parentId)
/// Only includes root categories that have at least one active subcategory.
final categoryTreeProvider = Provider<List<CategoryModel>>((ref) {
  final categoriesState = ref.watch(categoryProvider);
  final categories = categoriesState.value ?? [];

  final roots = categories.where((c) => c.parentId == null || c.parentId!.isEmpty).where((c) => c.isActive).toList()
    ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

  final hasEmbeddedChildren = roots.any((c) => c.children != null && c.children!.isNotEmpty);

  if (hasEmbeddedChildren) {
    return roots.where((r) => r.children != null && r.children!.isNotEmpty).toList();
  }

  List<CategoryModel> buildTree(List<CategoryModel> parents, int level) {
    return parents.map((parent) {
      final children = categories.where((c) => c.parentId == parent.docId).where((c) => c.isActive).toList()
        ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

      return parent.copyWith(
        children: buildTree(children, level + 1),
        level: level,
      );
    }).toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }

  final tree = buildTree(roots, 0);
  // Fixed: Do NOT filter out categories without children, so they show in tabs
  return tree;
});

/// Get category by ID
final categoryByIdProvider = Provider.family<CategoryModel?, String>((ref, categoryId) {
  final categoriesState = ref.watch(categoryProvider);
  final categories = categoriesState.value ?? [];

  try {
    return categories.firstWhere((c) => c.id == categoryId);
  } catch (_) {
    return null;
  }
});

class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository _repository;
  StreamSubscription<List<CategoryModel>>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _init();
    });
  }

  void _init() {
    _subscription?.cancel();
    _subscription = _repository.watchCategories().listen(
      (categories) {
        state = AsyncValue.data(categories);
      },
      onError: (error, stackTrace) {
        debugPrint('CategoryNotifier stream error: $error');
        state = AsyncValue.error(error, stackTrace);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.hasError) {
            _init();
          }
        });
      },
    );
  }

  Future<void> refresh() async {
    _init();
  }

  Stream<List<CategoryModel>> getActiveCategories() {
    return _repository.getActiveCategories();
  }

  Stream<CategoryModel?> watchCategoryById(String categoryId) {
    return _repository.watchCategoryById(categoryId);
  }

  Stream<List<CategoryModel>> searchCategories(String query) {
    return _repository.searchCategories(query);
  }

  Future<CategoryModel?> getCategoryById(String categoryId) async {
    return await _repository.getCategoryById(categoryId).first;
  }

  Future<List<CategoryModel>> getSubcategories(String parentId) async {
    return await _repository
        .getCategoriesWhere(
          field: 'parentId',
          value: parentId,
        )
        .first;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
