import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/app_debug.dart';
import 'package:sure_wholesaler/notifiers/product_review_notifier.dart';
import 'package:sure_wholesaler/screens/product/product_review_model.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class ProductReviewWidget extends ConsumerStatefulWidget {
  final String productId;
  final bool onlyMyReview;

  const ProductReviewWidget({
    super.key,
    required this.productId,
    this.onlyMyReview = true,
  });

  @override
  ConsumerState<ProductReviewWidget> createState() => _ProductReviewWidgetState();
}

class _ProductReviewWidgetState extends ConsumerState<ProductReviewWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productReviews = ref.watch(
      widget.onlyMyReview ? myProductReviewsProvider(widget.productId) : productReviewsProvider(widget.productId),
    );

    return productReviews.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Stars
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < review.rating.round() ? Icons.star : Icons.star_border,
                                size: 16.sp,
                                color: AppColors.starColor,
                              );
                            }),
                          ),
                          SizedBox(width: 8.w),

                          /// Title
                          Expanded(
                            child: Text(
                              review.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 6.h),

                      /// 💬 Comment
                      Text(
                        review.comment,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      SizedBox(height: 8.h),

                      /// 👤 Footer (user + date placeholder)
                      Row(
                        children: [
                          Icon(Icons.person, size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            "Verified Buyer",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            review.createdAt != null ? "${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}" : "",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) {
        AppDebug.log(e);
        return const SizedBox.shrink();
      },
    );
  }

  /// 🔹 Empty UI
  Widget _emptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          widget.onlyMyReview ? 'You haven\'t reviewed this product yet.' : 'No reviews yet. Be the first to review this product!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
