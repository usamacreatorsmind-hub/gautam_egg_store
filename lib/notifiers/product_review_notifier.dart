import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/notifiers/user_notifier.dart';
import 'package:sure_wholesaler/screens/product/product_review_model.dart';

final productReviewRepositoryProvider =
    Provider<FirestoreRepository<ProductReviewModel>>(
  (ref) => FirestoreRepository<ProductReviewModel>(
    collectionPath: AppCollections.productReviews,
    fromFirestore: (doc) => ProductReviewModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    ),
  ),
);

final productReviewsProvider =
    StreamProvider.family<List<ProductReviewModel>, String>((ref, productId) {
  return ref.read(productReviewRepositoryProvider).streamQuery(
        (q) => q
            .where('productId', isEqualTo: productId)
            .orderBy('createdAt', descending: true),
      );
});

final myProductReviewsProvider =
    StreamProvider.family<List<ProductReviewModel>, String>((ref, productId) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.read(productReviewRepositoryProvider).streamQuery(
        (q) => q
            .where('productId', isEqualTo: productId)
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true),
      );
});

/// submit review provider
///
///
final submitReviewProvider = Provider((ref) {
  final repository = ref.read(productReviewRepositoryProvider);

  return ({
    required String productId,
    required String orderId,
    required String orderItemId,
    required double rating,
    required String title,
    required String comment,
  }) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      throw Exception("User not logged in. Cannot submit a review.");
    }

    // Note: In a real app, you'd get the userId from your auth provider
    // For this example, we'll assume a placeholder or that it's handled in the repo
    final review = ProductReviewModel(
      productId: productId,
      userId: uid, // Use uid directly after null check
      orderId: orderId,
      orderItemId: orderItemId,
      rating: rating,
      title: title,
      comment: comment,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      id: '',
    );

    await repository.create(review);
  };
});

// check for order review if already reviwed fo the  order by the user
final hasReviewedOrderItemProvider =
    FutureProvider.family<bool, String>((ref, orderItemId) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return false;

  final repository = ref.read(productReviewRepositoryProvider);
  final reviews = await repository.query(
    (q) => q
        .where('orderItemId', isEqualTo: orderItemId)
        .where('userId', isEqualTo: uid)
        .limit(1),
  );
  return reviews.isNotEmpty;
});
