// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';

/// 🔹 Helper: Safe Timestamp parser
DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

class SpecificationField {
  final String key;
  final String label;
  final String type;
  final List<String>? options;
  final bool required;

  const SpecificationField({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    required this.required,
  });

  factory SpecificationField.fromJson(Map<String, dynamic> json) {
    return SpecificationField(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      options:
          json['options'] != null ? List<String>.from(json['options']) : null,
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      if (options != null) 'options': options,
      'required': required,
    };
  }
}

class CategorySpecification {
  final List<SpecificationField> specificationFields;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategorySpecification({
    required this.specificationFields,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategorySpecification.fromJson(Map<String, dynamic> json) {
    return CategorySpecification(
      specificationFields: (json['specificationFields'] as List<dynamic>)
          .map((e) => SpecificationField.fromJson(e))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specificationFields':
          specificationFields.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CategoryModel {
  final String docId;
  final String id;
  final bool isStoryItem;
  final String name;
  final String? description;

  /// 🔑 parentId decides sub-category
  /// null  → main category
  /// value → sub-category
  final String? parentId;
  final String? parentName;
  final List<String>? variantAttributes;

  final List<SpecificationField> specificationFields;

  final String status;
  final String? imageUrl;
  final int? sortOrder;
  final int? productCount;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// UI-only (NEVER store in Firestore)
  final List<CategoryModel>? children;

  /// UI helper
  final int level;

  CategoryModel({
    required this.docId,
    this.isStoryItem = false,
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.parentName,
    this.variantAttributes,
    this.specificationFields = const [],
    this.isActive = true,
    required this.status,
    this.imageUrl,
    this.sortOrder,
    this.productCount,
    this.createdAt,
    this.updatedAt,
    this.children,
    this.level = 0,
  });

  /* -------------------------------------------------------------------------- */
  /*                               FACTORY METHODS                              */
  /* -------------------------------------------------------------------------- */

  /// 🔹 Firestore Document → Model
  factory CategoryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CategoryModel.fromMap(data, doc.id);
  }

  /// 🔹 Map → Model
  factory CategoryModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final parentId = (data['parentCategoryId'] ?? data['parentId'])?.toString();

    return CategoryModel(
      docId: docId ?? data['id']?.toString() ?? '',
      isStoryItem: data['showInStory'] ?? data['isStoryItem'] ?? false,
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      description: data['description']?.toString(),
      parentId: parentId,
      parentName: data['parentName']?.toString(),
      variantAttributes: data['variantAttributes'] != null
          ? List<String>.from(data['variantAttributes'])
          : null,
      specificationFields: data['specificationFields'] != null
          ? (data['specificationFields'] as List)
              .map(
                  (e) => SpecificationField.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      isActive: data['isActive'] ?? data['showInStore'] ?? true,
      status: data['status'] ?? EntityStatus.active,
      imageUrl: data['imageUrl']?.toString(),
      sortOrder: (data['sortOrder'] as num?)?.toInt(),
      productCount: (data['productCount'] as num?)?.toInt(),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      children: data['children'] != null
          ? (data['children'] as List).map((child) {
              final childMap = child as Map<String, dynamic>;
              return CategoryModel.fromMap(childMap, childMap['id']);
            }).toList()
          : null,
      level: data['level'] ?? (parentId == null ? 0 : 1),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              FIRESTORE SERIALIZE                            */
  /* -------------------------------------------------------------------------- */

  /// 🔹 Model → Firestore Map
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      "showInStory": isStoryItem,
      'status': status,
      if (description != null) 'description': description,
      if (parentId != null) 'parentCategoryId': parentId,
      if (variantAttributes != null) 'variantAttributes': variantAttributes,
      if (specificationFields != null)
        'specificationFields': specificationFields,
      'isActive': isActive,
      'showInStore': isActive,
      if (parentName != null) 'parentName': parentName,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (productCount != null) 'productCount': productCount,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    /// Create vs Update
    if (docId.isEmpty) {
      map['createdAt'] = DateTime.now().toIso8601String();
    }

    return map;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   COPY WITH                                 */
  /* -------------------------------------------------------------------------- */

  CategoryModel copyWith({
    String? docId,
    String? id,
    String? name,
    String? description,
    String? parentId,
    bool? isStoryItem,
    String? parentName,
    List<String>? variantAttributes,
    List<SpecificationField>? specificationFields,
    bool? isActive,
    String? status,
    String? imageUrl,
    int? sortOrder,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CategoryModel>? children,
    int? level,
  }) {
    return CategoryModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      status: status ?? this.status,
      isStoryItem: isStoryItem ?? this.isStoryItem,
      variantAttributes: variantAttributes ?? this.variantAttributes,
      specificationFields: specificationFields ?? this.specificationFields,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      children: children ?? this.children,
      level: level ?? this.level,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                 UI HELPERS                                  */
  /* -------------------------------------------------------------------------- */

  bool get hasParent => parentId != null && parentId!.isNotEmpty;

  bool? get hasChildren => children?.isNotEmpty;

  bool get isMainCategory => parentId == null;

  bool get isSubCategory => parentId != null;

  String get indentation => '  ' * level;

  String get displayName => '$indentation$name';

  @override
  String toString() {
    return 'CategoryModel(docId: $docId, id: $id, isStoryItem: $isStoryItem, name: $name, description: $description, parentId: $parentId, parentName: $parentName, status: $status, imageUrl: $imageUrl,   variantAttributes: $variantAttributes, specificationFields: $specificationFields, isActive: $isActive,  sortOrder: $sortOrder, productCount: $productCount, createdAt: $createdAt, updatedAt: $updatedAt, children: $children, level: $level)';
  }
}

/* -------------------------------------------------------------------------- */
/*                            CATEGORY FORM MODEL                              */
/* -------------------------------------------------------------------------- */

class CategoryFormData {
  final String name;
  final String description;
  final String? parentId;
  final String status;
  final String? imageUrl;

  CategoryFormData({
    required this.name,
    required this.description,
    this.parentId,
    required this.status,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'parentId': parentId,
      'status': status,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'CategoryFormData(name: $name, description: $description, parentId: $parentId, status: $status, imageUrl: $imageUrl)';
  }
}
