import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/campaign_model.dart';

final campaignRepositoryProvider = Provider<FirestoreRepository<CampaignModel>>(
  (ref) => FirestoreRepository<CampaignModel>(
    collectionPath: AppCollections.productCampaign,
    fromFirestore: (doc) => CampaignModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
  ),
);

/// Real provider fetching from Firestore (Streaming for real-time updates)
final fetchCampaignProvider = StreamProvider<List<CampaignModel>>((ref) async* {
  final repository = ref.read(campaignRepositoryProvider);

  try {
    await for (final allCampaigns in repository.streamAll(
      orderBy: 'priority',
      descending: false,
    )) {
      if (allCampaigns.isEmpty) {
        yield _getMockCampaigns();
      } else {
        yield allCampaigns;
      }
    }
  } catch (e) {
    // If there's an error (like permission denied or missing index), fallback to mocks
    yield _getMockCampaigns();
  }
});

/// Comprehensive mock data covering all Layouts for development/testing
List<CampaignModel> _getMockCampaigns() {
  return [
    // 1. Hero Layout
    CampaignModel(
      id: "hero_summer",
      priority: 1,
      layout: CampaignLayout.hero,
      type: CampaignType.seasonal,
      targetId: "summer",
      title: "Summer Collection 2025",
      subtitle: "Breezy styles for the heat",
      style: _defaultStyle(
        gradient: [const Color(0xffFF8F00), const Color(0xffFFC107)],
        backgroundImage: "https://picsum.photos/seed/summer/800/400",
        buttonColor: Colors.black,
      ),
      productsIds: ["prod_chair", "prod_headphone", "prod_facewash"],
      action: const ActionConfig(
        type: ActionType.collection,
        id: "summer",
      ),
    ),

    // 2. Coupon Layout
    CampaignModel(
      id: "coupon_first",
      priority: 2,
      layout: CampaignLayout.coupon,
      type: CampaignType.offer,
      targetId: "welcome",
      title: "Get 50% OFF",
      subtitle: "On your first order! Use code WELCOME50",
      style: _defaultStyle(
        gradient: [Colors.purple, Colors.deepPurple],
        buttonColor: Colors.amber,
      ),
      productsIds: [],
      action: const ActionConfig(
        type: ActionType.offer,
        id: "welcome",
      ),
    ),

    // 3. Grid Layout - Fixed to show real data
    CampaignModel(
      id: "grid_electronics",
      priority: 3,
      type: CampaignType.category,
      targetId: "3BRYvntGLk7TxfQZFUB1",
      layout: CampaignLayout.grid,
      title: "Top Electronics",
      subtitle: "Best gadgets for you",
      style: _defaultStyle(
        gradient: [Colors.white, Colors.white],
        titleColor: Colors.black,
        subtitleColor: Colors.grey,
        buttonColor: Colors.blue,
        productCardColor: Colors.white,
      ),
      productsIds: [], // Triggers dynamic fetch in GridCampaignCard
      action: const ActionConfig(
        type: ActionType.category,
        id: "3BRYvntGLk7TxfQZFUB1",
      ),
    ),

    // 4. Split Layout
    CampaignModel(
      id: "split_brand",
      priority: 4,
      type: CampaignType.brand,
      targetId: "nike",
      layout: CampaignLayout.split,
      title: "Nike Originals",
      subtitle: "Unmatched performance",
      style: _defaultStyle(
        gradient: [Colors.black, Colors.black],
        backgroundImage: "https://picsum.photos/seed/nike/800/400",
        buttonColor: Colors.orange,
        productCardColor: Colors.grey.shade50,
      ),
      productsIds: [],
      action: const ActionConfig(
        type: ActionType.brand,
        id: "nike",
      ),
    ),
  ]..sort((a, b) => a.priority.compareTo(b.priority));
}

/// Helper to create a consistent style for mocks
CampaignStyle _defaultStyle({
  required List<Color> gradient,
  Color buttonColor = Colors.white,
  String backgroundImage = "",
  Color titleColor = Colors.white,
  Color subtitleColor = Colors.white70,
  Color productCardColor = Colors.white,
}) {
  return CampaignStyle(
    gradient: gradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    titleColor: titleColor,
    subtitleColor: subtitleColor,
    quoteColor: titleColor.withValues(alpha: 0.9),
    buttonColor: buttonColor,
    productCardColor: productCardColor,
    backgroundImage: backgroundImage,
    borderRadius: 16.0,
    padding: const EdgeInsets.all(16.0),
  );
}
