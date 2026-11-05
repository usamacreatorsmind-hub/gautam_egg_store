import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

class CouponCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const CouponCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Container(
      margin: EdgeInsets.all(12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: style.buttonColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: style.buttonColor, width: 1, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campaign.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.sp)),
                Text(campaign.subtitle ?? "Limited time offer",
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => handleAction(context, campaign),
            style: ElevatedButton.styleFrom(backgroundColor: style.buttonColor),
            child: const Text("CLAIM", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
