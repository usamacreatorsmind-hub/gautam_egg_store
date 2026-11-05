import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/features/campaign/models/campaign_model.dart';
import 'package:sure_wholesaler/features/campaign/widgets/layouts/campaign_layout_mixin.dart';

import '../../../../notifiers/product_notifier.dart';
import '../../../../widgets/Product_Card_Widget.dart';

class GridCampaignCard extends StatelessWidget with CampaignLayoutMixin {
  final CampaignModel campaign;

  const GridCampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final style = campaign.style;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.productCardColor,
        borderRadius: BorderRadius.circular(style.borderRadius.r),
        border: Border.all(color: style.buttonColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: TextStyle(
                        color: style.titleColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (campaign.subtitle != null)
                      Text(
                        campaign.subtitle!,
                        style: TextStyle(
                            color: style.subtitleColor, fontSize: 13.sp),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => handleAction(context, campaign),
                child: Text("See All",
                    style: TextStyle(
                        color: style.buttonColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (campaign.productsIds.isEmpty)
            _CategoryProductsGrid(categoryId: campaign.action.id)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio:
                    ProductCardWidget.gridWidth / ProductCardWidget.gridHeight,
              ),
              itemCount: campaign.productsIds.length.clamp(0, 8),
              itemBuilder: (context, index) =>
                  buildProductItem(campaign.productsIds[index]),
            ),
        ],
      ),
    );
  }
}

class _CategoryProductsGrid extends ConsumerWidget with CampaignLayoutMixin {
  final String categoryId;
  const _CategoryProductsGrid({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryStreamProvider(categoryId));
    
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        final displayItems = products.take(4).toList();
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio:
                ProductCardWidget.gridWidth / ProductCardWidget.gridHeight,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ProductCardWidget(
              product: displayItems[index],
              layout: ProductCardLayout.grid,
              onAddToCart: () {
                // Same add to cart logic as buildProductItem
              },
            ),
          ),
        );
      },
      loading: () => GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemCount: 4,
        itemBuilder: (_, __) => buildShimmerLoading(width: 80),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
