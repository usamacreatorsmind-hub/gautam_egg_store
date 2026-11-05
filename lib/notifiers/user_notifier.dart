import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/user_firestore_ds.dart';
import 'package:sure_wholesaler/models/UserModel.dart';
import 'package:sure_wholesaler/repositories/user_repository.dart';

/// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(UserFirestoreDsImpl());
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final repository = ref.read(userRepositoryProvider);
  return repository.getCurrentUserId();
});

/// Main user state provider
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return UserNotifier(ref.read(userRepositoryProvider), userId);
});

/// Watch user by ID (for viewing other users' profiles)
final userByIdProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  final repository = ref.read(userRepositoryProvider);
  return repository.watchUserById(userId);
});

/// Get user by ID (one-time fetch)
final fetchUserByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repository = ref.read(userRepositoryProvider);
  return repository.getUserById(userId);
});

final fetchCurrentUser = FutureProvider<UserModel?>((ref) async {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return null;

  final repository = ref.read(userRepositoryProvider);
  return repository.getUserById(uid);
});

/// Profile update state
final profileUpdateLoadingProvider = StateProvider<bool>((ref) => false);

/// Profile picture upload state
final profilePictureUploadingProvider = StateProvider<bool>((ref) => false);

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository _repository;
  final String? _userId;
  StreamSubscription<UserModel?>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  UserNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _init();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _init();
    });
  }

  void _init() {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    _subscription?.cancel();
    _subscription = _repository.watchUserById(_userId!).listen(
      (user) {
        state = AsyncValue.data(user);
      },
      onError: (error, stackTrace) {
        debugPrint('UserNotifier stream error: $error');
        state = AsyncValue.error(error, stackTrace);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.hasError) {
            _init();
          }
        });
      },
    );
  }

  Future<void> refresh() async {
    _init();
  }

  Future<bool> updateUser({
    required String userName,
    required String mobileNo,
    required String email,
    String? userImgUrl,
  }) async {
    if (_userId == null) return false;

    try {
      return await _repository.updateUser(
        _userId!,
        userName: userName,
        userImg: userImgUrl,
        mobileNo: mobileNo,
        email: email,
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _repository.saveUser(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadProfilePicture(File imageFile) async {
    if (_userId == null) return null;
    return await _repository.uploadProfilePicture(_userId!, imageFile);
  }

  Future<UserModel?> getUserById(String userId) async {
    return await _repository.getUserById(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
