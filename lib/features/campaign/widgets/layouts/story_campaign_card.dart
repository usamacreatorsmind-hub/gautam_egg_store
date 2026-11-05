import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

class StoryCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const StoryCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      height: 120.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(campaign.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: style.titleColor)),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              scrollDirection: Axis.horizontal,
              itemCount: campaign.productsIds.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: style.buttonColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30.r,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: NetworkImage(
                              "https://picsum.photos/200?random=$index"),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text("Story ${index + 1}",
                          style: TextStyle(fontSize: 10.sp)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
