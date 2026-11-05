// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:sure_wholesaler/core/routing/app_routes.dart';
// import 'package:sure_wholesaler/features/business_kyc/models/business_kyc_model.dart';
// import 'package:sure_wholesaler/features/business_kyc/providers/business_kyc_providers.dart';
// import 'package:sure_wholesaler/models/UserModel.dart';
//
// import '../../../notifiers/user_notifier.dart';
//
// class KycStatusScreen extends ConsumerWidget {
//   final UserModel? user;
//
//   const KycStatusScreen({super.key, this.user});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final effectiveUser = user ?? ref.watch(userProvider).value;
//
//     if (effectiveUser == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       return const Scaffold(
//         body: Center(child: Text('Not logged in')),
//       );
//     }
//
//     final kycAsync = ref.watch(businessKycByUserIdProvider(uid));
//
//     return kycAsync.when(
//       loading: () => const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       ),
//       error: (error, _) => Scaffold(
//         appBar: AppBar(title: const Text('KYC Status')),
//         body: Center(child: Text('Error: $error')),
//       ),
//       data: (kyc) {
//         return Scaffold(
//           body: kyc == null ? _buildNoKycBody(context) : KycStatusScreenContent(kyc: kyc, user: effectiveUser),
//         );
//       },
//     );
//   }
//
//   Widget _buildNoKycBody(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.info_outline, size: 72, color: Colors.blue),
//           const SizedBox(height: 24),
//           const Text(
//             'No KYC record found yet.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           const Text(
//             'Start the business KYC process to get your account verified. Status updates will appear here automatically once submitted.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 15, height: 1.5),
//           ),
//           const SizedBox(height: 30),
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               onPressed: () => context.push(AppRoutes.kycStepper),
//               child: const Text('Start KYC'),
//             ),
//           ),
//           SizedBox(
//             height: 20.h,
//           ),
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.grey,
//               ),
//               onPressed: () => context.pop(),
//               child: const Text('Back'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class KycStatusScreenContent extends ConsumerWidget {
//   final BusinessKycModel kyc;
//   final UserModel? user;
//
//   const KycStatusScreenContent({super.key, required this.kyc, this.user});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Watch for live changes to this specific KYC record
//     final liveKycAsync = ref.watch(businessKycByUserIdProvider(kyc.userId));
//
//     return liveKycAsync.when(
//       data: (liveKyc) {
//         final currentKyc = liveKyc ?? kyc;
//
//         return Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     _buildHeader(context, currentKyc),
//                     Padding(
//                       padding: EdgeInsets.all(16.r),
//                       child: Column(
//                         children: [
//                           _buildStatusCard(context, currentKyc),
//                           SizedBox(height: 16.h),
//                           _buildTimeline(context, currentKyc),
//                           SizedBox(height: 16.h),
//                           _buildInfoSection(context, currentKyc),
//                           SizedBox(height: 16.h),
//                           _buildDocumentsSection(currentKyc),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             _buildActionButton(context, currentKyc),
//           ],
//         );
//       },
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (_, __) => const Center(child: Text("Error syncing status")),
//     );
//   }
//
//   Widget _buildHeader(BuildContext context, BusinessKycModel currentKyc) {
//     final scheme = Theme.of(context).colorScheme;
//     final status = currentKyc.verification.kycStatus;
//     final isApproved = status == KycStatus.approved;
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 32.h),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [scheme.primary, scheme.primaryContainer],
//         ),
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
//       ),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 70.r,
//             backgroundColor: Colors.white24,
//             backgroundImage: user?.userImg.isNotEmpty == true ? NetworkImage(user!.userImg) : null,
//             child: user?.userImg.isEmpty != false ? Icon(Icons.business, size: 40.r, color: Colors.white) : null,
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             currentKyc.identity.businessName,
//             style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           Text(
//             currentKyc.identity.ownerName,
//             style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.9)),
//           ),
//           SizedBox(height: 16.h),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20.r),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
// // business type
//
//                 Icon(
//                   isApproved ? Icons.verified : Icons.pending_actions,
//                   size: 18.sp,
//                   color: isApproved ? Colors.green : Colors.orange,
//                 ),
//                 SizedBox(width: 8.w),
//                 Text(
//                   status.toUpperCase(),
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12.sp,
//                     color: isApproved ? Colors.green : Colors.orange,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusCard(BuildContext context, BusinessKycModel currentKyc) {
//     final status = currentKyc.verification.kycStatus;
//     final isRejected = status == KycStatus.rejected;
//
//     return Card(
//       elevation: 0,
//       color: isRejected ? Colors.red.shade50 : Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
//       child: Padding(
//         padding: EdgeInsets.all(20.r),
//         child: Column(
//           children: [
//             Icon(
//               status == KycStatus.approved
//                   ? Icons.check_circle_rounded
//                   : isRejected
//                       ? Icons.error_rounded
//                       : Icons.info_rounded,
//               size: 48.r,
//               color: status == KycStatus.approved
//                   ? Colors.green
//                   : isRejected
//                       ? Colors.red
//                       : Colors.blue,
//             ),
//             SizedBox(height: 12.h),
//             Text(
//               _statusMessage(status),
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, height: 1.5),
//             ),
//             if (isRejected && currentKyc.verification.rejectionReason != null) ...[
//               SizedBox(height: 8.h),
//               Text(
//                 "Reason: ${currentKyc.verification.rejectionReason}",
//                 style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp, fontWeight: FontWeight.bold),
//               ),
//             ]
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimeline(BuildContext context, BusinessKycModel currentKyc) {
//     final status = currentKyc.verification.kycStatus;
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r), side: BorderSide(color: Colors.grey.shade200)),
//       child: Padding(
//         padding: EdgeInsets.all(20.r),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Verification Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
//             SizedBox(height: 16.h),
//             _timelineItem("Submitted", true, currentKyc.verification.submittedAt),
//             _timelineItem("Under Review", status != KycStatus.draft, currentKyc.updatedAt),
//             _timelineItem(
//               status == KycStatus.approved ? "Approved" : (status == KycStatus.rejected ? "Rejected" : "Verification Complete"),
//               status == KycStatus.approved || status == KycStatus.rejected,
//               status == KycStatus.approved || status == KycStatus.rejected ? currentKyc.updatedAt : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _timelineItem(String title, bool isDone, Timestamp? ts) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 8.h),
//       child: Row(
//         children: [
//           Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey, size: 20.sp),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: TextStyle(fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
//                 if (ts != null)
//                   Text(DateFormat.yMMMd().add_jm().format(ts.toDate()), style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoSection(BuildContext context, BusinessKycModel currentKyc) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r), side: BorderSide(color: Colors.grey.shade200)),
//       child: Padding(
//         padding: EdgeInsets.all(20.r),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Business Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
//             const Divider(height: 24),
//             _detailRow("GST No.", currentKyc.legalDocuments.gstNumber),
//             _detailRow("PAN No.", currentKyc.legalDocuments.panNumber),
//             _detailRow("Address", currentKyc.address.fullAddress ?? "${currentKyc.address.addressLine1}, ${currentKyc.address.city}"),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _documentCard({
//     required BuildContext context,
//     required String title,
//     String? imageUrl,
//     required VoidCallback onTap,
//   }) {
//     final scheme = Theme.of(context).colorScheme;
//     final uploaded = imageUrl != null && imageUrl.isNotEmpty;
//
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 160.w, // Increased width for better visibility
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16.r),
//           color: Colors.white,
//           border: Border.all(
//             color: uploaded ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3),
//             width: 1.5,
//           ),
//           boxShadow: [
//             BoxShadow(
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//               color: Colors.black.withOpacity(0.05),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.vertical(
//                   top: Radius.circular(16.r),
//                 ),
//                 child: uploaded
//                     ? Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           Image.network(
//                             imageUrl,
//                             fit: BoxFit.cover,
//                             loadingBuilder: (context, child, progress) {
//                               if (progress == null) return child;
//                               return const Center(child: CircularProgressIndicator(strokeWidth: 2));
//                             },
//                             errorBuilder: (context, _, __) => Container(
//                               color: Colors.grey.shade100,
//                               child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
//                             ),
//                           ),
//                           Positioned(
//                             top: 8,
//                             right: 8,
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
//                               child: const Icon(Icons.zoom_in_rounded, size: 16, color: Colors.blue),
//                             ),
//                           ),
//                         ],
//                       )
//                     : Container(
//                         color: Colors.grey.shade50,
//                         child: Center(
//                           child: Icon(
//                             Icons.image_not_supported_outlined,
//                             size: 32.sp,
//                             color: Colors.grey.shade400,
//                           ),
//                         ),
//                       ),
//               ),
//             ),
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
//               decoration: BoxDecoration(
//                 color: uploaded ? Colors.blue.withOpacity(0.03) : Colors.red.withOpacity(0.03),
//                 borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight: FontWeight.bold,
//                         color: scheme.onSurface,
//                       ),
//                     ),
//                   ),
//                   Icon(
//                     uploaded ? Icons.check_circle : Icons.error_outline,
//                     size: 16.sp,
//                     color: uploaded ? Colors.blue : Colors.red,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDocumentsSection(BusinessKycModel currentKyc) {
//     final docs = [
//       {'title': 'GST Certificate', 'url': currentKyc.images.gstCertificateUrl},
//       {'title': 'PAN Card', 'url': currentKyc.images.panCardUrl},
//       {'title': 'Shop Photo', 'url': currentKyc.images.shopPhotoUrl},
//       {'title': 'Owner Photo', 'url': currentKyc.images.ownerPhotoUrl},
//     ].where((doc) => doc['url'] != null && doc['url']!.isNotEmpty).toList();
//
//     if (docs.isEmpty) return const SizedBox.shrink();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'Submitted Documents',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Spacer(),
//             Text(
//               'Tap to verify',
//               style: TextStyle(fontSize: 11.sp, color: Colors.blue, fontWeight: FontWeight.w500),
//             ),
//           ],
//         ),
//         SizedBox(height: 12.h),
//         SizedBox(
//           height: 180.h, // Increased height for better thumbnails
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: docs.length,
//             padding: EdgeInsets.symmetric(vertical: 4.h),
//             separatorBuilder: (_, __) => SizedBox(width: 14.w),
//             itemBuilder: (context, index) {
//               final doc = docs[index];
//               final url = doc['url'];
//
//               return _documentCard(
//                 context: context,
//                 title: doc['title']!,
//                 imageUrl: url,
//                 onTap: () {
//                   if (url != null && url.isNotEmpty) {
//                     _showFullscreenViewer(context, url, doc['title']!);
//                   }
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _showFullscreenViewer(BuildContext context, String url, String title) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         final controller = TransformationController();
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: EdgeInsets.zero,
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(color: Colors.black),
//               ),
//               Column(
//                 children: [
//                   AppBar(
//                     backgroundColor: Colors.transparent,
//                     elevation: 0,
//                     title: Text(title, style: const TextStyle(color: Colors.white)),
//                     leading: IconButton(
//                       icon: const Icon(Icons.close, color: Colors.white),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ),
//                   Expanded(
//                     child: InteractiveViewer(
//                       transformationController: controller,
//                       panEnabled: true,
//                       minScale: 0.5,
//                       maxScale: 4.0,
//                       child: Image.network(
//                         url,
//                         fit: BoxFit.contain,
//                         loadingBuilder: (_, child, progress) {
//                           if (progress == null) return child;
//                           return const Center(child: CircularProgressIndicator());
//                         },
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.symmetric(vertical: 20.h),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _zoomButton(
//                           icon: Icons.remove,
//                           onTap: () {
//                             final current = controller.value.getMaxScaleOnAxis();
//                             final next = (current - 0.5).clamp(0.5, 4.0);
//                             controller.value = Matrix4.diagonal3Values(next, next, 1.0);
//                           },
//                         ),
//                         SizedBox(width: 24.w),
//                         _zoomButton(
//                           icon: Icons.add,
//                           onTap: () {
//                             final current = controller.value.getMaxScaleOnAxis();
//                             final next = (current + 0.5).clamp(0.5, 4.0);
//                             controller.value = Matrix4.diagonal3Values(next, next, 1.0);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(8.w),
//         decoration: BoxDecoration(
//           color: Colors.black54,
//           shape: BoxShape.circle,
//         ),
//         child: Icon(icon, color: Colors.white, size: 24.sp),
//       ),
//     );
//   }
//
//   Widget _buildActionButton(BuildContext context, BusinessKycModel currentKyc) {
//     final status = currentKyc.verification.kycStatus;
//     return Padding(
//       padding: EdgeInsets.all(16.r),
//       child: SizedBox(
//         width: double.infinity,
//         height: 50.h,
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r))),
//           onPressed: () {
//             if (status == KycStatus.rejected) {
//               context.go(AppRoutes.kycStepper);
//             } else {
//               context.go(AppRoutes.home);
//             }
//           },
//           child: Text(status == KycStatus.rejected ? 'Resubmit KYC' : 'Back to Profile'),
//         ),
//       ),
//     );
//   }
//
//   Widget _detailRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 6.h),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
//           SizedBox(height: 2.h),
//           Text(value.isEmpty ? '—' : value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
//         ],
//       ),
//     );
//   }
//
//   String _statusMessage(String status) {
//     switch (status) {
//       case KycStatus.approved:
//         return 'Congratulations! Your business has been verified. You can now access all features.';
//       case KycStatus.rejected:
//         return 'Unfortunately, your KYC submission was rejected. Please review the details below.';
//       default:
//         return 'Your KYC is currently under review. This typically takes 1-3 business days.';
//     }
//   }
// }
