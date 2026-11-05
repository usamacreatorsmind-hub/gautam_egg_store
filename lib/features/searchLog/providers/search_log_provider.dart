import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/features/searchLog/models/search_log_model.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';

final searchLogRepositoryProvider =
    Provider<FirestoreRepository<SearchLogModel>>(
  (ref) => FirestoreRepository<SearchLogModel>(
    collectionPath: AppCollections.searchLogs,
    fromFirestore: (doc) =>
        SearchLogModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
  ),
);

/// Logs a search keyword to Firestore.
///
/// Write guards (all must pass):
///   1. User must be logged in.
///   2. Keyword must be ≥ 3 characters after trimming.
///   3. Same keyword (case-insensitive) must not have been logged this session.
///   4. At least 5 seconds must have elapsed since the last write.
final submitSearchLogProvider = Provider((ref) {
  final repository = ref.read(searchLogRepositoryProvider);

  // Session-scoped state — lives as long as the provider lives.
  final sessionSeen = <String>{};
  DateTime? lastWrite;

  return ({
    required String keyword,
    required String hubId,
    required String serviceArea,
  }) async {
    final key = keyword.trim().toLowerCase();

    // Guard 1 — minimum length
    if (key.length < 5) return;

    // Guard 2 — session dedup
    if (sessionSeen.contains(key)) return;

    // Guard 3 — rate limit (5 s between writes)
    final now = DateTime.now();
    if (lastWrite != null &&
        now.difference(lastWrite!) < const Duration(seconds: 5)) {
      return;
    }

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    sessionSeen.add(key);
    lastWrite = now;

    final searchLog = SearchLogModel(
      keyword: key,
      uid: uid,
      hubId: hubId,
      dateTime: now,
      serviceArea: serviceArea,
    );

    await repository.create(searchLog);
  };
});
