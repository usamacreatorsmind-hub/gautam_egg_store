// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:path/path.dart' as p;
// import 'package:sure_wholesaler/core/routing/app_routes.dart';
// import 'package:sure_wholesaler/core/services/app_file_uploader.dart';
// import 'package:sure_wholesaler/features/business_kyc/models/business_kyc_model.dart';
// import 'package:sure_wholesaler/features/business_kyc/providers/business_kyc_providers.dart';
// import 'package:sure_wholesaler/features/business_kyc/screens/kyc_status_screen.dart';
// import 'package:sure_wholesaler/features/business_kyc/widgets/kyc_text_field.dart';
// import 'package:sure_wholesaler/utils/location_base_classes/location_service.dart';
// import 'package:sure_wholesaler/widgets/app_loader.dart';
// import 'package:sure_wholesaler/widgets/select_address_on_map.dart';
//
// import '../../../notifiers/user_notifier.dart';
//
// class BusinessKycStepperScreen extends ConsumerStatefulWidget {
//   const BusinessKycStepperScreen({super.key});
//
//   @override
//   ConsumerState<BusinessKycStepperScreen> createState() => _BusinessKycStepperScreenState();
// }
//
// class UpperCaseTextFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     return TextEditingValue(
//       text: newValue.text.toUpperCase(),
//       selection: newValue.selection,
//       composing: TextRange.empty,
//     );
//   }
// }
//
// class _BusinessKycStepperScreenState extends ConsumerState<BusinessKycStepperScreen> {
//   bool _isFetchingLocation = false;
//   int _currentStep = 0;
//   bool _isLoading = false;
//   bool _initialized = false;
//   String? _existingKycId;
//   BusinessKycModel? _existingKyc;
//   bool _showGstRequiredWarning = false;
//   bool _showPanRequiredWarning = false;
//   bool _showShopRequiredWarning = false;
//   bool _showOwnerRequiredWarning = false;
//
//   // Location state for display in step 3
//   double? _latitude;
//   double? _longitude;
//   bool _isFromCurrentLocation = false;
//
//   // Step 1 – Business Info
//   final _step1Key = GlobalKey<FormState>();
//   final _businessNameCtrl = TextEditingController();
//   final _ownerNameCtrl = TextEditingController();
//   String _businessType = BusinessType.soleProprietor;
//
//   // Step 2 – Legal Documents
//   final _step2Key = GlobalKey<FormState>();
//   final _gstCtrl = TextEditingController();
//   final _panCtrl = TextEditingController();
//   File? _gstCertFile;
//   File? _panCardFile;
//
//   // Step 3 – Business Address
//   final _step3Key = GlobalKey<FormState>();
//   final _addr1Ctrl = TextEditingController();
//   final _addr2Ctrl = TextEditingController();
//   final _cityCtrl = TextEditingController();
//   final _stateCtrl = TextEditingController();
//   final _pincodeCtrl = TextEditingController();
//   String? _fullAddress;
//   double? _addressLat;
//   double? _addressLng;
//
//   // Step 4 – Contact Details + Photos
//   final _step4Key = GlobalKey<FormState>();
//   final _phoneCtrl = TextEditingController();
//   final _whatsappCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   File? _shopPhotoFile;
//   File? _ownerPhotoFile;
//
//   @override
//   void dispose() {
//     _businessNameCtrl.dispose();
//     _ownerNameCtrl.dispose();
//     _gstCtrl.dispose();
//     _panCtrl.dispose();
//     _addr1Ctrl.dispose();
//     _addr2Ctrl.dispose();
//     _cityCtrl.dispose();
//     _stateCtrl.dispose();
//     _pincodeCtrl.dispose();
//     _phoneCtrl.dispose();
//     _whatsappCtrl.dispose();
//     _emailCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchCurrentLocation() async {
//     if (_isFetchingLocation) return;
//     setState(() => _isFetchingLocation = true);
//
//     try {
//       final locationData = await LocationService.getCurrentLocation();
//       final placemark = await LocationService.getFullAddress(
//         locationData.latitude!,
//         locationData.longitude!,
//       );
//
//       setState(() {
//         _latitude = locationData.latitude;
//         _longitude = locationData.longitude;
//         _isFromCurrentLocation = true;
//         _addressLat = locationData.latitude;
//         _addressLng = locationData.longitude;
//         _fullAddress = [
//           placemark.street ?? '',
//           placemark.locality ?? '',
//           placemark.administrativeArea ?? '',
//           placemark.postalCode ?? '',
//         ].where((s) => s.isNotEmpty).join(', ');
//
//         if (_addr1Ctrl.text.trim().isEmpty) {
//           _addr1Ctrl.text = placemark.street ?? placemark.name ?? '';
//         }
//         if (_cityCtrl.text.trim().isEmpty) {
//           _cityCtrl.text = placemark.locality ?? placemark.subAdministrativeArea ?? '';
//         }
//         if (_stateCtrl.text.trim().isEmpty) {
//           _stateCtrl.text = placemark.administrativeArea ?? '';
//         }
//         if (_pincodeCtrl.text.trim().isEmpty) {
//           _pincodeCtrl.text = placemark.postalCode ?? '';
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to get location: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isFetchingLocation = false);
//     }
//   }
//
//   void _prefillFromExisting(BusinessKycModel kyc) {
//     if (_initialized) return;
//     _initialized = true;
//     _existingKycId = kyc.id;
//     _existingKyc = kyc;
//     _businessNameCtrl.text = kyc.identity.businessName;
//     _ownerNameCtrl.text = kyc.identity.ownerName;
//     _businessType = kyc.identity.businessType.isEmpty ? BusinessType.soleProprietor : kyc.identity.businessType;
//     _gstCtrl.text = kyc.legalDocuments.gstNumber;
//     _panCtrl.text = kyc.legalDocuments.panNumber;
//     _addr1Ctrl.text = kyc.address.addressLine1;
//     _addr2Ctrl.text = kyc.address.addressLine2;
//     _cityCtrl.text = kyc.address.city;
//     _stateCtrl.text = kyc.address.state;
//     _pincodeCtrl.text = kyc.address.pincode;
//     _fullAddress = kyc.address.fullAddress;
//     _addressLat = kyc.address.latitude;
//     _addressLng = kyc.address.longitude;
//     if (_addressLat != null && _addressLng != null) {
//       _latitude = _addressLat;
//       _longitude = _addressLng;
//       _isFromCurrentLocation = false;
//     }
//     _phoneCtrl.text = kyc.contact.businessPhone;
//     _whatsappCtrl.text = kyc.contact.whatsappNumber;
//     _emailCtrl.text = kyc.contact.email ?? '';
//   }
//
//   bool _hasExistingOrSelected(File? file, String? existingUrl) {
//     return file != null || (existingUrl?.isNotEmpty == true);
//   }
//
//   void _clearDocumentWarnings() {
//     _showGstRequiredWarning = false;
//     _showPanRequiredWarning = false;
//     _showShopRequiredWarning = false;
//     _showOwnerRequiredWarning = false;
//   }
//
//   bool _validateCurrentStep() {
//     _clearDocumentWarnings();
//     bool isValid = true;
//
//     switch (_currentStep) {
//       case 0:
//         isValid = _step1Key.currentState?.validate() ?? false;
//         break;
//       case 1:
//         if (!(_step2Key.currentState?.validate() ?? false)) {
//           isValid = false;
//         }
//         // GST is now optional, so we only require PAN
//         if (!_hasExistingOrSelected(_panCardFile, _existingKyc?.images.panCardUrl)) {
//           _showPanRequiredWarning = true;
//           isValid = false;
//         }
//         if (!isValid) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please upload required documents.')),
//           );
//         }
//         break;
//       case 2:
//         isValid = _step3Key.currentState?.validate() ?? false;
//         break;
//       case 3:
//         if (!(_step4Key.currentState?.validate() ?? false)) {
//           isValid = false;
//         }
//         if (!_hasExistingOrSelected(_shopPhotoFile, _existingKyc?.images.shopPhotoUrl)) {
//           _showShopRequiredWarning = true;
//           isValid = false;
//         }
//         if (!_hasExistingOrSelected(_ownerPhotoFile, _existingKyc?.images.ownerPhotoUrl)) {
//           _showOwnerRequiredWarning = true;
//           isValid = false;
//         }
//         if (!isValid) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please upload all required photos.')),
//           );
//         }
//         break;
//       default:
//         isValid = true;
//     }
//
//     if (!isValid) {
//       setState(() {});
//     }
//     return isValid;
//   }
//
//   Future<void> _onStepContinue() async {
//     if (_currentStep < 4) {
//       if (!_validateCurrentStep()) return;
//       setState(() => _currentStep++);
//     } else {
//       if (!_validateCurrentStep()) return;
//       await _submitKyc();
//     }
//   }
//
//   void _onStepCancel() {
//     if (_currentStep > 0) {
//       setState(() => _currentStep--);
//     } else {
//       context.pop();
//     }
//   }
//
//   Future<void> _pickGstCert() async {
//     final file = await AppFileUploader.pickDocument();
//     if (file != null) setState(() => _gstCertFile = file);
//   }
//
//   Future<void> _pickPanCard() async {
//     final file = await AppFileUploader.pickDocument();
//     if (file != null) setState(() => _panCardFile = file);
//   }
//
//   Future<void> _pickShopPhoto() async {
//     final file = await AppFileUploader.pickImageFromGallery();
//     if (file != null) setState(() => _shopPhotoFile = file);
//   }
//
//   Future<void> _pickOwnerPhoto() async {
//     final file = await AppFileUploader.pickImageFromGallery();
//     if (file != null) setState(() => _ownerPhotoFile = file);
//   }
//
//   Future<String?> _uploadFile(File file, String fileName, String uid) async {
//     final ext = p.extension(file.path).replaceAll('.', '');
//     final result = await AppFileUploader.uploadFile(
//       file: file,
//       storagePath: AppFileUploader.generateBusinessKycPath(
//         userId: uid,
//         fileName: '$fileName.$ext',
//       ),
//     );
//
//     if (!result.success) {
//       throw Exception('Failed to upload $fileName: ${result.error ?? 'Unknown error'}');
//     }
//
//     return result.downloadUrl;
//   }
//
//   Future<void> _submitKyc() async {
//     setState(() => _isLoading = true);
//     try {
//       final uid = FirebaseAuth.instance.currentUser!.uid;
//       final now = Timestamp.now();
//
//       final gstUrl = _gstCertFile != null ? await _uploadFile(_gstCertFile!, 'gst_cert', uid) : _existingKyc?.images.gstCertificateUrl;
//       final panUrl = _panCardFile != null ? await _uploadFile(_panCardFile!, 'pan_card', uid) : _existingKyc?.images.panCardUrl;
//       final shopUrl = _shopPhotoFile != null ? await _uploadFile(_shopPhotoFile!, 'shop_photo', uid) : _existingKyc?.images.shopPhotoUrl;
//       final ownerUrl =
//           _ownerPhotoFile != null ? await _uploadFile(_ownerPhotoFile!, 'owner_photo', uid) : _existingKyc?.images.ownerPhotoUrl;
//
//       final identity = BusinessIdentity(
//         businessName: _businessNameCtrl.text.trim(),
//         ownerName: _ownerNameCtrl.text.trim(),
//         businessType: _businessType,
//       );
//       final legal = LegalDocuments(
//         gstNumber: _gstCtrl.text.trim().toUpperCase(),
//         panNumber: _panCtrl.text.trim().toUpperCase(),
//       );
//       final address = BusinessAddress(
//         addressLine1: _addr1Ctrl.text.trim(),
//         addressLine2: _addr2Ctrl.text.trim(),
//         city: _cityCtrl.text.trim(),
//         state: _stateCtrl.text.trim(),
//         pincode: _pincodeCtrl.text.trim(),
//         fullAddress: _fullAddress,
//         latitude: _addressLat,
//         longitude: _addressLng,
//       );
//       final contact = BusinessContact(
//         businessPhone: _phoneCtrl.text.trim(),
//         whatsappNumber: _whatsappCtrl.text.trim(),
//         email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
//       );
//       const settings = BusinessSettings(
//         isActive: true,
//         isBlocked: false,
//         acceptsOnlinePayments: false,
//         creditLimit: 0.0,
//       );
//       final images = BusinessImages(
//         gstCertificateUrl: gstUrl,
//         panCardUrl: panUrl,
//         shopPhotoUrl: shopUrl,
//         ownerPhotoUrl: ownerUrl,
//       );
//       final verification = KycVerification(
//         kycStatus: KycStatus.pending,
//         submittedAt: now,
//       );
//
//       final controller = ref.read(businessKycControllerProvider);
//
//       final createdAt = _existingKyc?.createdAt ?? now;
//       final updatedAt = now;
//
//       if (_existingKycId != null && _existingKycId!.isNotEmpty) {
//         final kyc = BusinessKycModel(
//           id: _existingKycId!,
//           userId: uid,
//           identity: identity,
//           legalDocuments: legal,
//           address: address,
//           contact: contact,
//           verification: verification,
//           images: images,
//           settings: settings,
//           createdAt: createdAt,
//           updatedAt: updatedAt,
//         );
//         await controller.setKyc(kyc);
//       } else {
//         final kyc = BusinessKycModel(
//           id: uid,
//           userId: uid,
//           identity: identity,
//           legalDocuments: legal,
//           address: address,
//           contact: contact,
//           verification: verification,
//           images: images,
//           settings: settings,
//           createdAt: createdAt,
//           updatedAt: updatedAt,
//         );
//         await controller.createKyc(kyc);
//       }
//
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Submission failed: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please login to continue')),
//       );
//     }
//
//     final kycAsync = ref.watch(businessKycByUserIdProvider(uid));
//
//     return kycAsync.when(
//       loading: () => const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       ),
//       error: (e, _) => Scaffold(
//         appBar: AppBar(title: const Text('Business KYC')),
//         body: Center(child: Text('Error: $e')),
//       ),
//       data: (kyc) {
//         if (kyc != null && kyc.verification.kycStatus != KycStatus.rejected && kyc.verification.kycStatus != KycStatus.draft) {
//           return Scaffold(
//             appBar: AppBar(title: const Text('KYC Status'), centerTitle: true),
//             body: KycStatusScreenContent(
//               kyc: kyc,
//               user: null,
//             ),
//           );
//         }
//         if (kyc != null) {
//           _existingKyc = kyc;
//           _prefillFromExisting(kyc);
//         }
//         return _buildStepperScaffold(context, kyc);
//       },
//     );
//   }
//
//   Widget _buildStepperScaffold(BuildContext context, BusinessKycModel? existing) {
//     final isRejected = existing?.verification.kycStatus == KycStatus.rejected;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Business KYC'),
//         centerTitle: true,
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               if (isRejected)
//                 Container(
//                   width: double.infinity,
//                   color: Colors.red.shade50,
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.info_outline, color: Colors.red, size: 18),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           existing!.verification.rejectionReason?.isNotEmpty == true
//                               ? 'Rejected: ${existing.verification.rejectionReason}'
//                               : 'Your previous KYC was rejected. Please resubmit.',
//                           style: TextStyle(color: Colors.red.shade700, fontSize: 13),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               Expanded(
//                 child: Stepper(
//                   currentStep: _currentStep,
//                   onStepContinue: _isLoading ? null : _onStepContinue,
//                   onStepCancel: _isLoading ? null : _onStepCancel,
//                   onStepTapped: (step) {
//                     if (step < _currentStep) {
//                       setState(() => _currentStep = step);
//                     }
//                   },
//                   controlsBuilder: (context, details) {
//                     final isLast = _currentStep == 4;
//                     final buttonLabel = isLast ? 'Submit KYC' : 'Continue';
//                     final loadingLabel = isLast ? 'Submitting...' : 'Saving...';
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 16),
//                       child: Row(
//                         children: [
//                           ElevatedButton(
//                             onPressed: _isLoading ? null : details.onStepContinue,
//                             child: _isLoading
//                                 ? Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       const SizedBox(
//                                         width: 16,
//                                         height: 16,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Text(loadingLabel),
//                                     ],
//                                   )
//                                 : Text(buttonLabel),
//                           ),
//                           const SizedBox(width: 12),
//                           if (_currentStep > 0)
//                             TextButton(
//                               onPressed: _isLoading ? null : details.onStepCancel,
//                               child: const Text('Back'),
//                             ),
//                         ],
//                       ),
//                     );
//                   },
//                   steps: [
//                     Step(
//                       title: const Text('Business Info'),
//                       isActive: _currentStep >= 0,
//                       state: _currentStep > 0 ? StepState.complete : StepState.indexed,
//                       content: _buildStep1(),
//                     ),
//                     Step(
//                       title: const Text('Legal Documents'),
//                       isActive: _currentStep >= 1,
//                       state: _currentStep > 1 ? StepState.complete : StepState.indexed,
//                       content: _buildStep2(),
//                     ),
//                     Step(
//                       title: const Text('Business Address'),
//                       isActive: _currentStep >= 2,
//                       state: _currentStep > 2 ? StepState.complete : StepState.indexed,
//                       content: _buildStep3(),
//                     ),
//                     Step(
//                       title: const Text('Contact Details'),
//                       isActive: _currentStep >= 3,
//                       state: _currentStep > 3 ? StepState.complete : StepState.indexed,
//                       content: _buildStep4(),
//                     ),
//                     Step(
//                       title: const Text('Review & Submit'),
//                       isActive: _currentStep >= 4,
//                       state: StepState.indexed,
//                       content: _buildStep5Review(),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.black26,
//               child: const Center(
//                 child: Card(
//                   child: Padding(
//                     padding: EdgeInsets.all(24),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 16),
//                         Text('Submitting KYC...'),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // ─── Step 1: Business Info ───────────────────────────────────────────────
//
//   Widget _buildStep1() {
//     return Form(
//       key: _step1Key,
//       child: Column(
//         children: [
//           KycTextField(
//             label: 'Business Name',
//             controller: _businessNameCtrl,
//             validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'Owner Name',
//             controller: _ownerNameCtrl,
//             validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//           ),
//           const SizedBox(height: 16),
//           DropdownButtonFormField<String>(
//             value: _businessType,
//             decoration: const InputDecoration(
//               labelText: 'Business Type',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.all(Radius.circular(12)),
//               ),
//             ),
//             items: const [
//               DropdownMenuItem(
//                 value: BusinessType.soleProprietor,
//                 child: Text('Sole Proprietor'),
//               ),
//               DropdownMenuItem(
//                 value: BusinessType.partnership,
//                 child: Text('Partnership'),
//               ),
//               DropdownMenuItem(
//                 value: BusinessType.llp,
//                 child: Text('LLP'),
//               ),
//               DropdownMenuItem(
//                 value: BusinessType.privateLimited,
//                 child: Text('Private Limited'),
//               ),
//             ],
//             onChanged: (v) => setState(() => _businessType = v ?? BusinessType.soleProprietor),
//             validator: (v) => v == null ? 'Required' : null,
//           ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
//
//   // ─── Step 2: Legal Documents ─────────────────────────────────────────────
//
//   Widget _buildStep2() {
//     return Form(
//       key: _step2Key,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           KycTextField(
//             label: 'GST Number (Optional)',
//             controller: _gstCtrl,
//             textCapitalization: TextCapitalization.characters,
//             maxLength: 15,
//             inputFormatters: [
//               FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
//               LengthLimitingTextInputFormatter(15),
//               UpperCaseTextFormatter(),
//             ],
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) return null; // Optional
//               final input = v.trim().toUpperCase();
//               if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(input)) {
//                 return 'Enter a valid 15-character GST number';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'PAN Number',
//             controller: _panCtrl,
//             textCapitalization: TextCapitalization.characters,
//             maxLength: 10,
//             inputFormatters: [
//               FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
//               LengthLimitingTextInputFormatter(10),
//               UpperCaseTextFormatter(),
//             ],
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) return 'PAN number is required';
//               final input = v.trim().toUpperCase();
//               if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(input)) {
//                 return 'Enter a valid 10-character PAN number';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 8),
//           const Text('Upload Documents', style: TextStyle(fontWeight: FontWeight.w600)),
//           const SizedBox(height: 10),
//           _buildImageCard(
//             title: 'GST Certificate',
//             file: _gstCertFile,
//             onPick: _pickGstCert,
//           ),
//           if (_showGstRequiredWarning)
//             const Padding(
//               padding: EdgeInsets.only(top: 4, left: 12),
//               child: Text(
//                 'GST document is required to proceed.',
//                 style: TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 10),
//           _buildImageCard(
//             title: 'PAN Card',
//             file: _panCardFile,
//             onPick: _pickPanCard,
//           ),
//           if (_showPanRequiredWarning)
//             const Padding(
//               padding: EdgeInsets.only(top: 4, left: 12),
//               child: Text(
//                 'PAN document is required to proceed.',
//                 style: TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
//
//   // ─── Step 3: Business Address ────────────────────────────────────────────
//
//   Future<void> _openMapPicker() async {
//     final result = await Navigator.push<Map<String, dynamic>>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SelectAddressOnMapScreen(
//           initialLatitude: _addressLat,
//           initialLongitude: _addressLng,
//         ),
//       ),
//     );
//     if (result == null || !mounted) return;
//     setState(() {
//       _addressLat = result['latitude'] as double?;
//       _addressLng = result['longitude'] as double?;
//       _fullAddress = result['address'] as String?;
//       _latitude = _addressLat;
//       _longitude = _addressLng;
//       _isFromCurrentLocation = false;
//       if (_fullAddress != null && _addr1Ctrl.text.trim().isEmpty) {
//         _addr1Ctrl.text = _fullAddress!;
//       }
//     });
//   }
//
//   Widget _buildStep3() {
//     final hasPinned = _addressLat != null && _addressLng != null;
//
//     final theme = Theme.of(context);
//     return Form(
//       key: _step3Key,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               FilledButton.tonalIcon(
//                 onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
//                 icon: _isFetchingLocation
//                     ? SizedBox(
//                         height: 16,
//                         child: AppLoader(
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Icon(Icons.my_location),
//                 label: Text(
//                   _isFetchingLocation ? 'Fetching location...' : 'Use current location',
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: theme.colorScheme.primary.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(25.r),
//                       border: Border.all(
//                         color: theme.colorScheme.primary.withValues(alpha: 0.2),
//                       ),
//                     ),
//                     child: Center(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           if (_latitude != null && _longitude != null && _isFromCurrentLocation) ...[
//                             Padding(
//                               padding: const EdgeInsets.all(3.0),
//                               child: Text(
//                                 "Lat: ${_latitude!}",
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: theme.colorScheme.primary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(3.0),
//                               child: Text(
//                                 "Long: ${_longitude!}",
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: theme.colorScheme.primary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ] else ...[
//                             Padding(
//                               padding: const EdgeInsets.all(3.0),
//                               child: Text(
//                                 "Lat: N/A",
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: theme.colorScheme.primary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(3.0),
//                               child: Text(
//                                 "Long: N/A",
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: theme.colorScheme.primary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//             ],
//           ),
//           if (hasPinned) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.location_on, size: 14, color: Colors.green),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     _fullAddress ?? '${_addressLat!.toStringAsFixed(5)}, ${_addressLng!.toStringAsFixed(5)}',
//                     style: const TextStyle(fontSize: 12, color: Colors.green),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'Address Line 1',
//             controller: _addr1Ctrl,
//             validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'Address Line 2 (Optional)',
//             controller: _addr2Ctrl,
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'City',
//             controller: _cityCtrl,
//             validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'State',
//             controller: _stateCtrl,
//             validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'Pincode',
//             controller: _pincodeCtrl,
//             keyboardType: TextInputType.number,
//             maxLength: 6,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(6),
//             ],
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) return 'Pincode is required';
//               if (!RegExp(r'^[0-9]{6}$').hasMatch(v.trim())) {
//                 return 'Enter a valid 6-digit pincode';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
//
//   // ─── Step 4: Contact Details ─────────────────────────────────────────────
//
//   Widget _buildStep4() {
//     return Form(
//       key: _step4Key,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           KycTextField(
//             label: 'Business Phone',
//             controller: _phoneCtrl,
//             keyboardType: TextInputType.phone,
//             maxLength: 10,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(10),
//             ],
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) {
//                 return 'Business phone is required';
//               }
//               if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) {
//                 return 'Enter valid 10-digit phone number';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'WhatsApp Number',
//             controller: _whatsappCtrl,
//             keyboardType: TextInputType.phone,
//             maxLength: 10,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(10),
//             ],
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) {
//                 return 'WhatsApp number is required';
//               }
//               if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) {
//                 return 'Enter valid 10-digit number';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           KycTextField(
//             label: 'Email (Optional)',
//             controller: _emailCtrl,
//             keyboardType: TextInputType.emailAddress,
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) return null;
//               if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$').hasMatch(v.trim())) {
//                 return 'Enter valid email address';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),
//           const Text('Business Photos', style: TextStyle(fontWeight: FontWeight.w600)),
//           const SizedBox(height: 10),
//           _buildImageCard(
//             title: 'Shop Photo',
//             file: _shopPhotoFile,
//             onPick: _pickShopPhoto,
//           ),
//           if (_showShopRequiredWarning)
//             const Padding(
//               padding: EdgeInsets.only(top: 4, left: 12),
//               child: Text(
//                 'Shop photo is required to proceed.',
//                 style: TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 10),
//           _buildImageCard(
//             title: 'Owner Photo',
//             file: _ownerPhotoFile,
//             onPick: _pickOwnerPhoto,
//           ),
//           if (_showOwnerRequiredWarning)
//             const Padding(
//               padding: EdgeInsets.only(top: 4, left: 12),
//               child: Text(
//                 'Owner photo is required to proceed.',
//                 style: TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
//
//   // ─── Step 5: Review & Submit ─────────────────────────────────────────────
//
//   Widget _buildStep5Review() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _reviewSection('Business Info', [
//           _reviewRow('Business Name', _businessNameCtrl.text),
//           _reviewRow('Owner Name', _ownerNameCtrl.text),
//           _reviewRow(
//             'Business Type',
//             _businessType.replaceAll('_', ' ').toUpperCase(),
//           ),
//         ]),
//         _reviewSection('Legal Documents', [
//           _reviewRow('GST Number', _gstCtrl.text.toUpperCase()),
//           _reviewRow('PAN Number', _panCtrl.text.toUpperCase()),
//         ]),
//         _reviewSection('Address', [
//           _reviewRow('Line 1', _addr1Ctrl.text),
//           _reviewRow('Line 2', _addr2Ctrl.text),
//           _reviewRow('City', _cityCtrl.text),
//           _reviewRow('State', _stateCtrl.text),
//           _reviewRow('Pincode', _pincodeCtrl.text),
//           if (_fullAddress != null) _reviewRow('Map Address', _fullAddress!),
//           if (_addressLat != null && _addressLng != null)
//             _reviewRow('Coordinates', '${_addressLat!.toStringAsFixed(5)}, ${_addressLng!.toStringAsFixed(5)}'),
//         ]),
//         _reviewSection('Contact', [
//           _reviewRow('Phone', _phoneCtrl.text),
//           _reviewRow('WhatsApp', _whatsappCtrl.text),
//           if (_emailCtrl.text.isNotEmpty) _reviewRow('Email', _emailCtrl.text),
//         ]),
//         _reviewSection('Documents & Photos', [
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 if (_gstCertFile != null || (_existingKyc?.images.gstCertificateUrl?.isNotEmpty ?? false)) ...[
//                   _thumbnailPreview('GST Cert', _gstCertFile, _existingKyc?.images.gstCertificateUrl),
//                   SizedBox(width: 12.w),
//                 ],
//                 if (_panCardFile != null || (_existingKyc?.images.panCardUrl?.isNotEmpty ?? false)) ...[
//                   _thumbnailPreview('PAN Card', _panCardFile, _existingKyc?.images.panCardUrl),
//                   SizedBox(width: 12.w),
//                 ],
//                 if (_shopPhotoFile != null || (_existingKyc?.images.shopPhotoUrl?.isNotEmpty ?? false)) ...[
//                   _thumbnailPreview('Shop Photo', _shopPhotoFile, _existingKyc?.images.shopPhotoUrl),
//                   SizedBox(width: 12.w),
//                 ],
//                 if (_ownerPhotoFile != null || (_existingKyc?.images.ownerPhotoUrl?.isNotEmpty ?? false)) ...[
//                   _thumbnailPreview('Owner Photo', _ownerPhotoFile, _existingKyc?.images.ownerPhotoUrl),
//                 ],
//               ],
//             ),
//           ),
//         ]),
//         const SizedBox(height: 8),
//         Text(
//           'By submitting, you confirm that all information provided is accurate.',
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
//
//   // ─── Helpers ─────────────────────────────────────────────────────────────
//
//   Widget _thumbnailPreview(String label, File? file, String? url) {
//     Widget image;
//     bool hasFile = file != null;
//     bool hasUrl = url != null && url.isNotEmpty;
//
//     if (hasFile) {
//       image = Image.file(file, fit: BoxFit.cover);
//     } else if (hasUrl) {
//       image = Image.network(url, fit: BoxFit.cover);
//     } else {
//       image = Container(
//         color: Colors.grey.shade100,
//         child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 24),
//       );
//     }
//
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: (hasFile || hasUrl) ? () => _showFullscreenPreview(label, file, url) : null,
//           child: Container(
//             width: 80.w,
//             height: 80.w,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8.r),
//               border: Border.all(color: Colors.grey.shade300),
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 image,
//                 if (hasFile || hasUrl)
//                   Positioned(
//                     right: 4,
//                     top: 4,
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
//                       child: const Icon(Icons.fullscreen, size: 14, color: Colors.blue),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         SizedBox(height: 4.h),
//         Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
//
//   void _showFullscreenPreview(String title, File? file, String? url) {
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
//                 child: Container(color: Colors.grey.shade600),
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
//                       child: file != null ? Image.file(file, fit: BoxFit.contain) : Image.network(url!, fit: BoxFit.contain),
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.symmetric(vertical: 20.h),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _zoomButtonReview(
//                           icon: Icons.remove,
//                           onTap: () {
//                             final current = controller.value.getMaxScaleOnAxis();
//                             final next = (current - 0.5).clamp(0.5, 4.0);
//                             controller.value = Matrix4.diagonal3Values(next, next, 1.0);
//                           },
//                         ),
//                         SizedBox(width: 24.w),
//                         _zoomButtonReview(
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
//   Widget _zoomButtonReview({required IconData icon, required VoidCallback onTap}) {
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
//   Widget _reviewSection(String title, List<Widget> rows) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//             const Divider(height: 16),
//             ...rows,
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _reviewRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 3),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 110,
//             child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
//           ),
//           Expanded(
//             child: Text(
//               value.isEmpty ? '—' : value,
//               style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImageCard({
//     required String title,
//     required File? file,
//     required VoidCallback onPick,
//   }) {
//     Widget preview;
//     if (file != null && AppFileUploader.isImageFile(file)) {
//       preview = ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: Image.file(file, width: 50, height: 50, fit: BoxFit.cover),
//       );
//     } else if (file != null) {
//       preview = Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           color: Colors.red.shade50,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: const Icon(Icons.picture_as_pdf, color: Colors.red),
//       );
//     } else {
//       preview = Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
//       );
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           preview,
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
//                 if (file != null)
//                   Text(
//                     p.basename(file.path),
//                     style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//               ],
//             ),
//           ),
//           TextButton(
//             onPressed: onPick,
//             child: Text(file != null ? 'Change' : 'Upload'),
//           ),
//         ],
//       ),
//     );
//   }
// }
