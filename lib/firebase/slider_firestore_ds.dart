import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';

abstract class SliderFirestoreDs {
  /// Fetch all sliders
  Stream<List<Map<String, dynamic>>> getSliders();

  /// Fetch a single slider by ID
  Stream<Map<String, dynamic>?> getSliderById(String sliderId);

  /// Fetch sliders with a specific filter
  Stream<List<Map<String, dynamic>>> getSlidersWhere({
    required String field,
    required dynamic value,
  });

  /// Fetch active sliders only
  Stream<List<Map<String, dynamic>>> getActiveSliders();

  /// Increment click count for a slider
  Future<void> incrementClicks(String sliderId);

  /// Watch sliders (real-time updates)
  Stream<List<Map<String, dynamic>>> watchSliders();

  /// Watch a single slider by ID
  Stream<Map<String, dynamic>?> watchSliderById(String sliderId);
}

class SliderFirestoreDsImpl implements SliderFirestoreDs {
  final FirebaseFirestore _firestore;
  final String _collectionName = Collections.sliders;

  SliderFirestoreDsImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? AppConfig.firestore;

  CollectionReference get _sliderCollection =>
      _firestore.collection(_collectionName);

  @override
  Stream<List<Map<String, dynamic>>> getSliders() async* {
    try {
      final querySnapshot =
          await _sliderCollection.orderBy('createdAt', descending: true).get();
      yield querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch sliders: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> getSliderById(String sliderId) async* {
    try {
      final docSnapshot = await _sliderCollection.doc(sliderId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id;
        yield data;
      } else {
        yield null;
      }
    } catch (e) {
      throw Exception('Failed to fetch slider: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getSlidersWhere({
    required String field,
    required dynamic value,
  }) async* {
    try {
      final querySnapshot = await _sliderCollection
          .where(field, isEqualTo: value)
          .orderBy('createdAt', descending: true)
          .get();
      yield querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch filtered sliders: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getActiveSliders() async* {
    try {
      final querySnapshot = await _sliderCollection
          .where('status', isEqualTo: SliderStatus.active)
          .orderBy('createdAt', descending: true)
          .get();
      yield querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch active sliders: $e');
    }
  }

  @override
  Future<void> incrementClicks(String sliderId) async {
    try {
      await _sliderCollection.doc(sliderId).update({
        'clicks': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment clicks: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchSliders() {
    try {
      return _sliderCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to watch sliders: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> watchSliderById(String sliderId) {
    try {
      return _sliderCollection.doc(sliderId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          data['id'] = snapshot.id;
          return data;
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to watch slider: $e');
    }
  }
}
