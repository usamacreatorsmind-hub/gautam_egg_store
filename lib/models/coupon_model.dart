import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';

/// 🔹 Coupon Types
enum CouponType {
  percentage,
  flat,
  bogo,
  subscription,
}

/// 🔹 Where coupon applies
enum ApplyOn {
  allProducts,
  category,
  products,
}

class CouponModel {
  final String code;
  final CouponType type;

  /// percentage / flat
  final double? value;
  final double? maxDiscount;

  /// BOGO
  final int? buyQty;
  final int? getQty;

  final DateTime expiryDate;
  final DateTime activeDate;

  final double minOrder;

  final int maxUsage;
  final int usedCount;
  final int maxUsagePerUser;

  final bool isActive;

  final ApplyOn applyOn;
  final String? applicableCategory;
  final List<String> applicableProducts;

  const CouponModel({
    required this.code,
    required this.type,
    this.value,
    this.maxDiscount,
    this.buyQty,
    this.getQty,
    required this.expiryDate,
    required this.activeDate,
    required this.minOrder,
    required this.maxUsage,
    required this.usedCount,
    required this.isActive,
    required this.applyOn,
    this.maxUsagePerUser = 1,
    this.applicableCategory,
    this.applicableProducts = const [],
  });

  /// Empty fallback instance
  factory CouponModel.empty() => CouponModel(
        code: '',
        type: CouponType.flat,
        value: 0,
        maxDiscount: 0,
        buyQty: 0,
        getQty: 0,
        expiryDate: DateTime(2099),
        activeDate: DateTime(2000),
        minOrder: 0,
        maxUsage: 0,
        usedCount: 0,
        isActive: false,
        applyOn: ApplyOn.allProducts,
        maxUsagePerUser: 0,
        applicableProducts: const [],
      );

  /* ------------------------------------------------ */
  /*                  FROM MAP                        */
  /* ------------------------------------------------ */

  factory CouponModel.fromMap(Map<String, dynamic> map) {
    DateTime parseTs(dynamic v, {required bool future}) {
      if (v == null) return future ? DateTime(2099) : DateTime(2000);
      if (v is Timestamp) return v.toDate();
      if (v is int) {
        if (v < 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000);
        }
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      if (v is double) {
        final intV = v.toInt();
        if (intV < 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(intV * 1000);
        }
        return DateTime.fromMillisecondsSinceEpoch(intV);
      }
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
        final asNum = num.tryParse(v);
        if (asNum != null) {
          final intV = asNum.toInt();
          if (intV < 10000000000) {
            return DateTime.fromMillisecondsSinceEpoch(intV * 1000);
          }
          return DateTime.fromMillisecondsSinceEpoch(intV);
        }
      }
      return future ? DateTime(2099) : DateTime(2000);
    }

    final codeVal = (map['code'] ?? map['id'] ?? '').toString().trim();
    final rawTypeStr = (map['type'] ?? 'percentage').toString().toLowerCase().trim();
    CouponType type;
    if (rawTypeStr.contains('fixed') || rawTypeStr.contains('flat') || rawTypeStr.contains('amount')) {
      type = CouponType.flat;
    } else if (rawTypeStr.contains('bogo')) {
      type = CouponType.bogo;
    } else if (rawTypeStr.contains('sub')) {
      type = CouponType.subscription;
    } else {
      type = CouponType.values.firstWhere(
        (e) => e.name.toLowerCase() == rawTypeStr,
        orElse: () => CouponType.percentage,
      );
    }

    final rawVal = (map['value'] as num?)?.toDouble() ?? 0.0;
    final rawMaxDiscount = (map['maxDiscount'] ?? map['maxDiscountAmount'] as num?)?.toDouble();
    final rawMinOrder = (map['minOrder'] ?? map['minOrderAmount'] ?? map['min_order_amount'] ?? 0).toDouble();

    final maxUsageVal = map['maxUsage'] != null
        ? (map['maxUsage'] as num).toInt()
        : map['usageLimit'] != null
            ? (map['usageLimit'] as num).toInt()
            : map['max_usage'] != null
                ? (map['max_usage'] as num).toInt()
                : 999999;

    final usedCountVal = map['usedCount'] != null
        ? (map['usedCount'] as num).toInt()
        : map['usageCount'] != null
            ? (map['usageCount'] as num).toInt()
            : map['used_count'] != null
                ? (map['used_count'] as num).toInt()
                : 0;

    final maxUsagePerUserVal = map['maxUsagePerUser'] != null
        ? (map['maxUsagePerUser'] as num).toInt()
        : map['usageLimitPerUser'] != null
            ? (map['usageLimitPerUser'] as num).toInt()
            : map['limitPerUser'] != null
                ? (map['limitPerUser'] as num).toInt()
                : 1;

    final isActiveVal = map['isActive'] ?? map['active'] ?? true;

    final applyOnStr = (map['applyOn'] ?? 'allProducts').toString().toLowerCase().trim();
    final applyOn = ApplyOn.values.firstWhere(
      (e) => e.name.toLowerCase() == applyOnStr,
      orElse: () => ApplyOn.allProducts,
    );

