import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return AppConfig.firestore;
});
