import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

class ImageCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const ImageCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return GestureDetector(
      onTap: () => handleAction(context, campaign),
      child: Container(
        margin: EdgeInsets.all(12.w),
        width: double.infinity,
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          image: DecorationImage(
            image: NetworkImage(style.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
