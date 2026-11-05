// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';

class StockAlertModel {
  final String id; // documentId
  final String userId;
  final String productId;
  final String productName; // helpful for notification text
  final bool isNotified;
  final DateTime? createdAt;
  final DateTime? notifiedAt;

  StockAlertModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    this.isNotified = false,
    this.createdAt,
    this.notifiedAt,
  });

  /// From Firestore document
  factory StockAlertModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return StockAlertModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      isNotified: data['isNotified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      notifiedAt: (data['notifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// From a Map (used with getPendingAlertsByProduct)
  factory StockAlertModel.fromMap(Map<String, dynamic> data) {
    return StockAlertModel(
      id: data['alertId'] ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      isNotified: data['isNotified'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      notifiedAt: data['notifiedAt'] is Timestamp
          ? (data['notifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// To Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'isNotified': isNotified,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  StockAlertModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    bool? isNotified,
    DateTime? createdAt,
    DateTime? notifiedAt,
  }) {
    return StockAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      isNotified: isNotified ?? this.isNotified,
      createdAt: createdAt ?? this.createdAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }

  @override
  String toString() {
    return 'StockAlertModel(id: $id, userId: $userId, productId: $productId, productName: $productName, isNotified: $isNotified, createdAt: $createdAt, notifiedAt: $notifiedAt)';
  }
}
