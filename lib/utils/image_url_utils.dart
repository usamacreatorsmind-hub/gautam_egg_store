String? sanitizeImageUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final hasHttpScheme = uri.hasScheme && ['http', 'https'].contains(uri.scheme.toLowerCase());
  final hasHost = uri.host.trim().isNotEmpty;

  if (!hasHttpScheme || !hasHost) return null;

  return uri.toString();
}

List<String> validImageUrls(Iterable<String>? values) {
  if (values == null) return const [];

  return values.map(sanitizeImageUrl).whereType<String>().toList(growable: false);
}

/// Transforms unoptimized image URLs (e.g. Unsplash, Cloudinary, etc.)
/// into lightweight, resized, webp-formatted URLs to drastically speed up downloading.
String? getOptimizedImageUrl(
  String? url, {
  int? targetWidth,
  int quality = 80,
}) {
  final sanitized = sanitizeImageUrl(url);
  if (sanitized == null) return null;

  final uri = Uri.tryParse(sanitized);
  if (uri == null) return sanitized;

  final host = uri.host.toLowerCase();
  final width = targetWidth ?? 400;

  // 1. Unsplash URL optimization
  if (host.contains('unsplash.com')) {
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['w'] = width.toString();
    queryParams['q'] = quality.toString();
    queryParams['auto'] = 'format';
    queryParams['fit'] = 'crop';

    return uri.replace(queryParameters: queryParams).toString();
  }

  // 2. Cloudinary URL optimization
  if (host.contains('cloudinary.com')) {
    final path = uri.path;
    if (path.contains('/upload/') && !path.contains('/upload/f_auto')) {
      final newPath = path.replaceFirst(
        '/upload/',
        '/upload/f_auto,q_auto,w_$width/',
      );
      return uri.replace(path: newPath).toString();
    }
  }

  return sanitized;
}
