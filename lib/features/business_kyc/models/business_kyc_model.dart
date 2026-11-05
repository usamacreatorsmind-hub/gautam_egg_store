import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';

export 'package:sure_wholesaler/core/constants/app_status.dart'
    show BusinessType, KycStatus;

/// =======================================================
/// BUSINESS IDENTITY
/// =======================================================

class BusinessIdentity {
  final String businessName;
  final String ownerName;
  final String businessType;

  const BusinessIdentity({
    required this.businessName,
    required this.ownerName,
    required this.businessType,
  });

  factory BusinessIdentity.fromMap(Map<String, dynamic> map) {
    return BusinessIdentity(
      businessName: map['businessName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      businessType: map['businessType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'ownerName': ownerName,
      'businessType': businessType,
    };
  }

  BusinessIdentity copyWith({
    String? businessName,
    String? ownerName,
    String? businessType,
  }) {
    return BusinessIdentity(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      businessType: businessType ?? this.businessType,
    );
  }
}

/// =======================================================
/// LEGAL DOCUMENTS
/// =======================================================

class LegalDocuments {
  final String gstNumber;
  final String panNumber;

  const LegalDocuments({
    required this.gstNumber,
    required this.panNumber,
  });

  factory LegalDocuments.fromMap(Map<String, dynamic> map) {
    return LegalDocuments(
      gstNumber: map['gstNumber'] ?? '',
      panNumber: map['panNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gstNumber': gstNumber.toUpperCase(),
      'panNumber': panNumber.toUpperCase(),
    };
  }

  LegalDocuments copyWith({
    String? gstNumber,
    String? panNumber,
  }) {
    return LegalDocuments(
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
    );
  }
}

/// =======================================================
/// BUSINESS ADDRESS
/// =======================================================

class BusinessAddress {
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? fullAddress;
  final double? latitude;
  final double? longitude;

  const BusinessAddress({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.fullAddress,
    this.latitude,
    this.longitude,
  });

