import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/slider_model.dart';

final imageSliderProvider = FutureProvider<List<SliderModel>>((ref) async {
  try {
    final snapshot = await AppConfig.firestore
        .collection(Collections.sliders).get();

    final sliders = snapshot.docs.map((doc) => SliderModel.fromFirestore(doc)).toList();
    
    // Sort safely in Dart
    sliders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sliders;
  } catch (e) {
    if (kDebugMode == true) debugPrint('Error fetching sliders: $e');
    rethrow;
  }
});

// Active और Upcoming sliders के लिए Provider (expired filter करें)
final activeUpcomingSlidersProvider = Provider<List<SliderModel>>((ref) {
  final allSliders = ref.watch(imageSliderProvider);

  return allSliders.when(
    data: (sliders) {
      // Expired status वाले filter करें
      return sliders.where((slider) => slider.status != SliderStatus.expired).toList();
    },
    loading: () => [],
    error: (error, stackTrace) {
      if (kDebugMode == true) debugPrint('Error: $error');
      return [];
    },
  );
});
