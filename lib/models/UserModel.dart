// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String userImg;

  /* ------------------ BASIC ------------------ */
  final String userName;
  final String email;
  final String mobileNo;

  /* ------------------ TOKENS ------------------ */
  final List<String> fcmTokens;

  /* ------------------ COUPONS ------------------ */
  /// couponCode → timesUsed (FAST ACCESS ONLY,  source of truth)< cid< times>
  final Map<String, int> usedCoupons;

  /* ------------------ TIME ------------------ */
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isProfileCreated;

  const UserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.mobileNo,
    required this.userImg,
    required this.fcmTokens,
    required this.usedCoupons,
    required this.createdAt,
    required this.updatedAt,
    required this.isProfileCreated,
  });

  /* ------------------------------------------------ */
  /*                  FROM MAP                        */
  /* ------------------------------------------------ */

  factory UserModel.fromMap(Map<String, dynamic> m, String id) {
    return UserModel(
      userId: m['uid'] ?? id,
      userName: m['displayName'] ?? m['userName'] ?? m['name'] ?? '',
      email: m['email'] ?? '',
      mobileNo: m['phoneNumber'] ?? m['mobileNo'] ?? '',
      userImg: m['photoURL'] ?? m['userImg'] ?? '',
      isProfileCreated: m['isProfileCreated'] ?? (m['status'] == 'active'),
      fcmTokens: List<String>.from(m['fcmTokens'] ?? []),
      usedCoupons: Map<String, int>.from(
        (m['usedCoupons'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num? ?? 0).toInt()),
            ) ??
            {},
      ),
      createdAt: _parseTimestamp(m['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(m['updatedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /* ------------------------------------------------ */
  /*                   TO MAP                         */
  /* ------------------------------------------------ */

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'displayName': userName,
      'email': email,
      'phoneNumber': mobileNo,
      'photoURL': userImg,
      'fcmTokens': fcmTokens,
      'usedCoupons': usedCoupons,
      'isProfileCreated': isProfileCreated,
      'status': isProfileCreated ? 'active' : 'pending',
      'role': 'retail_customer',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /* ------------------------------------------------ */
  /*                   EMPTY                          */
  /* ------------------------------------------------ */

  factory UserModel.empty() {
    return UserModel(
      userId: '',
      userImg: '',
      userName: '',
      email: '',
      mobileNo: '',
      fcmTokens: const [],
      usedCoupons: const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isProfileCreated: false,
    );
  }

  /* ------------------------------------------------ */
  /*                  COPY WITH                       */
  /* ------------------------------------------------ */

  UserModel copyWith({
    String? userName,
    String? userImg,
    String? city,
    List<String>? fcmTokens,
    Map<String, int>? usedCoupons,
    DateTime? updatedAt,
    bool? isProfileCreated,
  }) {
    return UserModel(
      userId: userId,
      userName: userName ?? this.userName,
      email: email,
      userImg: userImg ?? this.userImg,
      mobileNo: mobileNo,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      usedCoupons: usedCoupons ?? this.usedCoupons,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProfileCreated: isProfileCreated ?? this.isProfileCreated,
    );
  }

  /* ------------------------------------------------ */
  /*              COUPON HELPERS                      */
  /* ------------------------------------------------ */

  /// Increment coupon usage locally (UI cache)
  Map<String, int> incrementCouponUsage(String code) {
    final updated = Map<String, int>.from(usedCoupons);
    updated[code] = (updated[code] ?? 0) + 1;
    return updated;
  }

  /// Get how many times user used a coupon
  int getCouponUsage(String code) {
    return usedCoupons[code] ?? 0;
  }
}
