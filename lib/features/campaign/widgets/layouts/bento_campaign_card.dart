import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

class BentoCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const BentoCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: style.productCardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: style.titleColor,
              letterSpacing: -0.5,
            ),
          ),
          if (campaign.subtitle != null)
            Text(
              campaign.subtitle!,
              style: TextStyle(
                fontSize: 12.sp,
                color: style.subtitleColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: 16.h),
          AspectRatio(
            aspectRatio: 0.78,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: campaign.productsIds.isNotEmpty
                      ? buildProductItem(campaign.productsIds[0],
                              width: double.infinity)
                      : _buildPlaceholder(),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: campaign.productsIds.length > 1
                            ? buildProductItem(campaign.productsIds[1],
                                    width: double.infinity)
                            : _buildPlaceholder(),
                      ),
                      SizedBox(height: 10.h),
                      Expanded(
                        child: campaign.productsIds.length > 2
                            ? buildProductItem(campaign.productsIds[2],
                                    width: double.infinity)
                            : _buildPlaceholder(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade300),
      ),
    );
  }
}
