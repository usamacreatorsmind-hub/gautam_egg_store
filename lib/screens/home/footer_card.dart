import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/core/constants/asset_constants.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class DesktopFooterCard extends StatelessWidget {
  const DesktopFooterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1200,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      AssetConstants.appLogoCleanBg,
                      width: 60,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppConfig.appName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  "Your trusted wholesale shopping partner.",
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConfig.legalCompanyName,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Contact",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(AppConfig.supportPhone),
                const SizedBox(height: 8),
                Text(AppConfig.supportEmail),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Links",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text("Privacy Policy"),
                Text("Terms & Conditions"),
                Text("Help Center"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileFooterCard extends StatelessWidget {
  const MobileFooterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandSeed.withOpacity(0.15),
            AppColors.brandSeed.withOpacity(0.05),
            Colors.white,
          ],
        ),
        border: Border.all(
          color: AppColors.brandSeed.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Image.asset(
                  AssetConstants.appLogoCleanBg,
                  width: 100.w,
                ),
                SizedBox(width: 12.h),
                Column(
                  children: [
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Your trusted shopping partner",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Divider(),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone),
            title: Text(AppConfig.supportPhone),
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email),
            title: Text(AppConfig.supportEmail),
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Support"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              context.push(AppRoutes.helpSupport);
            },
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              context.push(AppRoutes.privacyPolicy);
            },
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              context.push(AppRoutes.termsAndConditions);
            },
          ),
          Divider(),
          Text(
            "Version 1.0.0",
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "© 2026 ${AppConfig.appName}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
