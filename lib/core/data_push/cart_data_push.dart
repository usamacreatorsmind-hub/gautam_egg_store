import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import '../constants/app_constants.dart';

class CartDataPush {
  final FirebaseFirestore _firestore;

  CartDataPush({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  Future<void> clearCarts() async {
    final snapshot = await _firestore.collection(Collections.cart).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
