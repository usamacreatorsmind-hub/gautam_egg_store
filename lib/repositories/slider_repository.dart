import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/firebase/slider_firestore_ds.dart';
import 'package:sure_wholesaler/models/slider_model.dart';

abstract class SliderRepository {
  Stream<List<SliderModel>> getSliders();
  Stream<SliderModel?> getSliderById(String sliderId);
  Stream<List<SliderModel>> getSlidersWhere({
    required String field,
    required dynamic value,
  });
  Stream<List<SliderModel>> getActiveSliders();
  Future<void> incrementClicks(String sliderId);
  Stream<List<SliderModel>> watchSliders();
  Stream<SliderModel?> watchSliderById(String sliderId);
}

class SliderRepositoryImpl implements SliderRepository {
  final SliderFirestoreDs _firestoreDs;

  SliderRepositoryImpl(this._firestoreDs);

  SliderModel _mapToModel(Map<String, dynamic> data) {
    return SliderModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: List<String>.from(data['category'] ?? []),
      clicks: data['clicks'] ?? 0,
      status: data['status'] ?? '',
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  @override
  Stream<List<SliderModel>> getSliders() {
    return _firestoreDs.getSliders().map(
          (dataList) => dataList.map(_mapToModel).toList(),
        );
  }

  @override
  Stream<SliderModel?> getSliderById(String sliderId) {
    return _firestoreDs.getSliderById(sliderId).map(
          (data) => data != null ? _mapToModel(data) : null,
        );
  }

  @override
  Stream<List<SliderModel>> getSlidersWhere({
    required String field,
    required dynamic value,
  }) {
    return _firestoreDs
        .getSlidersWhere(field: field, value: value)
        .map((dataList) => dataList.map(_mapToModel).toList());
  }

  @override
  Stream<List<SliderModel>> getActiveSliders() {
    return _firestoreDs.getActiveSliders().map(
          (dataList) => dataList.map(_mapToModel).toList(),
        );
  }

  @override
  Future<void> incrementClicks(String sliderId) async {
    await _firestoreDs.incrementClicks(sliderId);
  }

  @override
  Stream<List<SliderModel>> watchSliders() {
    return _firestoreDs.watchSliders().map(
          (dataList) => dataList.map(_mapToModel).toList(),
        );
  }

  @override
  Stream<SliderModel?> watchSliderById(String sliderId) {
    return _firestoreDs.watchSliderById(sliderId).map(
          (data) => data != null ? _mapToModel(data) : null,
        );
  }
}
