import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';

abstract class FirestoreModel {
  String? get id;
  Map<String, dynamic> toMap();
}

class FirestoreRepository<T extends FirestoreModel> {
  final FirebaseFirestore _firestore;
  final String collectionPath;
  final T Function(DocumentSnapshot doc) fromFirestore;

  FirestoreRepository({
    FirebaseFirestore? firestore,
    required this.collectionPath,
    required this.fromFirestore,
  }) : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _collection => _firestore.collection(collectionPath);

  // ================================
  // CREATE
  // ================================

  /// Auto ID
  Future<String> create(T model) async {
    final doc = _collection.doc();
    await doc.set(model.toMap());
    return doc.id;
  }

  /// Custom ID
  Future<void> set(T model) async {
    if (model.id == null) {
      throw Exception("Model ID cannot be null for set()");
    }
    await _collection.doc(model.id).set(model.toMap());
  }

  // ================================
  // READ
  // ================================

  Future<T?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return fromFirestore(doc);
  }

  Stream<T?> streamById(String id) {
    return _collection.doc(id).snapshots().map((doc) => doc.exists ? fromFirestore(doc) : null);
  }

  Future<List<T>> getAll({
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _collection;

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<T>> streamAll({
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _collection;

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(fromFirestore).toList(),
        );
  }

  // ================================
  // UPDATE
  // ================================

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  Future<void> updateModel(T model) async {
    if (model.id == null) {
      throw Exception("Model ID cannot be null for update()");
    }
    await _collection.doc(model.id).update(model.toMap());
  }

  Future<void> setMerge(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).set(data, SetOptions(merge: true));
  }

  // ================================
  // DELETE
  // ================================

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> softDelete(String id) async {
    await _collection.doc(id).update({
      "isDeleted": true,
      "deletedAt": FieldValue.serverTimestamp(),
    });
  }

  // ================================
  // WHERE / FILTER  (callback style)
  // ================================

  /// Pass a builder that receives the base [Query] and returns
  /// the modified query with any where/orderBy/limit clauses you need.
  ///
  /// Example:
  /// ```dart
  /// repo.query((q) => q.where('testId', isEqualTo: tid).orderBy('timestamp'));
  /// ```
  Future<List<T>> query(Query Function(Query) builder) async {
    final snapshot = await builder(_collection).get();
    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<T>> streamQuery(Query Function(Query) builder) {
    return builder(
      _collection,
    ).snapshots().map((snapshot) => snapshot.docs.map(fromFirestore).toList());
  }

  // ================================
  // PAGINATION
  // ================================

  Future<List<T>> paginate({
    required DocumentSnapshot lastDocument,
    required int limit,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _collection;

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    query = query.startAfterDocument(lastDocument).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map(fromFirestore).toList();
  }

  // ================================
  // COUNT
  // ================================

  Future<int> count() async {
    final snapshot = await _collection.count().get();
    return snapshot.count ?? 0;
  }

  // ================================
  // BATCH
  // ================================

  Future<void> batchSet(List<T> models) async {
    final batch = _firestore.batch();

    for (var model in models) {
      if (model.id == null) {
        throw Exception("All models must have a non-null id for batchSet()");
      }
      final doc = _collection.doc(model.id!);
      batch.set(doc, model.toMap());
    }

    await batch.commit();
  }

  // ================================
  // TRANSACTION
  // ================================

  Future<void> runTransaction(
    Future<void> Function(Transaction tx) action,
  ) async {
    await _firestore.runTransaction(action);
  }

  // ================================
  // SUBCOLLECTION
  // ================================

  CollectionReference subCollection(String docId, String subPath) {
    return _collection.doc(docId).collection(subPath);
  }
}
