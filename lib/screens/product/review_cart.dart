import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/screens/product/product_review_model.dart';

class ReviewCard extends StatelessWidget {
  final ProductReviewModel review;

  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ⭐ Rating + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStars(review.rating),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  review.title,
                  style: theme.textTheme.titleSmall?.copyWith(
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
            style: theme.textTheme.bodyMedium,
          ),

          SizedBox(height: 10.h),

          /// 👤 Footer
          Row(
            children: [
              Icon(Icons.verified_user, size: 14.sp, color: AppColors.success),
              SizedBox(width: 4.w),
              Text(
                "Verified Buyer",
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⭐ Stars
  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating.round() ? Icons.star : Icons.star_border,
          size: 16.sp,
          color: AppColors.starColor,
        );
      }),
    );
  }

  /// 📅 Time ago
  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}