    return CouponModel(
      code: codeVal,
      type: type,
      value: rawVal,
      maxDiscount: rawMaxDiscount,
      buyQty: (map['buyQty'] as num?)?.toInt(),
      getQty: (map['getQty'] as num?)?.toInt(),
      expiryDate: parseTs(map['expiryDate'] ?? map['expiresAt'] ?? map['expiry_date'], future: true),
      activeDate: parseTs(map['activeDate'] ?? map['createdAt'] ?? map['active_date'] ?? map['startDate'], future: false),
      minOrder: rawMinOrder,
      maxUsage: maxUsageVal,
      usedCount: usedCountVal,
      maxUsagePerUser: maxUsagePerUserVal,
      isActive: isActiveVal is bool ? isActiveVal : true,
      applyOn: applyOn,
      applicableCategory: map['applicableCategory']?.toString(),
      applicableProducts: List<String>.from(map['applicableProducts'] ?? []),
    );
  }

  /* ------------------------------------------------ */
  /*                   TO MAP                         */
  /* ------------------------------------------------ */

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'type': type.name,
      'value': value,
      'maxDiscount': maxDiscount,
      'buyQty': buyQty,
      'getQty': getQty,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'activeDate': Timestamp.fromDate(activeDate),
      'minOrder': minOrder,
      'maxUsage': maxUsage,
      'usedCount': usedCount,
      'maxUsagePerUser': maxUsagePerUser,
      'isActive': isActive,
      'applyOn': applyOn.name,
      'applicableCategory': applicableCategory,
      'applicableProducts': applicableProducts,
    };
  }

  /* ------------------------------------------------ */
  /*                 VALIDATIONS                      */
  /* ------------------------------------------------ */

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  bool get isStarted => DateTime.now().isAfter(activeDate);

  bool get isUsageExceeded => usedCount >= maxUsage;

  double get normalizedMinOrder {
    if (minOrder > 0 && minOrder < 1000) {
      return minOrder * 100;
    }
    return minOrder;
  }

  bool get isValidStructure {
    switch (type) {
      case CouponType.bogo:
        return buyQty != null && getQty != null;

      case CouponType.percentage:
      case CouponType.flat:
      case CouponType.subscription:
        return value != null;
    }
  }

  bool canApply(double cartTotal) {
    if (!isActive) return false;
    if (!isStarted) return false;
    if (isExpired) return false;
    if (isUsageExceeded) return false;
    if (cartTotal < normalizedMinOrder) return false;
    if (!isValidStructure) return false;
    return true;
  }

  bool canApplyForUser(double cartTotal, int userTimesUsed) {
    if (!canApply(cartTotal)) return false;
    if (userTimesUsed >= maxUsagePerUser) return false;
    return true;
  }

  /* ------------------------------------------------ */
  /*              DISCOUNT CALCULATION                */
  /* ------------------------------------------------ */

  double calculateDiscount(double cartTotal) {
    double discount = 0;

    switch (type) {
      case CouponType.percentage:
        discount = (cartTotal * (value ?? 0)) / 100;
        break;

      case CouponType.flat:
        double flatVal = value ?? 0;
        if (flatVal > 0 && flatVal < 1000 && cartTotal >= 1000) {
          flatVal = flatVal * 100;
        }
        discount = flatVal;
        break;

      case CouponType.subscription:
        discount = (cartTotal * (value ?? 0)) / 100;
        break;

      case CouponType.bogo:
        return 0;
    }

    if (maxDiscount != null && maxDiscount! > 0) {
      double cap = maxDiscount!;
      if (cap < 1000 && cartTotal >= 1000) {
        cap = cap * 100;
      }
      if (discount > cap) {
        discount = cap;
      }
    }

    return discount.clamp(0.0, cartTotal);
  }

  /// For BOGO
  int calculateFreeItems(int quantity) {
    if (type != CouponType.bogo || buyQty == null || getQty == null) {
      return 0;
    }

    return (quantity ~/ buyQty!) * getQty!;
  }

  /* ------------------------------------------------ */
  /*          PRODUCT / CATEGORY CHECK                */
  /* ------------------------------------------------ */

  bool isApplicableToProduct(String productId, String categoryId) {
    switch (applyOn) {
      case ApplyOn.allProducts:
        return true;

      case ApplyOn.category:
        return categoryId == applicableCategory;

      case ApplyOn.products:
        return applicableProducts.contains(productId);
    }
  }

  /* ------------------------------------------------ */
  /*               ERROR MESSAGE                      */
  /* ------------------------------------------------ */

  String? rejectReason(double cartTotal, int userTimesUsed) {
    if (!isActive) return 'Coupon is not active';
    if (!isStarted) return 'Coupon is not yet valid';
    if (isExpired) return 'Coupon has expired';
    if (isUsageExceeded) return 'Coupon usage limit reached';
    if (userTimesUsed >= maxUsagePerUser) {
      return 'You have already used this coupon ($userTimesUsed/$maxUsagePerUser times allowed)';
    }
    if (cartTotal < normalizedMinOrder) {
      return 'Minimum order of ${AppConfig.formatPrice(normalizedMinOrder)} is required';
    }
    if (!isValidStructure) return 'Invalid coupon configuration';
    return null;
  }
}
