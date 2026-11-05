/// Dynamic variant attributes driven by category.variantAttributes.
/// Keys and values are both strings — e.g. {"color": "Red", "size": "M"}.
/// Replaces the old hardcoded-field approach.
class PackVariantAttributes {
  final Map<String, String> _data;

  const PackVariantAttributes(this._data);

  PackVariantAttributes.empty() : _data = {};

  /// Convenience accessors for common attribute keys
  String? get color => _data['color'];
  String? get size => _data['size'];
  String? get storage => _data['storage'];
  String? get packSize => _data['packSize'];
  String? get weight => _data['weight'];
  String? get flavor => _data['flavor'];
  String? get material => _data['material'];

  /// Generic getter — use when key is dynamic
  String? operator [](String key) => _data[key];

  /// All attribute entries
  Map<String, String> get all => Map.unmodifiable(_data);

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  factory PackVariantAttributes.fromMap(Map<String, dynamic> map) {
    return PackVariantAttributes(
      Map<String, String>.from(
        map.map((k, v) => MapEntry(k.toString(), v.toString())),
      ),
    );
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_data);

  PackVariantAttributes copyWith(Map<String, String> overrides) {
    return PackVariantAttributes({..._data, ...overrides});
  }

  @override
  String toString() => 'PackVariantAttributes($_data)';
}
