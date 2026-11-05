import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/features/searchLog/models/popular_searches_model.dart';
import 'package:sure_wholesaler/features/searchLog/models/search_log_model.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';

final popularSearchRepositoryProvider =
    Provider<FirestoreRepository<PopularSearchModel>>(
  (ref) => FirestoreRepository<PopularSearchModel>(
    collectionPath: AppCollections.popularSearches,
    fromFirestore: (doc) =>
        PopularSearchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
  ),
);

final incrementSearchCount = Provider((ref) {
  return (String keyword) async {
    final repository = ref.read(popularSearchRepositoryProvider);
    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedKeyword.isEmpty) return;

    final existingDoc = await repository.getById(normalizedKeyword);
    if (existingDoc != null) {
      final updatedModel = existingDoc.copyWith(
        searchCount: existingDoc.searchCount + 1,
        updatedAt: DateTime.now(),
      );
      await repository.update(
          updatedModel.id, updatedModel as Map<String, dynamic>);
    } else {
      final newModel = PopularSearchModel(
        id: normalizedKeyword,
        keyword: normalizedKeyword,
        searchCount: 1,
        isTrending: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.create(newModel);
    }
  };
});

final fetchTrendingSearchesProvider =
    FutureProvider<List<PopularSearchModel>>((ref) async {
  final repository = ref.read(popularSearchRepositoryProvider);
  final allSearches = await repository.getAll(
      orderBy: 'searchCount', descending: true, limit: 10);
  return allSearches.where((s) => s.isTrending).toList();
});
