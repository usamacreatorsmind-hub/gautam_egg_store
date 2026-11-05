import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

enum DiscountType {
  percentage,
  amount,
  under, flat,
}

class SaleCardModel {
  final String title;
  final DiscountType discountType;
  final String value;

  final List<Color> colors;

  const SaleCardModel({
    required this.title,
    required this.discountType,
    required this.value,
    required this.colors,
  });
}

class SaleCard extends StatelessWidget {
  final SaleCardModel card;

  const SaleCard({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final isPercentage = card.discountType == DiscountType.percentage;
    final isAmount = card.discountType == DiscountType.amount;

    return InkWell(
      onTap: () {
        final Map<String, dynamic> extra = {
          'categoryName': '${card.title} ${card.value}${isPercentage ? '%' : ''}',
        };

        if (card.discountType == DiscountType.percentage) {
          extra['minDiscount'] = int.tryParse(card.value);
          extra['sortBy'] = 'Discount: High to Low';
        } else if (card.discountType == DiscountType.under) {
          final maxPrice = double.tryParse(card.value);
          if (maxPrice != null) {
            extra['priceRange'] = RangeValues(0, maxPrice);
          }
          extra['sortBy'] = 'Price: Low to High';
        }

        context.push(
          AppRoutes.categoryItemsPath('all'),
          extra: extra,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 150.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: card.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.title,
              style: const TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10.h),
            Transform.rotate(
              angle: -0.08, // radians (~ -4.5°)
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: Colors.white.withOpacity(.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isPercentage ? "${card.value}%" : "₹${card.value}",
                      style: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isPercentage
                          ? "OFF"
                          : isAmount
                              ? "OFF"
                              : "ONLY",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
