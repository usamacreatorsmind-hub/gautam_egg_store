import 'package:sure_wholesaler/firebase/category_firestore_ds.dart';
import 'package:sure_wholesaler/models/category_model.dart';

abstract class CategoryRepository {
  /// Fetch all categories
  Stream<List<CategoryModel>> getCategories();

  /// Fetch a single category by ID
  Stream<CategoryModel?> getCategoryById(String categoryId);

  /// Fetch categories with filters
  Stream<List<CategoryModel>> getCategoriesWhere({
    required String field,
    required dynamic value,
  });

  /// Listen to real-time category updates
  Stream<List<CategoryModel>> watchCategories();

  /// Listen to a single category's real-time updates
  Stream<CategoryModel?> watchCategoryById(String categoryId);

  /// Search categories by name
  Stream<List<CategoryModel>> searchCategories(String query);

  /// Get active categories only
  Stream<List<CategoryModel>> getActiveCategories();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryFirestoreDs _firestoreDs;

  CategoryRepositoryImpl(this._firestoreDs);

  @override
  Stream<List<CategoryModel>> getCategories() {
    try {
      return _firestoreDs.getCategories().map((dataList) {
        return dataList
            .map((map) => CategoryModel.fromMap(map, map['docId'] as String?))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  @override
  Stream<CategoryModel?> getCategoryById(String categoryId) {
    try {
      return _firestoreDs.getCategoryById(categoryId).map((data) {
        return data != null
            ? CategoryModel.fromMap(data, data['docId'] as String?)
            : null;
      });
    } catch (e) {
      throw Exception('Failed to get category by ID: $e');
    }
  }

  @override
  Stream<List<CategoryModel>> getCategoriesWhere({
    required String field,
    required dynamic value,
  }) {
    try {
      return _firestoreDs.getCategoriesWhere(field: field, value: value).map(
            (dataList) => dataList
                .map((map) =>
                    CategoryModel.fromMap(map, map['docId'] as String?))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to get filtered categories: $e');
    }
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    try {
      return _firestoreDs.watchCategories().map(
            (dataList) => dataList
                .map((map) =>
                    CategoryModel.fromMap(map, map['docId'] as String?))
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to watch categories: $e');
    }
  }

  @override
  Stream<CategoryModel?> watchCategoryById(String categoryId) {
    try {
      return _firestoreDs.watchCategoryById(categoryId).map(
            (data) => data != null
                ? CategoryModel.fromMap(data, data['docId'] as String?)
                : null,
          );
    } catch (e) {
      throw Exception('Failed to watch category: $e');
    }
  }

  @override
  Stream<List<CategoryModel>> searchCategories(String query) {
    try {
      return _firestoreDs.getCategories().map((dataList) {
        return dataList
            .map((map) => CategoryModel.fromMap(map, map['docId'] as String?))
            .where((category) =>
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  @override
  Stream<List<CategoryModel>> getActiveCategories() {
    try {
      return _firestoreDs
          .getCategoriesWhere(field: 'isActive', value: true)
          .map((dataList) {
        return dataList
            .map((map) => CategoryModel.fromMap(map, map['docId'] as String?))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get active categories: $e');
    }
  }
}