  factory BusinessAddress.fromMap(Map<String, dynamic> map) {
    return BusinessAddress(
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      fullAddress: map['fullAddress'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  BusinessAddress copyWith({
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? fullAddress,
    double? latitude,
    double? longitude,
  }) {
    return BusinessAddress(
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// =======================================================
/// CONTACT DETAILS
/// =======================================================

class BusinessContact {
  final String businessPhone;
  final String whatsappNumber;
  final String? email;

  const BusinessContact({
    required this.businessPhone,
    required this.whatsappNumber,
    this.email,
  });

  factory BusinessContact.fromMap(Map<String, dynamic> map) {
    return BusinessContact(
      businessPhone: map['businessPhone'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessPhone': businessPhone,
      'whatsappNumber': whatsappNumber,
      'email': email,
    };
  }

  BusinessContact copyWith({
    String? businessPhone,
    String? whatsappNumber,
    String? email,
  }) {
    return BusinessContact(
      businessPhone: businessPhone ?? this.businessPhone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
    );
  }
}

/// =======================================================
/// KYC VERIFICATION
/// =======================================================

class KycVerification {
  final String kycStatus;

  final Timestamp? submittedAt;
  final Timestamp? reviewedAt;

  final String? rejectionReason;

  final String? reviewedByAdminId;

  const KycVerification({
    required this.kycStatus,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.reviewedByAdminId,
  });

  factory KycVerification.fromMap(Map<String, dynamic> map) {
    return KycVerification(
      kycStatus: map['kycStatus'] ?? KycStatus.pending,
      submittedAt: map['submittedAt'],
      reviewedAt: map['reviewedAt'],
      rejectionReason: map['rejectionReason'],
      reviewedByAdminId: map['reviewedByAdminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kycStatus': kycStatus,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'rejectionReason': rejectionReason,
      'reviewedByAdminId': reviewedByAdminId,
    };
  }

  KycVerification copyWith({
    String? kycStatus,
    Timestamp? submittedAt,
    Timestamp? reviewedAt,
    String? rejectionReason,
    String? reviewedByAdminId,
  }) {
    return KycVerification(
      kycStatus: kycStatus ?? this.kycStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedByAdminId: reviewedByAdminId ?? this.reviewedByAdminId,
    );
  }
}

/// =======================================================
/// BUSINESS IMAGES / DOCUMENTS
/// =======================================================

class BusinessImages {
  final String? gstCertificateUrl;
  final String? panCardUrl;

  final String? shopPhotoUrl;
  final String? ownerPhotoUrl;

  final String? cancelledChequeUrl;

  const BusinessImages({
    this.gstCertificateUrl,
    this.panCardUrl,
    this.shopPhotoUrl,
    this.ownerPhotoUrl,
    this.cancelledChequeUrl,
  });

  factory BusinessImages.fromMap(Map<String, dynamic> map) {
    return BusinessImages(
      gstCertificateUrl: map['gstCertificateUrl'],
      panCardUrl: map['panCardUrl'],
      shopPhotoUrl: map['shopPhotoUrl'],
      ownerPhotoUrl: map['ownerPhotoUrl'],
      cancelledChequeUrl: map['cancelledChequeUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gstCertificateUrl': gstCertificateUrl,
      'panCardUrl': panCardUrl,
      'shopPhotoUrl': shopPhotoUrl,
      'ownerPhotoUrl': ownerPhotoUrl,
      'cancelledChequeUrl': cancelledChequeUrl,
    };
  }

  BusinessImages copyWith({
    String? gstCertificateUrl,
    String? panCardUrl,
    String? shopPhotoUrl,
    String? ownerPhotoUrl,
    String? cancelledChequeUrl,
  }) {
    return BusinessImages(
      gstCertificateUrl: gstCertificateUrl ?? this.gstCertificateUrl,
      panCardUrl: panCardUrl ?? this.panCardUrl,
      shopPhotoUrl: shopPhotoUrl ?? this.shopPhotoUrl,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      cancelledChequeUrl: cancelledChequeUrl ?? this.cancelledChequeUrl,
    );
  }
}

/// =======================================================
/// BUSINESS SETTINGS
/// =======================================================

class BusinessSettings {
  final bool isActive;
  final bool isBlocked;
  final bool acceptsOnlinePayments;

  final double creditLimit;

  const BusinessSettings({
    required this.isActive,
    required this.isBlocked,
    required this.acceptsOnlinePayments,
    required this.creditLimit,
  });

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      isActive: map['isActive'] ?? true,
      isBlocked: map['isBlocked'] ?? false,
      acceptsOnlinePayments: map['acceptsOnlinePayments'] ?? false,
      creditLimit: (map['creditLimit'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'isBlocked': isBlocked,
      'acceptsOnlinePayments': acceptsOnlinePayments,
      'creditLimit': creditLimit,
    };
  }

  BusinessSettings copyWith({
    bool? isActive,
    bool? isBlocked,
    bool? acceptsOnlinePayments,
    double? creditLimit,
  }) {
    return BusinessSettings(
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      acceptsOnlinePayments:
          acceptsOnlinePayments ?? this.acceptsOnlinePayments,
      creditLimit: creditLimit ?? this.creditLimit,
    );
  }
}

/// =======================================================
/// MAIN BUSINESS KYC MODEL
/// =======================================================

class BusinessKycModel extends FirestoreModel {
  @override
  final String id;
  final String userId;

  final BusinessIdentity identity;
  final LegalDocuments legalDocuments;
  final BusinessAddress address;
  final BusinessContact contact;
  final KycVerification verification;
  final BusinessImages images;
  final BusinessSettings settings;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  BusinessKycModel({
    required this.id,
    required this.userId,
    required this.identity,
    required this.legalDocuments,
    required this.address,
    required this.contact,
    required this.verification,
    required this.images,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessKycModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return BusinessKycModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      identity: BusinessIdentity.fromMap(map),
      legalDocuments: LegalDocuments.fromMap(map),
      address: BusinessAddress.fromMap(map),
      contact: BusinessContact.fromMap(map),
      verification: KycVerification.fromMap(map),
      images: BusinessImages.fromMap(map),
      settings: BusinessSettings.fromMap(map),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      ...identity.toMap(),
      ...legalDocuments.toMap(),
      ...address.toMap(),
      ...contact.toMap(),
      ...verification.toMap(),
      ...images.toMap(),
      ...settings.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  BusinessKycModel copyWith({
    String? id,
    String? userId,
    BusinessIdentity? identity,
    LegalDocuments? legalDocuments,
    BusinessAddress? address,
    BusinessContact? contact,
    KycVerification? verification,
    BusinessImages? images,
    BusinessSettings? settings,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return BusinessKycModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      identity: identity ?? this.identity,
      legalDocuments: legalDocuments ?? this.legalDocuments,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      verification: verification ?? this.verification,
      images: images ?? this.images,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
