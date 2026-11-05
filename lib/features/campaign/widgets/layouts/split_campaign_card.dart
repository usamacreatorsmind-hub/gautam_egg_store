import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

import '../../../../widgets/Product_Card_Widget.dart';

class SplitCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const SplitCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Container(
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: style.productCardColor,
        borderRadius: BorderRadius.circular(style.borderRadius.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [

          if (campaign.productsIds.isNotEmpty)
            SizedBox(
              height: ProductCardWidget.gridHeight + 16.h,
              child: ListView.builder(
                padding: EdgeInsets.all(8.w),
                scrollDirection: Axis.horizontal,
                itemCount: campaign.productsIds.length,
                itemBuilder: (context, index) =>
                    buildProductItem(campaign.productsIds[index]),
              ),
            ),
        ],
      ),
    );
  }
}
