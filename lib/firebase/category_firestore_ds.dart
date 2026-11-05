import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';

abstract class CategoryFirestoreDs {
  /// Fetch all categories from Firestore
  Stream<List<Map<String, dynamic>>> getCategories();

  /// Fetch a single category by ID
  Stream<Map<String, dynamic>?> getCategoryById(String categoryId);

  /// Fetch categories with a specific filter (e.g., by status, type)
  Stream<List<Map<String, dynamic>>> getCategoriesWhere({
    required String field,
    required dynamic value,
  });

  /// Listen to real-time category updates
  Stream<List<Map<String, dynamic>>> watchCategories();

  /// Listen to a single category's real-time updates
  Stream<Map<String, dynamic>?> watchCategoryById(String categoryId);
}

class CategoryFirestoreDsImpl implements CategoryFirestoreDs {
  final FirebaseFirestore _firestore;
  final String _collectionName = Collections.categories;

  CategoryFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _categoryCollection =>
      _firestore.collection(_collectionName);

  @override
  Stream<List<Map<String, dynamic>>> getCategories() {
    try {
      final snapshot = _categoryCollection.snapshots();

      return snapshot.map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> getCategoryById(String categoryId) {
    try {
      return _categoryCollection.doc(categoryId).snapshots().map((doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getCategoriesWhere({
    required String field,
    required dynamic value,
  }) {
    try {
      return _categoryCollection
          .where(field, isEqualTo: value)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch filtered categories: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCategories() {
    try {
      return _categoryCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to watch categories: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchCategoryById(String categoryId) {
    try {
      return _categoryCollection.doc(categoryId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          data['docId'] = snapshot.id;
          return data;
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to watch category: $e');
    }
  }
}
