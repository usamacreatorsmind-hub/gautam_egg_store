import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/models/coupon_model.dart';
import 'package:sure_wholesaler/utils/app_notifications.dart';

import '../../core/constants/app_constants.dart';

class CouponCardWidget extends StatelessWidget {
  final CouponModel coupon;

  /// Called when the user taps Apply. Null hides the button.
  final VoidCallback? onApply;

  const CouponCardWidget({
    super.key,
    required this.coupon,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final config = _CouponConfig.from(coupon);
    final scheme = Theme.of(context).colorScheme;
    final isExpired = coupon.isExpired;

    return Opacity(
      opacity: isExpired ? 0.5 : 1.0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: config.accentColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Left accent strip + icon
              Container(
                width: 56.w,
                decoration: BoxDecoration(
                  color: config.accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14.r),
                    bottomLeft: Radius.circular(14.r),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(config.icon, color: Colors.white, size: 22.sp),
                    SizedBox(height: 6.h),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        config.typeLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Dashed separator
              _DashedDivider(color: scheme.outlineVariant),

              /// Main content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              config.title,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: config.accentColor,
                              ),
                            ),
                          ),
                          if (isExpired)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Expired',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      /// Description (switch on type)
                      Text(
                        config.description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      /// Code chip + copy
                      Row(
                        children: [
                          _CodeChip(
                            code: coupon.code,
                            accentColor: config.accentColor,
                          ),
                          const Spacer(),
                          if (onApply != null && !isExpired)
                            SizedBox(
                              height: 30.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: config.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: onApply,
                                child: Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      /// Footer info
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        children: [
                          if (coupon.minOrder > 0)
                            _InfoChip(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Min ${AppConfig.formatPrice(coupon.minOrder)}',
                              color: scheme.onSurfaceVariant,
                            ),
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Valid till ${_formatDate(coupon.expiryDate)}',
                            color: isExpired ? scheme.error : scheme.onSurfaceVariant,
                          ),
                          if (coupon.maxUsagePerUser > 1)
                            _InfoChip(
                              icon: Icons.person_outline,
                              label: 'Use ${coupon.maxUsagePerUser}x/user',
                              color: scheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Config resolved from CouponType
// ─────────────────────────────────────────────────────────────────────────────

class _CouponConfig {
  final String typeLabel;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const _CouponConfig({
    required this.typeLabel,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  factory _CouponConfig.from(CouponModel c) {
    switch (c.type) {
      case CouponType.percentage:
        final pct = c.value?.toStringAsFixed(0) ?? '?';
        final cap = c.maxDiscount != null ? ' (max ${AppConfig.formatPrice(c.maxDiscount!)})' : '';
        return _CouponConfig(
          typeLabel: 'PERCENT',
          title: '$pct% OFF',
          description: 'Get $pct% off on your order$cap. '
              '${_applyOnText(c)}',
          icon: Icons.percent_rounded,
          accentColor: AppColors.brandSeed,
        );

      case CouponType.flat:
        double flatVal = c.value ?? 0;
        if (flatVal > 0 && flatVal < 1000) {
          flatVal = flatVal * 100;
        }
        final amtString = AppConfig.formatPrice(flatVal);
        return _CouponConfig(
          typeLabel: 'FLAT',
          title: '$amtString OFF',
          description: 'Flat $amtString discount on your order. '
              '${_applyOnText(c)}',
          icon: Icons.currency_rupee_rounded,
          accentColor: AppColors.infoBright,
        );

      case CouponType.bogo:
        final buy = c.buyQty ?? '?';
        final get = c.getQty ?? '?';
        return _CouponConfig(
          typeLabel: 'BOGO',
          title: 'Buy $buy Get $get Free',
          description: 'Buy $buy items and get $get free. '
              '${_applyOnText(c)}',
          icon: Icons.card_giftcard_rounded,
          accentColor: AppColors.accentPurple,
        );

      case CouponType.subscription:
        final pct = c.value?.toStringAsFixed(0) ?? '?';
        return _CouponConfig(
          typeLabel: 'SUBS',
          title: '$pct% OFF on Subscribe',
          description: 'Save $pct% when you subscribe & auto-deliver. '
              '${_applyOnText(c)}',
          icon: Icons.repeat_rounded,
          accentColor: AppColors.warningDark,
        );
    }
  }

  static String _applyOnText(CouponModel c) {
    switch (c.applyOn) {
      case ApplyOn.allProducts:
        return 'Valid on all products.';
      case ApplyOn.category:
        return 'Valid on selected category.';
      case ApplyOn.products:
        return 'Valid on selected products.';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CodeChip extends StatelessWidget {
  final String code;
  final Color accentColor;

  const _CodeChip({required this.code, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        AppNotifications.showSuccess(
          context,
          title: 'Success',
          message: 'Code "$code" copied!',
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.copy_rounded, size: 12.sp, color: accentColor),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10.sp, color: color),
        SizedBox(width: 3.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12.w,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
