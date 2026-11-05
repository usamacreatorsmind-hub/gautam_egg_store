import 'package:fade_shimmer/fade_shimmer.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:sure_wholesaler/utils/image_url_utils.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImagePreviewScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;
  bool _autoSlide = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    final validUrls = validImageUrls(widget.imageUrls);

    if (validUrls.length > 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_autoSlide) _startAutoSlide();
      });
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final validUrls = validImageUrls(widget.imageUrls);
      _currentIndex = (_currentIndex + 1) % validUrls.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleAutoSlide() {
    setState(() {
      _autoSlide = !_autoSlide;
      _autoSlide ? _startAutoSlide() : _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrls = validImageUrls(widget.imageUrls);

    if (imageUrls.isEmpty) {
      return const Scaffold(
        body: Center(child: Icon(Icons.broken_image_outlined)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          /// Full-screen gallery
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: imageUrls.length,
            backgroundDecoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            builder: (_, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: imageUrls[index],
                ),
              );
            },
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            loadingBuilder: (_, event) => Center(
              child: FadeShimmer.round(
                size: 30,
                baseColor: Colors.grey,
                highlightColor: Colors.white,
              ),
            ),
          ),

          /// Close button
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: _OverlayButton(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),

          /// Auto-slide toggle
          if (imageUrls.length > 1)
            Positioned(
              top: 40,
              right: 20,
              child: SafeArea(
                child: _OverlayButton(
                  icon: _autoSlide ? Icons.pause : Icons.play_arrow,
                  onTap: _toggleAutoSlide,
                ),
              ),
            ),

          /// Counter + dots
          if (imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _OverlayLabel(
                    text: '${_currentIndex + 1} / ${imageUrls.length}',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imageUrls.length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Overlay icon button (theme-aware)
class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Overlay label pill
class _OverlayLabel extends StatelessWidget {
  final String text;

  const _OverlayLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
