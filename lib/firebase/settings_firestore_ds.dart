import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';

abstract class SettingsFirestoreDs {
  Future<Map<String, dynamic>?> getGeneralSettings();
  Stream<Map<String, dynamic>?> watchGeneralSettings();
}

class SettingsFirestoreDsImpl implements SettingsFirestoreDs {
  final FirebaseFirestore _firestore;

  SettingsFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  @override
  Future<Map<String, dynamic>?> getGeneralSettings() async {
    final doc = await _firestore.collection(Collections.settings).doc('general').get();
    return doc.data();
  }

  @override
  Stream<Map<String, dynamic>?> watchGeneralSettings() {
    return _firestore.collection(Collections.settings).doc('general').snapshots().map((snap) => snap.data());
  }
}
