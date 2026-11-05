import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionDecorator extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final List<Color>? gradient;
  final String? backgroundImage;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;
  final Color? borderColor;

  const SectionDecorator({
    super.key,
    required this.child,
    this.backgroundColor,
    this.gradient,
    this.backgroundImage,
    this.borderRadius,
    this.padding,
    this.margin,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: padding ?? EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? (gradient == null ? Colors.white : null),
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: backgroundImage != null
            ? DecorationImage(
                image: NetworkImage(backgroundImage!),
                fit: BoxFit.cover,
                opacity: 0.1,
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.black.withOpacity(0.05),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
