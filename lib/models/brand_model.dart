// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandModel {
  final String id;
  final String name;
  final String? logoUrl;
  final bool isActive;
  final String? description;
  final String? country;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  BrandModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isActive = true,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.country,
  });

  /// 🔹 From Firestore
  factory BrandModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw Exception('Brand document ${doc.id} has no data');
    }

    return BrandModel(
      id: doc.id,
      name: (data['name'] ?? data['brandName'] ?? 'No Name').toString(),
      logoUrl: (data['logoUrl'] ?? data['logo'] ?? data['imageUrl'])?.toString(),
      isActive: data['isActive'] is bool ? data['isActive'] : true,
      description: data['description']?.toString(),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      country: (data['country'] ?? data['origin'])?.toString(),
    );
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'];
      if (seconds != null) {
        return Timestamp(seconds as int, (nanoseconds as int?) ?? 0);
      }
    }
    return null;
  }

  /// 🔹 To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'description': description,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'country': country,
    };
  }

  @override
  String toString() {
    return 'BrandModel(id: $id, name: $name, logoUrl: $logoUrl, isActive: $isActive, description: $description, createdAt: $createdAt.  updatedAt: $updatedAt, country: $country  )';
  }
}
