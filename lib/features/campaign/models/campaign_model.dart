import 'package:flutter/material.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

enum CampaignLayout {
  hero,
  split,
  carousel,
  grid,
  bento,
  story,
  coupon,
  countdown,
  image,
}

enum CampaignType {
  category,
  subCategory,
  brand,
  seasonal,
  collection,
  offer,
  custom,
}

class CampaignStyle {
  final List<Color> gradient;
  final List<double>? stops;
  final Alignment begin;
  final Alignment end;
  final Color titleColor;
  final Color subtitleColor;
  final Color quoteColor;
  final Color buttonColor;
  final Color productCardColor;
  final String backgroundImage;
  final double borderRadius;
  final EdgeInsets padding;

  CampaignStyle({
    required this.gradient,
    this.stops,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    required this.titleColor,
    required this.subtitleColor,
    required this.quoteColor,
    required this.buttonColor,
    required this.productCardColor,
    required this.backgroundImage,
    required this.borderRadius,
    required this.padding,
  });

  factory CampaignStyle.fromMap(Map<String, dynamic> map) {
    return CampaignStyle(
      gradient: (map['gradient'] as List<dynamic>?)
              ?.map((c) => Color(c as int))
              .toList() ??
          [],
      stops: (map['stops'] as List<dynamic>?)
          ?.map((s) => (s as num).toDouble())
          .toList(),
      begin: _parseAlignment(map['beginX'], map['beginY'], Alignment.topLeft),
      end: _parseAlignment(map['endX'], map['endY'], Alignment.bottomRight),
      titleColor: Color(map['titleColor'] as int? ?? 0xFF000000),
      subtitleColor: Color(map['subtitleColor'] as int? ?? 0xFF000000),
      quoteColor: Color(map['quoteColor'] as int? ?? 0xFF000000),
      buttonColor: Color(map['buttonColor'] as int? ?? 0xFF000000),
      productCardColor: Color(map['productCardColor'] as int? ?? 0xFFFFFFFF),
      backgroundImage: map['backgroundImage'] as String? ?? '',
      borderRadius: (map['borderRadius'] as num? ?? 0).toDouble(),
      padding: EdgeInsets.only(
        left: (map['paddingLeft'] as num? ?? 0).toDouble(),
        top: (map['paddingTop'] as num? ?? 0).toDouble(),
        right: (map['paddingRight'] as num? ?? 0).toDouble(),
        bottom: (map['paddingBottom'] as num? ?? 0).toDouble(),
      ),
    );
  }

  static Alignment _parseAlignment(dynamic x, dynamic y, Alignment fallback) {
    if (x == null || y == null) return fallback;
    return Alignment((x as num).toDouble(), (y as num).toDouble());
  }

  Map<String, dynamic> toMap() {
    return {
      'gradient': gradient.map((c) => c.toARGB32()).toList(),
      'stops': stops,
      'beginX': begin.x,
      'beginY': begin.y,
      'endX': end.x,
      'endY': end.y,
      'titleColor': titleColor.toARGB32(),
      'subtitleColor': subtitleColor.toARGB32(),
      'quoteColor': quoteColor.toARGB32(),
      'buttonColor': buttonColor.toARGB32(),
      'productCardColor': productCardColor.toARGB32(),
      'backgroundImage': backgroundImage,
      'borderRadius': borderRadius,
      'paddingLeft': padding.left,
      'paddingTop': padding.top,
      'paddingRight': padding.right,
      'paddingBottom': padding.bottom,
    };
  }
}

class CampaignModel implements FirestoreModel {
  @override
  String id;
  final int priority;
  final CampaignType type;
  final String targetId;
  final String title;
  final String? subtitle;
  final CampaignLayout layout;
  final String? quote;
  final CampaignStyle style;
  final List<String> productsIds;
  final ActionConfig action;

  CampaignModel({
    required this.id,
    required this.priority,
    required this.layout,
    required this.type,
    required this.targetId,
    required this.title,
    this.subtitle,
    this.quote,
    required this.style,
    required this.productsIds,
    required this.action,
  });

  factory CampaignModel.fromMap(Map<String, dynamic> map, String id) {
    return CampaignModel(
      id: id,
      priority: map['priority'] as int? ?? 0,
      type: CampaignType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CampaignType.custom,
      ),
      targetId: map['targetId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String?,
      layout: CampaignLayout.values.firstWhere(
        (e) => e.name == map['layout'],
        orElse: () => CampaignLayout.hero,
      ),
      quote: map['quote'] as String?,
      style: CampaignStyle.fromMap(map['style'] as Map<String, dynamic>? ?? {}),
      productsIds: List<String>.from(map['productsIds'] ?? []),
      action:
          ActionConfig.fromMap(map['action'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'priority': priority,
      'type': type.name,
      'targetId': targetId,
      'title': title,
      'subtitle': subtitle,
      'layout': layout.name,
      'quote': quote,
      'style': style.toMap(),
      'productsIds': productsIds,
      'action': action.toMap(),
    };
  }

  @override
  String toString() {
    return 'CampaignModel{id: $id, priority: $priority, type: $type, targetId: $targetId, title: $title, subtitle: $subtitle, layout: $layout, quote: $quote, style: $style, productsIds: $productsIds, action: $action}';
  }
}

enum ActionType {
  category,
  subCategory,
  brand,
  product,
  productList,
  collection,
  search,
  offer,
  externalLink,
  customPage,
}

class ActionConfig {
  final ActionType type;

  /// Main identifier
  final String id;

  /// Optional parameters
  final Map<String, dynamic>? params;

  const ActionConfig({
    required this.type,
    required this.id,
    this.params,
  });

  factory ActionConfig.fromMap(Map<String, dynamic> map) {
    return ActionConfig(
      type: ActionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActionType.productList,
      ),
      id: map['id'] as String? ?? '',
      params: map['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'id': id,
      'params': params,
    };
  }
}
