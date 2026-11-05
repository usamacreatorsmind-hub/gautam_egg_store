import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

class FlashSaleModel implements FirestoreModel {
  @override
  final String? id;
  final String title;
  final String? subtitle;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> productIds;
  final bool isActive;
  final double? discountPercent;

  const FlashSaleModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.productIds,
    required this.isActive,
    this.discountPercent,
  });

  bool get isLive {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isExpired => DateTime.now().isAfter(endTime);

  Duration get timeRemaining {
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory FlashSaleModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime parseTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is Map) {
        final seconds = raw['seconds'];
        if (seconds is int) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
      return DateTime.now();
    }

    return FlashSaleModel(
      id: docId ?? data['id'] as String?,
      title: data['title'] as String? ?? 'Flash Sale',
      subtitle: data['subtitle'] as String?,
      startTime: parseTime(data['startTime']),
      endTime: parseTime(data['endTime']),
      productIds: List<String>.from(data['productIds'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? false,
      discountPercent: (data['discountPercent'] as num?)?.toDouble(),
    );
  }

  factory FlashSaleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    return FlashSaleModel.fromMap(
      data is Map<String, dynamic> ? data : {},
      doc.id,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'productIds': productIds,
        'isActive': isActive,
        if (discountPercent != null) 'discountPercent': discountPercent,
      };
}
