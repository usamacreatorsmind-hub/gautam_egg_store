import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/models/brand_model.dart';
import 'package:sure_wholesaler/repositories/brand_repository.dart';

// extract providers
final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepositoryImpl();
});

final brandsProvider =
    StateNotifierProvider<BrandNotifier, AsyncValue<List<BrandModel>>>((ref) {
  return BrandNotifier(ref.read(brandRepositoryProvider));
});

class BrandNotifier extends StateNotifier<AsyncValue<List<BrandModel>>> {
  final BrandRepository _repository;
  StreamSubscription<List<BrandModel>>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  BrandNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _init();
    });
  }

  void _init() {
    _subscription?.cancel();
    _subscription = _repository.watchBrands().listen(
      (brands) {
        state = AsyncValue.data(brands);
      },
      onError: (error, stackTrace) {
        debugPrint('BrandNotifier stream error: $error');
        state = AsyncValue.error(error, stackTrace);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.hasError) {
            _init();
          }
        });
      },
    );
  }

  void refresh() {
    _init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
