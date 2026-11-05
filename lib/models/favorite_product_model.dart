// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sure_wholesaler/generics/generic_firestore.dart';

class FavoriteProductsModel implements FirestoreModel {
  @override
  final String id;
  final List<String> productIds;
  final DateTime updatedAt;

  FavoriteProductsModel({
    required this.id,
    required this.productIds,
    required this.updatedAt,
  });

  factory FavoriteProductsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FavoriteProductsModel(
      id: data['id'] ?? '',
      productIds: List<String>.from(data['productIds'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'productIds': productIds,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FavoriteProductsModel copyWith({
    String? id,
    List<String>? productIds,
    DateTime? updatedAt,
  }) {
    return FavoriteProductsModel(
      id: id ?? this.id,
      productIds: productIds ?? this.productIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
