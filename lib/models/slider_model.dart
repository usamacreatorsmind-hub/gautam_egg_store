// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';

/// Action types for slider tap navigation.
abstract final class SliderActionType {
  static const String category = 'category';
  static const String product = 'product';
  static const String offer = 'offer';
  static const String url = 'url';
  static const String none = 'none';
}

class SliderModel {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> category;
  final int clicks;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// What to do on tap: 'category' | 'product' | 'offer' | 'url' | 'none'
  final String actionType;

  /// Target for the action:
  /// - category → ignored (uses [category] list)
  /// - product  → product document ID
  /// - url      → full URL string
  /// - offer / none → ignored
  final String actionTarget;

  SliderModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.clicks,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.actionType = SliderActionType.category,
    this.actionTarget = '',
  });

  factory SliderModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final DateTime now = DateTime.now();
    
    // Improved date parsing
    DateTime parseDate(dynamic value, [DateTime? fallback]) {
      if (value == null) return fallback ?? now;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? fallback ?? now;
      return fallback ?? now;
    }

    final startDate = parseDate(data['startDate'], now);
    final endDate = parseDate(data['endDate'], now.add(const Duration(days: 365)));
    
    // Status Logic: Use isActive boolean if status string is missing
    String status = data['status'] ?? '';
    if (status.isEmpty) {
      final bool isActive = data['isActive'] ?? true;
      if (!isActive) {
        status = SliderStatus.expired;
      } else if (now.isBefore(startDate)) {
        status = SliderStatus.upcoming;
      } else if (now.isAfter(endDate)) {
        status = SliderStatus.expired;
      } else {
        status = SliderStatus.active;
      }
    }

    return SliderModel(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image'] ?? '',
      category: List<String>.from(data['category'] ?? []),
      clicks: data['clicks'] ?? 0,
      status: status,
      startDate: startDate,
      endDate: endDate,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      actionType: data['actionType'] as String? ?? SliderActionType.url,
      actionTarget: data['actionTarget'] as String? ?? data['linkUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
      'clicks': clicks,
      'status': status,
      'actionType': actionType,
      'actionTarget': actionTarget,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isActive => status == SliderStatus.active;
  bool get isUpcoming => status == SliderStatus.upcoming;
  bool get isExpired => status == SliderStatus.expired;

  bool get isActuallyExpired {
    if (status == SliderStatus.expired) return true;
    return DateTime.now().isAfter(endDate);
  }

  @override
  String toString() {
    return 'SliderModel(id: $id, title: $title, imageUrl: $imageUrl, category: $category, clicks: $clicks, status: $status, startDate: $startDate, endDate: $endDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
