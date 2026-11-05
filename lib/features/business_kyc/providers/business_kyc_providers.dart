import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../generics/generic_firestore.dart';
import '../models/business_kyc_model.dart';

final businessKycRepositoryProvider =
    Provider<FirestoreRepository<BusinessKycModel>>(
  (ref) => FirestoreRepository<BusinessKycModel>(
    firestore: AppConfig.firestore,
    collectionPath: AppCollections.businessKyc,
    fromFirestore: (doc) => BusinessKycModel.fromMap(
        doc.data() as Map<String, dynamic>
          ..['id'] = doc.id), // Include the document ID in the model
  ),
);

final businessKycByUserIdProvider =
    StreamProvider.family<BusinessKycModel?, String>((ref, uid) {
  return ref
      .read(businessKycRepositoryProvider)
      .streamQuery(
        (q) => q.where('userId', isEqualTo: uid).limit(1),
      )
      .map((list) => list.isNotEmpty ? list.first : null);
});

// ============================================================
// CRUD OPERATIONS
// ============================================================

final businessKycControllerProvider = Provider((ref) {
  final repository = ref.watch(businessKycRepositoryProvider);
  return BusinessKycController(repository);
});

class BusinessKycController {
  final FirestoreRepository<BusinessKycModel> _repository;

  BusinessKycController(this._repository);

  Future<String> createKyc(BusinessKycModel kyc) async {
    return await _repository.create(kyc);
  }

  Future<void> updateKyc(BusinessKycModel kyc) async {
    await _repository.update(kyc.id, kyc.toMap());
  }

  Future<void> deleteKyc(String id) async {
    await _repository.delete(id);
  }

  Future<void> setKyc(BusinessKycModel kyc) async {
    await _repository.set(kyc);
  }
}
