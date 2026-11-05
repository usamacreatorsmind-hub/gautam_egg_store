import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

class SearchLogModel implements FirestoreModel {
  @override
  final String? id;

  final String keyword;
  final String uid;

  final String hubId;
  final String serviceArea;

  final DateTime dateTime;

  SearchLogModel({
    this.id,
    required this.keyword,
    required this.uid,
    required this.hubId,
    required this.serviceArea,
    required this.dateTime,
  });

  // ------------------------------------------------------------
  // FROM FIRESTORE
  // ------------------------------------------------------------

  factory SearchLogModel.fromMap(
    String documentId,
    Map<String, dynamic> map,
  ) {
    return SearchLogModel(
      id: documentId,
      keyword: map['keyword'] ?? '',
      uid: map['uid'] ?? '',
      hubId: map['hubId'] ?? '',
      serviceArea: map['serviceArea'] ?? '',
      dateTime: map['dateTime'] ?? DateTime.now(),
    );
  }

  // ------------------------------------------------------------
  // TO FIRESTORE
  // ------------------------------------------------------------

  @override
  Map<String, dynamic> toMap() {
    return {
      'keyword': keyword.trim(),
      'uid': uid,
      'hubId': hubId,
      'serviceArea': serviceArea,
      'dateTime': FieldValue.serverTimestamp(),
    };
  }

  // ------------------------------------------------------------
  // COPY WITH
  // ------------------------------------------------------------

  SearchLogModel copyWith({
    String? id,
    String? keyword,
    String? uid,
    String? hubId,
    String? serviceArea,
    DateTime? dateTime,
  }) {
    return SearchLogModel(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      uid: uid ?? this.uid,
      hubId: hubId ?? this.hubId,
      serviceArea: serviceArea ?? this.serviceArea,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}
