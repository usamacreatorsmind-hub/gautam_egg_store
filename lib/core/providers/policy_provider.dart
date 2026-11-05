import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

class PolicyModel {
  final String privacyUrl;
  final String termsUrl;
  final String disclaimerUrl;

  PolicyModel({
    required this.privacyUrl,
    required this.termsUrl,
    required this.disclaimerUrl,
  });

  factory PolicyModel.fromMap(Map<String, dynamic> map) {
    return PolicyModel(
      privacyUrl: map['privacyurl'] ?? AppConfig.privacyPolicyUrl,
      termsUrl: map['termandconditionurl'] ?? AppConfig.termsOfServiceUrl,
      disclaimerUrl: map['disclaimerurl'] ?? AppConfig.disclaimerUrl,
    );
  }
}

final policyProvider = FutureProvider<PolicyModel>((ref) async {
  try {
    final snapshot = await AppConfig.firestore.collection('policy').get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return PolicyModel.fromMap(data);
    }
  } catch (e) {
    // Fallback to default AppConfig URLs
  }
  return PolicyModel(
    privacyUrl: AppConfig.privacyPolicyUrl,
    termsUrl: AppConfig.termsOfServiceUrl,
    disclaimerUrl: AppConfig.disclaimerUrl,
  );
});
