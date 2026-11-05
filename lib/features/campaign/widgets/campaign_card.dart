import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/bento_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/countdown_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/coupon_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/grid_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/hero_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/image_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/product_carousel_campaign.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/split_campaign_card.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/story_campaign_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CampaignCard extends ConsumerWidget {
  final CampaignModel campaign;

  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (campaign.layout) {
      case CampaignLayout.hero:
        return HeroCampaignCard(campaign: campaign);

      case CampaignLayout.split:
        return SplitCampaignCard(campaign: campaign);

      case CampaignLayout.carousel:
        return ProductCarouselCampaign(campaign: campaign);

      case CampaignLayout.grid:
        return GridCampaignCard(campaign: campaign);

      case CampaignLayout.bento:
        return BentoCampaignCard(campaign: campaign);

      case CampaignLayout.story:
        return StoryCampaignCard(campaign: campaign);

      case CampaignLayout.image:
        return CouponCampaignCard(campaign: campaign);

      case CampaignLayout.countdown:
        return CountdownCampaignCard(campaign: campaign);


      default:
        return HeroCampaignCard(campaign: campaign);
    }
  }
}
