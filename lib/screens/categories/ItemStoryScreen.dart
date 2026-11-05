import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/widgets/story_view.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/models/story_item_model.dart';
import 'package:sure_wholesaler/notifiers/story_notifier.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class ItemStoryScreen extends ConsumerStatefulWidget {
  final String docId;

  const ItemStoryScreen({
    super.key,
    required this.docId,
  });

  @override
  ConsumerState<ItemStoryScreen> createState() => _ItemStoryScreenState();
}

class _ItemStoryScreenState extends ConsumerState<ItemStoryScreen> {
  final StoryController _controller = StoryController();
  StoryItemModel? _current;
  List<StoryItem>? _builtItems;
  List<StoryItemModel>? _snapshot;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final storiesAsync = ref.watch(storiesByCategoryProvider(widget.docId));

    return Scaffold(
      body: storiesAsync.when(
        loading: () => const Center(
          child: AppLoader(color: AppColors.onBrand),
        ),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: AppColors.onBrand),
          ),
        ),
        data: (stories) {
          if (stories.isEmpty) {
            return const Center(
              child: Text(
                'No story items available',
                style: TextStyle(color: AppColors.onBrand),
              ),
            );
          }

          // Rebuild StoryView only when the list identity changes.
          final needsRebuild = _snapshot == null ||
              _snapshot!.length != stories.length ||
              _snapshot!.first.id != stories.first.id;

          if (needsRebuild) {
            _snapshot = stories;
            _builtItems = stories
                .map((s) => StoryItem.pageImage(
                      url: s.primaryMediaUrl,
                      controller: _controller,
                      imageFit: BoxFit.cover,
                    ))
                .toList();
            _current ??= stories.first;
          }

          final display = _current ?? stories.first;

          return Stack(
            children: [
              StoryView(
                storyItems: _builtItems!,
                controller: _controller,
                repeat: false,
                onStoryShow: (_, index) {
                  if (_snapshot != null && index < _snapshot!.length) {
                    final item = _snapshot![index];
                    if (_current?.id != item.id) {
                      setState(() => _current = item);
                    }
                  }
                },
                onComplete: () => Navigator.pop(context),
              ),

              // ───────── TOP BAR ─────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Product Story',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppColors.onBrand),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onBrand),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ───────── PRODUCT INFO ─────────
              Positioned(
                bottom: 130,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: AppColors.onBrand),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      display.price,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ───────── ACTION BUTTONS ─────────
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    _viewButton(display, scheme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _viewButton(StoryItemModel story, ColorScheme scheme) {
    return Expanded(
      child: AnimatedButton(
        text: 'VIEW',
        height: 50,
        borderRadius: 14,
        borderWidth: 0,
        animatedOn: AnimatedOn.onTap,
        backgroundColor: scheme.primary,
        textStyle: const TextStyle(fontSize: 15, color: AppColors.onBrand),
        onPress: () => _onView(story),
      ),
    );
  }

  void _onView(StoryItemModel story) {
    if (story.source != null) {
      context.push('/product/${story.productId}', extra: story.source);
    } else {
      context.push('/product/${story.productId}');
    }
  }
}
