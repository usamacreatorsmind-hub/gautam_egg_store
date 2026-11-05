import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/slider_firestore_ds.dart';
import 'package:sure_wholesaler/models/slider_model.dart';
import 'package:sure_wholesaler/repositories/slider_repository.dart';

/// Repository provider
final sliderRepositoryProvider = Provider<SliderRepository>((ref) {
  return SliderRepositoryImpl(SliderFirestoreDsImpl());
});

/// Main sliders state provider
final sliderProvider =
    StateNotifierProvider<SliderNotifier, AsyncValue<List<SliderModel>>>((ref) {
  return SliderNotifier(ref.read(sliderRepositoryProvider));
});

/// Active sliders only
final activeSlidersProvider = Provider<List<SliderModel>>((ref) {
  final slidersState = ref.watch(sliderProvider);
  final sliders = slidersState.value ?? [];

  return sliders.where((s) => s.isActive).toList();
});

/// Upcoming sliders
final upcomingSlidersProvider = Provider<List<SliderModel>>((ref) {
  final slidersState = ref.watch(sliderProvider);
  final sliders = slidersState.value ?? [];

  return sliders.where((s) => s.isUpcoming).toList();
});

/// Get slider by ID
final sliderByIdProvider =
    Provider.family<SliderModel?, String>((ref, sliderId) {
  final slidersState = ref.watch(sliderProvider);
  final sliders = slidersState.value ?? [];

  try {
    return sliders.firstWhere((s) => s.id == sliderId);
  } catch (_) {
    return null;
  }
});

/// Sliders by category
final slidersByCategoryProvider =
    Provider.family<List<SliderModel>, String>((ref, category) {
  final slidersState = ref.watch(sliderProvider);
  final sliders = slidersState.value ?? [];

  return sliders
      .where((s) => s.isActive && s.category.contains(category))
      .toList();
});

/// Stream provider for real-time slider updates
final slidersStreamProvider = StreamProvider<List<SliderModel>>((ref) {
  final repository = ref.read(sliderRepositoryProvider);
  return repository.watchSliders();
});

class SliderNotifier extends StateNotifier<AsyncValue<List<SliderModel>>> {
  final SliderRepository _repository;
  StreamSubscription<List<SliderModel>>? _subscription;
  StreamSubscription<User?>? _authSubscription;

  SliderNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _init();
    });
  }

  void _init() {
    _subscription?.cancel();
    _subscription = _repository.watchSliders().listen(
      (sliders) {
        state = AsyncValue.data(sliders);
      },
      onError: (error, stackTrace) {
        debugPrint('SliderNotifier stream error: $error');
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

  Stream<List<SliderModel>> getActiveSliders() =>
      _repository.getActiveSliders();

  Future<void> incrementClicks(String sliderId) async {
    try {
      await _repository.incrementClicks(sliderId);
      // Local state will be updated through the stream subscription
    } catch (e) {
      // Handle error silently or rethrow based on requirements
    }
  }

  Stream<List<SliderModel>> watchSliders() {
    return _repository.watchSliders();
  }

  Stream<SliderModel?> getSliderById(String sliderId) =>
      _repository.getSliderById(sliderId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
