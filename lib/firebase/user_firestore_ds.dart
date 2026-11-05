import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class UserFirestoreDs {
  /// Get user by ID
  Stream<Map<String, dynamic>?> getUserById(String userId);

  /// Save user data (create or merge)
  Future<void> saveUser(String userId, Map<String, dynamic> data);

  /// Update user data
  Future<bool> updateUser(String userId, Map<String, dynamic> data);

  /// Watch user by ID (real-time updates)
  Stream<Map<String, dynamic>?> watchUserById(String userId);

  /// Upload profile picture and return download URL
  Stream<String?> uploadProfilePicture(String userId, File imageFile);

  /// Get current authenticated user ID
  String? getCurrentUserId();
}

class UserFirestoreDsImpl implements UserFirestoreDs {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final String _collectionName = Collections.users;

  UserFirestoreDsImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? AppConfig.firestore,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _userCollection => _firestore.collection(_collectionName);

  @override
  Stream<Map<String, dynamic>?> getUserById(String userId) async* {
    try {
      final docSnapshot = await _userCollection.doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        yield data;
      }
      yield null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  @override
  Future<void> saveUser(String userId, Map<String, dynamic> data) async {
    try {
      await _userCollection.doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  @override
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _userCollection.doc(userId).update(data);
      return true;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchUserById(String userId) {
    try {
      return _userCollection.doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          data['id'] = snapshot.id;
          return data;
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to watch user: $e');
    }
  }

  @override
  Stream<String?> uploadProfilePicture(String userId, File imageFile) async* {
    try {
      final storageRef = _storage.ref().child('profile_pictures').child('$userId.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with new image URL
      await _userCollection.doc(userId).set({
        'userImg': downloadUrl,
      }, SetOptions(merge: true));

      yield downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  @override
  @override
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
