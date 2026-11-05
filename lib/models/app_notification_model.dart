import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  order,
  delivery,
  product,
  stock,
  offer,
  system,
}

enum NotificationTarget {
  user,
  deliveryAgent,
  admin,
}

class AppNotificationModel {
  final String? id;
  final String? title;
  final String? body;
  final NotificationType? type;
  final NotificationTarget? target;

  /// Reference IDs (optional, but powerful)
  final String? userId;
  final String? orderId;
  final String? productId;
  final String? deliveryAgentId;

  /// Extra data for navigation / actions
  final Map<String, dynamic>? data;

  final bool? isRead;
  final DateTime? createdAt;

  AppNotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.target,
    this.userId,
    this.orderId,
    this.productId,
    this.deliveryAgentId,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  /// 🔹 Firestore → Model
  factory AppNotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;

    return AppNotificationModel(
      id: doc.id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      target: NotificationTarget.values.firstWhere(
        (e) => e.name == json['target'],
        orElse: () => NotificationTarget.user,
      ),
      userId: json['userId'],
      orderId: json['orderId'],
      productId: json['productId'],
      deliveryAgentId: json['deliveryAgentId'],
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['isRead'] ?? false,
      createdAt: _parseTimestamp(json['createdAt']) ?? DateTime.now(),
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type?.name,
      'target': target?.name,
      'userId': userId,
      'orderId': orderId,
      'productId': productId,
      'deliveryAgentId': deliveryAgentId,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Map) {
      final seconds = value['_seconds'] ?? value['seconds'];
      final nanos = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;
      if (seconds != null) {
        return Timestamp(seconds as int, nanos as int).toDate();
      }
    }
    return null;
  }

  /// 🔹 CopyWith
  AppNotificationModel copyWith({
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      target: target,
      userId: userId,
      orderId: orderId,
      productId: productId,
      deliveryAgentId: deliveryAgentId,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
