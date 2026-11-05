import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';

class FavoriteProductsDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FavoriteProductsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _favCol => _uid == null
      ? null
      : _firestore
          .collection(Collections.users)
          .doc(_uid)
          .collection('favorites');

  /// Real-time stream of favorited product IDs for the current user.
  Stream<List<String>> watchFavoriteIds() {
    if (_uid == null) return Stream.value([]);
    return _favCol!
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// Toggle favorite: adds if absent, removes if present.
  Future<void> toggleFavorite(String productId) async {
    if (_uid == null) return;
    final ref = _favCol!.doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// One-shot check whether a product is currently favorited.
  Future<bool> isFavorite(String productId) async {
    if (_uid == null) return false;
    final doc = await _favCol!.doc(productId).get();
    return doc.exists;
  }

  /// Remove a favorite directly (used when you already know it's favorited).
  Future<void> removeFavorite(String productId) async {
    if (_uid == null) return;
    await _favCol!.doc(productId).delete();
  }

  /// Add a favorite directly (used when you already know it's not favorited).
  Future<void> addFavorite(String productId) async {
    if (_uid == null) return;
    await _favCol!.doc(productId).set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
}
