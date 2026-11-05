import 'dart:io';

import 'package:sure_wholesaler/firebase/user_firestore_ds.dart';
import 'package:sure_wholesaler/models/UserModel.dart';

abstract class UserRepository {
  /// Get user by ID
  Future<UserModel?> getUserById(String userId);

  /// Save user data (create or merge)
  Future<void> saveUser(UserModel user);

  /// Update user data
  Future<bool> updateUser(
    String userId, {
    required String userName,
    required String mobileNo,
    String? userImg,
    required String email,
  });

  /// Watch user by ID (real-time updates)
  Stream<UserModel?> watchUserById(String userId);

  /// Upload profile picture and return download URL
  Future<String?> uploadProfilePicture(String userId, File imageFile);

  /// Get current authenticated user ID
  String? getCurrentUserId();
}

class UserRepositoryImpl implements UserRepository {
  final UserFirestoreDs _firestoreDs;

  UserRepositoryImpl(this._firestoreDs);

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final data = await _firestoreDs.getUserById(userId).first;
      if (data != null) {
        return UserModel.fromMap(data, data['id'] ?? userId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final userId = _firestoreDs.getCurrentUserId();
      if (userId == null) {
        throw Exception('No user logged in');
      }
      await _firestoreDs.saveUser(userId, user.toMap());
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  @override
  Future<bool> updateUser(
    String userId, {
    required String userName,
    required String mobileNo,
    required String email,
    String? userImg,
  }) async {
    try {
      return await _firestoreDs.updateUser(userId, {
        'userName': userName,
        'mobileNo': mobileNo,
        'email': email,
        if (userImg != null) 'userImg': userImg,
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Stream<UserModel?> watchUserById(String userId) {
    try {
      return _firestoreDs.watchUserById(userId).map((data) {
        if (data != null) {
          return UserModel.fromMap(data, data['id'] ?? userId);
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to watch user: $e');
    }
  }

  @override
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      return await _firestoreDs.uploadProfilePicture(userId, imageFile).first;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  @override
  String? getCurrentUserId() {
    return _firestoreDs.getCurrentUserId();
  }
}
