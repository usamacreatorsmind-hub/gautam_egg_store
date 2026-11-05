import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/models/story_item_model.dart';
import 'package:sure_wholesaler/notifiers/product_notifier.dart';
import 'package:sure_wholesaler/repositories/story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(ref.read(productRepositoryProvider));
});

/// Real-time story items for a category — used by [ItemStoryScreen].
final storiesByCategoryProvider =
    StreamProvider.family<List<StoryItemModel>, String>((ref, categoryId) {
  return ref.watch(storyRepositoryProvider).watchStoriesByCategory(categoryId);
});

/// All story items across every category — used by a home-screen story rail.
final allStoriesProvider = StreamProvider<List<StoryItemModel>>((ref) {
  return ref.watch(storyRepositoryProvider).watchAllStories();
});

/// Per-category story availability flag — lets the category slider show/hide
/// the story ring without loading the full story list.
final categoryHasStoriesProvider =
    Provider.family<bool, String>((ref, categoryId) {
  return ref.watch(storiesByCategoryProvider(categoryId)).maybeWhen(
        data: (items) => items.isNotEmpty,
        orElse: () => false,
      );
});
