
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/utils/image_url_utils.dart';
import 'package:sure_wholesaler/widgets/Image_Preview_Screen.dart';

import 'image_builder.dart';

class ProductImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final double borderRadius;

  const ProductImageSlider({
    super.key,
    required this.imageUrls,
    this.height = 100,
    this.borderRadius = 20,
  });

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    final imageUrls = validImageUrls(widget.imageUrls);
    if (imageUrls.length > 1) {
      _startAutoSlide();
    }
  }

  @override
  void didUpdateWidget(ProductImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the image list changes, reset the slider to the first image
    if (widget.imageUrls != oldWidget.imageUrls) {
      _timer?.cancel();
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      final imageUrls = validImageUrls(widget.imageUrls);
      if (imageUrls.length > 1) {
        _startAutoSlide();
      }
      setState(() {});
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final currentUrls = validImageUrls(widget.imageUrls);
      if (currentUrls.isEmpty) return;

      _currentPage = (_currentPage + 1) % currentUrls.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
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

    return Container(
      height: widget.height.h,
      margin: EdgeInsets.all(5.w),
      decoration: BoxDecoration(),
      child: GestureDetector(
        onDoubleTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImagePreviewScreen(
                imageUrls: widget.imageUrls,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.r),
            topRight: Radius.circular(15.r),
          ),
          child: imageUrls.isNotEmpty
              ? Stack(
                  children: [
                    /// Image slider
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: imageUrls.length,
                      itemBuilder: (_, index) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          child: ImageBuilder(
                            url: imageUrls[index],
                            fit: BoxFit.contain, // Changed from cover to show full image
                            width: double.infinity,
                          ),
                        );
                      },
                    ),

                    /// Page indicator
                    if (imageUrls.length > 1)
                      Positioned(
                        bottom: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${imageUrls.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40.sp,
                    color: theme.colorScheme.outline,
                  ),
                ),
        ),
      ),
    );
  }
}
