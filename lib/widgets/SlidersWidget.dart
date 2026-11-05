
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sure_wholesaler/state_management/providers/slider_provider.dart';
import 'package:sure_wholesaler/widgets/ProductsWidget.dart';
import '../models/slider_model.dart';
import 'image_builder.dart';

class SliderWidget extends ConsumerStatefulWidget {
  const SliderWidget({super.key});

  @override
  ConsumerState<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends ConsumerState<SliderWidget> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final double sliderHeight = 200.h;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_controller.hasClients) {
        final sliders = ref.read(activeUpcomingSlidersProvider);
        if (sliders.isNotEmpty) {
          final nextPage = (_currentPage + 1) % sliders.length;
          _controller.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildIndicator(BuildContext context, int index) {
    final isActive = index == _currentPage;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: 4.w,
      ),
      height: 8.h,
      width: isActive ? 24.w : 8.w,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.secondary
            : theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, SliderModel item) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: ImageBuilder(
        url: item.imageUrl,
        width: 1.sw,
        height: sliderHeight,
        fit: BoxFit.cover,
      ),
    );
  }

  void _handleSlideTap(SliderModel item, BuildContext context) {
    if (item.status == SliderStatus.upcoming) {
      _showUpcomingPopup(context, item);
      return;
    }
    if (item.status != SliderStatus.active) return;

    _trackClick(item.id);

    switch (item.actionType) {
      case SliderActionType.product:
        if (item.actionTarget.isNotEmpty) {
          context.push(AppRoutes.productDetailsPath(item.actionTarget));
        }
      case SliderActionType.offer:
        context.push(AppRoutes.offers);
      case SliderActionType.url:
        if (item.actionTarget.isNotEmpty) {
          _launchUrl(item.actionTarget);
        }
      case SliderActionType.none:
        break;
      default: // 'category' or legacy
        if (item.category.isNotEmpty) {
          _navigateToProducts(context, item);
        }
    }
  }

  void _trackClick(String sliderId) {
    AppConfig.firestore
        .collection(Collections.sliders)
        .doc(sliderId)
        .update({'clicks': FieldValue.increment(1)}).catchError((_) {});
  }

  Future<void> _launchUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUpcomingPopup(BuildContext context, SliderModel item) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = item.startDate.toLocal().toString().split(' ')[0];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.schedule_rounded, color: scheme.primary, size: 22.sp),
            SizedBox(width: 8.w),
            Text('Coming Soon', style: theme.textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: theme.textTheme.titleMedium),
            SizedBox(height: 8.h),
            Text('This offer goes live on', style: theme.textTheme.bodyMedium),
            SizedBox(height: 4.h),
            Text(start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                )),
          ],
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _navigateToProducts(BuildContext context, SliderModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsWidget(
          categoryIds: item.category,
          sliderTitle: item.title,
        ),
      ),
    );
  }

  Widget _buildStateContainer(BuildContext context, Widget child) {
    final theme = Theme.of(context);

    return Container(
      height: sliderHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);

    return _buildStateContainer(
      context,
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              color: theme.colorScheme.error, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            'Error loading sliders',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final theme = Theme.of(context);

    return _buildStateContainer(
      context,
      LoadingAnimationWidget.staggeredDotsWave(
        color: theme.colorScheme.primary,
        size: 60.sp,
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    final theme = Theme.of(context);

    return _buildStateContainer(
      context,
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search_outlined,
              color: theme.colorScheme.outline, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            'No active or upcoming sliders',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sliderAsyncValue = ref.watch(imageSliderProvider);

    return sliderAsyncValue.when(
      loading: () => _buildLoadingWidget(context),
      error: (_, __) => _buildErrorWidget(context),
      data: (allSliders) {
        final sliders =
            allSliders.where((s) => s.status != SliderStatus.expired).toList();

        if (sliders.isEmpty) {
          return _buildEmptyWidget(context);
        }

        return Column(
          children: [
            SizedBox(
              height: sliderHeight,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() {
                  _currentPage = index;
                }),
                itemCount: sliders.length,
                itemBuilder: (context, index) {
                  final item = sliders[index];
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
                    child: GestureDetector(
                      onTap: () => _handleSlideTap(item, context),
                      child: _buildSlide(context, item),
                    ),
                  );
                },
              ),
            ),
            if (sliders.length > 1) ...[
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  sliders.length,
                  (i) => _buildIndicator(context, i),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
