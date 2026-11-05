import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return FadeShimmer(
      width: width,
      height: height,
      radius: radius,
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
    );
  }

  static Widget circular({required double size}) {
    return FadeShimmer.round(
      size: size,
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
    );
  }

  static Widget productSkeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeShimmer(
            width: width,
            height: height * 0.55,
            radius: 16.r,
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeShimmer(
                  height: 10.h,
                  width: width * 0.8,
                  radius: 4.r,
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                ),
                SizedBox(height: 6.h),
                FadeShimmer(
                  height: 10.h,
                  width: width * 0.5,
                  radius: 4.r,
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                ),
                SizedBox(height: 12.h),
                FadeShimmer(
                  height: 14.h,
                  width: width * 0.4,
                  radius: 4.r,
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
