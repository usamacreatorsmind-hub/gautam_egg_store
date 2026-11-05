import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';

enum DeliveryType {
  quick,
  scheduled,
}

extension DeliveryTypeExtension on DeliveryType {
  String get label {
    switch (this) {
      case DeliveryType.quick:
        return 'Quick';
      case DeliveryType.scheduled:
        return 'Scheduled';
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryType.quick:
        return Icons.flash_on;
      case DeliveryType.scheduled:
        return Icons.schedule;
    }
  }

  Color get color {
    switch (this) {
      case DeliveryType.quick:
        return AppColors.success;
      case DeliveryType.scheduled:
        return AppColors.info;
    }
  }
}

class DeliveryConfig {
  final bool enabled;
  final bool subscription;

  const DeliveryConfig({
    required this.enabled,
    required this.subscription,
  });

  factory DeliveryConfig.fromMap(Map<String, dynamic> map) {
    return DeliveryConfig(
      enabled: map['enabled'] ?? false,
      subscription: map['subscription'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'subscription': subscription,
    };
  }

  @override
  String toString() {
    return 'DeliveryConfig(enabled: $enabled, subscription: $subscription)';
  }
}
