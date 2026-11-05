import 'package:sure_wholesaler/generics/generic_firestore.dart';

class ProductReviewModel implements FirestoreModel {
  @override
  final String id;

  final String productId;
  final String userId;
  final String orderId;
  final String orderItemId;

  final double rating;
  final String title;
  final String comment;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProductReviewModel({
    this.id = '',
    required this.productId,
    required this.userId,
    required this.orderId,
    required this.orderItemId,
    required this.rating,
    required this.title,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 🔹 Convert Firestore -> Model
  factory ProductReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductReviewModel(
      id: id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      orderId: map['orderId'] ?? '',
      orderItemId: map['orderItemId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Convert Model -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'id': id,
      'orderId': orderId,
      'orderItemId': orderItemId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 🔹 Copy with (useful for updates)
  ProductReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? orderId,
    String? orderItemId,
    double? rating,
    String? title,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
