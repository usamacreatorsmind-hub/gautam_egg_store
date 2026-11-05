// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sure_wholesaler/models/product_model.dart';

class StoryItemModel {
  final String id;
  final String productId;
  final String categoryId;
  final List<String>
      mediaUrls; // product.imageUrls today, dedicated field later
  final String title;
  final String price;
  final int sortOrder;
  final DateTime createdAt;

  /// Runtime-only reference to the source product.
  /// Not serialized — null when loaded from a dedicated stories collection.
  final ProductModel? source;

  StoryItemModel({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.mediaUrls,
    required this.title,
    required this.price,
    required this.sortOrder,
    required this.createdAt,
    this.source,
  });

  factory StoryItemModel.fromProduct(ProductModel product) {
    return StoryItemModel(
      id: product.id ?? '',
      productId: product.id ?? '',
      categoryId: product.categoryId,
      mediaUrls: product.imageUrls,
      title: product.name,
      price: product.formattedPrice,
      sortOrder: 0,
      createdAt: product.createdAt ?? DateTime.now(),
      source: product,
    );
  }

  bool get hasMedia => mediaUrls.isNotEmpty;

  String get primaryMediaUrl => mediaUrls.first;

  StoryItemModel copyWith({
    String? id,
    String? productId,
    String? categoryId,
    List<String>? mediaUrls,
    String? title,
    String? price,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return StoryItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      title: title ?? this.title,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'categoryId': categoryId,
      'mediaUrls': mediaUrls,
      'title': title,
      'price': price,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory StoryItemModel.fromMap(Map<String, dynamic> map) {
    return StoryItemModel(
        id: map['id'] as String,
        productId: map['productId'] as String,
        categoryId: map['categoryId'] as String,
        mediaUrls: List<String>.from(
          (map['mediaUrls'] as List<String>),
        ),
        title: map['title'] as String,
        price: map['price'] as String,
        sortOrder: map['sortOrder'] as int,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int));
  }

  String toJson() => json.encode(toMap());

  factory StoryItemModel.fromJson(String source) =>
      StoryItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'StoryItemModel(id: $id, productId: $productId, categoryId: $categoryId, mediaUrls: $mediaUrls, title: $title, price: $price, sortOrder: $sortOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant StoryItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.productId == productId &&
        other.categoryId == categoryId &&
        listEquals(other.mediaUrls, mediaUrls) &&
        other.title == title &&
        other.price == price &&
        other.sortOrder == sortOrder &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productId.hashCode ^
        categoryId.hashCode ^
        mediaUrls.hashCode ^
        title.hashCode ^
        price.hashCode ^
        sortOrder.hashCode ^
        createdAt.hashCode;
  }
}
