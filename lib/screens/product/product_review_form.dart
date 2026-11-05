import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/notifiers/product_review_notifier.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class ProductReviewForm extends ConsumerStatefulWidget {
  final String productId;
  final String orderId;
  final String orderItemId;

  const ProductReviewForm({
    super.key,
    required this.productId,
    required this.orderId,
    required this.orderItemId,
  });

  @override
  ConsumerState<ProductReviewForm> createState() => _ProductReviewFormState();
}

class _ProductReviewFormState extends ConsumerState<ProductReviewForm> {
  final _formKey = GlobalKey<FormState>();

  double _rating = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Write a Review",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          /// ⭐ Rating
          Text("Rating"),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: AppColors.starColor,
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          /// 📝 Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Enter title";
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          /// 💬 Comment
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Comment",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Enter comment";
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          /// 🚀 Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const AppLoader()
                  : const Text("Submit Review"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rating == 0) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Please select rating',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      /// 🔥 Call your provider / repo here
      await ref.read(submitReviewProvider).call(
            productId: widget.productId,
            orderId: widget.orderId,
            orderItemId: widget.orderItemId,
            rating: _rating,
            title: _titleController.text.trim(),
            comment: _commentController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context); // close form
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: 'Review submitted',
        );
      }
    } catch (e) {
      AppNotifications.showError(
        context,
        title: 'Error',
        message: 'Error: $e',
      );
    }

    setState(() => _isSubmitting = false);
  }
}
