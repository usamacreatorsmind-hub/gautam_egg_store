import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

class FavoriteItemModel implements FirestoreModel {
  @override
  final String id; // == productId (document ID in favorites subcollection)

  final DateTime addedAt;

  FavoriteItemModel({required this.id, required this.addedAt});

  factory FavoriteItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FavoriteItemModel(
      id: doc.id,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'productId': id,
        'addedAt': FieldValue.serverTimestamp(),
      };
}
