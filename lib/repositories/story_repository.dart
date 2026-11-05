import 'package:sure_wholesaler/models/story_item_model.dart';
import 'package:sure_wholesaler/repositories/product_repository.dart';

abstract class StoryRepository {
  /// Real-time stream of story items for a given category.
  /// Only returns products where [isStoryItem == true] and [imageUrls] is non-empty.
  Stream<List<StoryItemModel>> watchStoriesByCategory(String categoryId);

  /// All story items across every category (for a home-screen story rail).
  Stream<List<StoryItemModel>> watchAllStories();
}

class StoryRepositoryImpl implements StoryRepository {
  final ProductRepository _productRepository;

  StoryRepositoryImpl(this._productRepository);

  @override
  Stream<List<StoryItemModel>> watchStoriesByCategory(String categoryId) {
    return _productRepository.watchProductsByCategory(categoryId).map(
        (products) => products
            .where((p) => p.isStoryItem && p.imageUrls.isNotEmpty)
            .map(StoryItemModel.fromProduct)
            .toList());
  }

  @override
  Stream<List<StoryItemModel>> watchAllStories() {
    return _productRepository.watchProducts().map((products) => products
        .where((p) => p.isStoryItem && p.imageUrls.isNotEmpty)
        .map(StoryItemModel.fromProduct)
        .toList());
  }
}
