import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/cart_model.dart';
import '../../../../models/delivery_model.dart';
import '../../../../notifiers/cart_notifier.dart';
import '../../../../notifiers/product_notifier.dart';
import '../../../../widgets/Product_Card_Widget.dart';
import '../../../../widgets/app_shimmer.dart';
import '../../models/campaign_model.dart';

mixin CampaignLayoutMixin {
  void handleAction(BuildContext context, CampaignModel campaign) {
    final action = campaign.action;
    switch (action.type) {
      case ActionType.category:
        context.push(
          AppRoutes.categoryItemsPath(action.id),
          extra: {'categoryName': campaign.title},
        );
        break;
      case ActionType.subCategory:
        context.push(
          AppRoutes.categoryItemsPath('all'),
          extra: {
            'categoryName': campaign.title,
            'subcategoryId': action.id,
          },
        );
        break;
      case ActionType.brand:
        context.push(
          AppRoutes.categoryItemsPath('all'),
          extra: {
            'brandId': action.id,
            'brandName': campaign.title,
            'categoryName': campaign.title,
          },
        );
        break;
      case ActionType.product:
        context.push(AppRoutes.productDetailsPath(action.id));
        break;
      case ActionType.productList:
        context.push(
          AppRoutes.categoryItemsPath('all'),
          extra: {
            'categoryName': campaign.title,
            'productListId': action.id,
          },
        );
        break;
      case ActionType.collection:
        context.push(
          AppRoutes.categoryItemsPath('all'),
          extra: {'categoryName': campaign.title},
        );
        break;
      case ActionType.search:
        context.push(
          AppRoutes.search,
          extra: {'query': action.id},
        );
        break;
      case ActionType.offer:
        context.push(AppRoutes.offers);
        break;
      case ActionType.externalLink:
        if (action.id.isNotEmpty) {
          launchUrl(Uri.parse(action.id), mode: LaunchMode.externalApplication);
        }
        break;
      case ActionType.customPage:
        if (action.id.isNotEmpty) {
          context.push(action.id);
        }
        break;
    }
  }

  String getActionText(CampaignModel campaign) {
    switch (campaign.action.type) {
      case ActionType.category:
      case ActionType.subCategory:
      case ActionType.brand:
      case ActionType.collection:
        return "View All Items";
      case ActionType.product:
        return "Buy Now";
      case ActionType.search:
        return "Search More";
      case ActionType.offer:
        return "View All Offers";
      case ActionType.externalLink:
        return "Learn More";
      default:
        return "View More";
    }
  }

  Widget buildSectionHeader(BuildContext context, CampaignModel campaign) {
    final style = campaign.style;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      campaign.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: style.titleColor,
                      ),
                    ),
                    if (campaign.type == CampaignType.seasonal) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (campaign.subtitle != null)
                  Text(
                    campaign.subtitle!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: style.subtitleColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => handleAction(context, campaign),
            child: Row(
              children: [
                Text(
                  "See all",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: campaign.style.buttonColor,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16.sp,
                  color: campaign.style.buttonColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductItem(String productId, {double? width}) {
    return Consumer(
      builder: (context, ref, child) {
        final productAsync = ref.watch(productByIdStreamProvider(productId));
        return productAsync.when(
          data: (product) {
            if (product == null) return const SizedBox.shrink();
            final itemWidth = width?.w ?? ProductCardWidget.gridWidth;
            final itemHeight = width != null ? (width.w + 50.h) : ProductCardWidget.gridHeight;

            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: ProductCardWidget(
                  product: product,
                  layout: ProductCardLayout.grid,
                  onAddToCart: () {
                    final activeVariants = product.activePackVariants;
                    if (activeVariants.isEmpty) return;
                    final variant = activeVariants.first;
                    final deliveryType =
                        variant.availableDeliveryTypes.isNotEmpty ? variant.availableDeliveryTypes.first : DeliveryType.quick;
                    final warehouseId = variant.inventory?.warehouseId ??
                        ref.read(cartProvider).value?.warehouseId ??
                        ref.read(resolvedWarehouseProvider).firstOrNull ??
                        'default';
                    ref
                        .read(cartProvider.notifier)
                        .addToCart(CartItem.fromVariant(variant: variant, deliveryType: deliveryType, warehouseId: warehouseId));

                    AppNotifications.showPremiumNotification(
                      context,
                      title: 'Success',
                      message: '${product.name} added to cart',
                      buttonLabel: 'VIEW',
                      onButtonPressed: () => context.push('/cart'),
                    );
                  },
                ),
              ),
            );
          },
          loading: () => buildShimmerLoading(width: width ?? 160),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget buildShimmerLoading({double width = 160}) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: AppShimmer.productSkeleton(
        width: width.w,
        height: ProductCardWidget.gridHeight,
      ),
    );
  }
}
