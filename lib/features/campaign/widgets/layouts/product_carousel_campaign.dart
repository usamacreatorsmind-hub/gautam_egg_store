import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

class ProductCarouselCampaign extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const ProductCarouselCampaign({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              campaign.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: style.titleColor,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          CarouselSlider.builder(
            itemCount: campaign.productsIds.length,
            itemBuilder: (context, index, realIndex) =>
                buildProductItem(campaign.productsIds[index], width: 100),
            options: CarouselOptions(
              height: 150.h,
              viewportFraction: 0.35,
              enlargeCenterPage: false,
              autoPlay: true,
              padEnds: false,
              enableInfiniteScroll: campaign.productsIds.length > 3,
            ),
          ),
        ],
      ),
    );
  }
}
