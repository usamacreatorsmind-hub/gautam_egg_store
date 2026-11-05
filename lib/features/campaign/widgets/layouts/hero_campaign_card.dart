import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

import '../../../../widgets/Product_Card_Widget.dart';

class HeroCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const HeroCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.borderRadius.r),
            gradient: LinearGradient(
              colors: style.gradient,
              begin: style.begin,
              end: style.end,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (style.backgroundImage.isNotEmpty)
                Stack(
                  children: [
                    Image.network(
                      style.backgroundImage,
                      height: 180.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 180.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16.h,
                      left: 16.w,
                      right: 16.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (campaign.subtitle != null)
                            Text(
                              campaign.subtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                buildSectionHeader(context, campaign),
              if (campaign.productsIds.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: SizedBox(
                    height: ProductCardWidget.gridHeight,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: campaign.productsIds.length,
                      itemBuilder: (context, index) =>
                          buildProductItem(campaign.productsIds[index]),
                    ),
                  ),
                ),
              _buildActionFooter(context, style),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionFooter(BuildContext context, CampaignStyle style) {
    return InkWell(
      onTap: () => handleAction(context, campaign),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getActionText(campaign),
              style: TextStyle(
                color: style.titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 14.sp,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_rounded,
                color: style.titleColor, size: 18.sp),
          ],
        ),
      ),
    );
  }
}
