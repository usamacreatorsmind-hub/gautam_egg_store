import 'package:cached_network_image/cached_network_image.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/utils/image_url_utils.dart';

/// Performance-optimized ImageBuilder widget.
///
/// Features:
/// - Automatic memory caching caps (memCacheWidth/memCacheHeight) to avoid decoding heavy bitmaps.
/// - Dynamic URL optimization (for Unsplash, Cloudinary, etc.) via [getOptimizedImageUrl].
/// - Smooth shimmer placeholders for enhanced visual responsiveness.
class ImageBuilder extends StatelessWidget {
  /// Network URL. Takes priority over [imageProvider].
  final String? url;

  /// Any non-network ImageProvider (AssetImage, MemoryImage, …).
  final ImageProvider? imageProvider;

  /// For backwards-compatibility: an arbitrary ImageProvider.
  /// If it is a NetworkImage the URL is extracted automatically.
  final ImageProvider? image;

  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Explicit memory decode cache override (optional).
  final int? memCacheWidth;
  final int? memCacheHeight;

  const ImageBuilder({
    super.key,
    this.url,
    this.imageProvider,
    this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  // ── helpers ────────────────────────────────────────────────────────────────

  String? get _resolvedUrl {
    final candidate =
        url ?? (image is NetworkImage ? (image as NetworkImage).url : null);
    final targetW = _calculatedMemWidth;
    return getOptimizedImageUrl(candidate, targetWidth: targetW);
  }

  ImageProvider? get _resolvedProvider {
    if (imageProvider != null) return imageProvider;
    final src = image;
    if (src != null && src is! NetworkImage) return src;
    return null;
  }

  int? get _calculatedMemWidth {
    if (memCacheWidth != null) return memCacheWidth;
    if (width != null && width! > 0 && width!.isFinite) {
      return (width! * 2).toInt().clamp(100, 1000);
    }
    return 500;
  }

  int? get _calculatedMemHeight {
    if (memCacheHeight != null) return memCacheHeight;
    if (height != null && height! > 0 && height!.isFinite) {
      return (height! * 2).toInt().clamp(100, 1000);
    }
    return null;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final networkUrl = _resolvedUrl;
    final provider = _resolvedProvider;

    final targetMemWidth = _calculatedMemWidth;
    final targetMemHeight = _calculatedMemHeight;

    Widget child;

    if (networkUrl != null) {
      // ── network ─────────────────────────────────────────────────────────
      child = CachedNetworkImage(
        imageUrl: networkUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: targetMemWidth,
        memCacheHeight: targetMemHeight,
        maxWidthDiskCache: targetMemWidth,
        maxHeightDiskCache: targetMemHeight,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) =>
            placeholder ??
            FadeShimmer(
              height: height ?? 120.h,
              width: width ?? 120.w,
              radius: borderRadius,
              highlightColor: const Color(0xffF9F9FB),
              baseColor: const Color(0xffE6E8EB),
            ),
        errorWidget: (_, __, ___) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: (width != null && width! < 50) ? 16.sp : 24.sp,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
      );
    } else if (provider != null) {
      // ── asset / memory / other ───────────────────────────────────────────
      child = Image(
        image: provider,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              FadeShimmer(
                height: height ?? 120.h,
                width: width ?? 120.w,
                radius: borderRadius,
                highlightColor: const Color(0xffF9F9FB),
                baseColor: const Color(0xffE6E8EB),
              );
        },
        errorBuilder: (_, __, ___) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: scheme.errorContainer,
              child: Icon(Icons.broken_image_outlined,
                  color: scheme.onErrorContainer),
            ),
      );
    } else {
      // ── fallback for no source ──────────────────────────────────────────
      child = errorWidget ??
          Container(
            width: width,
            height: height,
            color: scheme.surfaceContainerHighest,
            child: Icon(Icons.image_not_supported_outlined,
                color: scheme.onSurfaceVariant),
          );
    }

    // When no explicit dimensions are given, expand to fill the bounded parent.
    if (width == null && height == null) {
      child = SizedBox.expand(child: child);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}
