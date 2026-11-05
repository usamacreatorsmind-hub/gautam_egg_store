import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/models/slider_model.dart';
import '../constants/app_constants.dart';

class SliderDataPush {
  final FirebaseFirestore _firestore = AppConfig.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<SliderModel> _generateInitialData(String uid) {
    return [
      SliderModel(
        id: _firestore.collection(Collections.sliders).doc().id,
        title: 'Mega Electronics Sale',
        imageUrl:
            'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=1200',
        category: ['Electronics'],
        clicks: 0,
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      SliderModel(
        id: _firestore.collection(Collections.sliders).doc().id,
        title: 'New Fashion Collection',
        imageUrl:
            'https://images.unsplash.com/photo-1445205170230-053b83016050?w=1200',
        category: ['Fashion'],
        clicks: 0,
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      SliderModel(
        id: _firestore.collection(Collections.sliders).doc().id,
        title: 'Home & Living Deals',
        imageUrl:
            'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200',
        category: ['Home'],
        clicks: 0,
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      SliderModel(
        id: _firestore.collection(Collections.sliders).doc().id,
        title: 'Beauty Essentials',
        imageUrl:
            'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1200',
        category: ['Beauty'],
        clicks: 0,
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      SliderModel(
        id: _firestore.collection(Collections.sliders).doc().id,
        title: 'Big Discount Offers',
        imageUrl:
            'https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=1200',
        category: ['Offers'],
        clicks: 0,
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Add more sliders as needed
    ];
  }

  /// Push slider data to Firestore
  Future<void> pushData() async {
    await clearData();
    debugPrint('Pushing slider data...');

    final batch = _firestore.batch();
    final sliders = _generateInitialData(_auth.currentUser?.uid ?? '');

    for (final slider in sliders) {
      batch.set(
        _firestore.collection(Collections.sliders).doc(slider.id),
        slider.toFirestore(),
      );
    }

    await batch.commit();
    debugPrint('Slider data pushed successfully');
  }

  /// Clear all slider data from Firestore
  Future<void> clearData() async {
    debugPrint('Clearing slider data...');

    final snapshot = await _firestore.collection(Collections.sliders).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    debugPrint('Slider data cleared successfully');
  }
}
