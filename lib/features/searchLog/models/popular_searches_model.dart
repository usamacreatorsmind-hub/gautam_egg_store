import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/datetime_converter.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

class PopularSearchModel implements FirestoreModel {
  @override
  final String id;
  final String keyword;
  final int searchCount;
  final bool isTrending;
  final DateTime createdAt;
  final DateTime updatedAt;

  PopularSearchModel({
    required this.id,
    required this.keyword,
    required this.searchCount,
    required this.isTrending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PopularSearchModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return PopularSearchModel(
      id: documentId,
      keyword: map['keyword'] ?? '',
      searchCount: map['searchCount'] ?? 0,
      isTrending: map['isTrending'] ?? false,
      createdAt: FirestoreDateConverter.parse(map['createdAt']),
      updatedAt: FirestoreDateConverter.parse(map['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toMap() {
    return {
      'keyword': keyword,
      'searchCount': searchCount,
      'isTrending': isTrending,
      'createdAt': FirestoreDateConverter.toTimestamp(createdAt),
      'updatedAt': FirestoreDateConverter.toTimestamp(updatedAt),
    };
  }

  PopularSearchModel copyWith({
    String? id,
    String? keyword,
    int? searchCount,
    bool? isTrending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PopularSearchModel(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      searchCount: searchCount ?? this.searchCount,
      isTrending: isTrending ?? this.isTrending,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
