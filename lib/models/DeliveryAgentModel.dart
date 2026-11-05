// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_status.dart';

class DeliveryAgentModel {
  final String email;
  final String address;
  final String bikeNumber;
  final int totalDeliveries;
  final int successfulDeliveries;
  final int cancelledDeliveries;
  final double commissionEarned;
  final double rating;
  final Timestamp joinedAt;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String aadhaarNumber;
  final String drivingNumber;
  final String panNumber;
  final DateTime updatedAt;
  final bool approved;
  final String profileImageUrl;
  final bool canLogin;
  final String status;

  DeliveryAgentModel({
    required this.email,
    required this.address,
    required this.bikeNumber,
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.cancelledDeliveries,
    required this.commissionEarned,
    required this.rating,
    required this.joinedAt,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.aadhaarNumber,
    required this.drivingNumber,
    required this.panNumber,
    required this.updatedAt,
    required this.approved,
    required this.profileImageUrl,
    required this.canLogin,
    required this.status,
  });

  /// 🔹 From Firestore
  factory DeliveryAgentModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAgentModel(
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      bikeNumber: json['bikeNumber'] ?? '',
      totalDeliveries: json['totalDeliveries'] ?? 0,
      successfulDeliveries: json['successfulDeliveries'] ?? 0,
      cancelledDeliveries: json['cancelledDeliveries'] ?? 0,
      commissionEarned: (json['commissionEarned'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      joinedAt: json['joinedAt'] is Timestamp
          ? json['joinedAt'] as Timestamp
          : Timestamp.now(),
      phoneNumber: json['phoneNumber'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      drivingNumber: json['drivingNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      approved: json['approved'] ?? false,
      profileImageUrl: json['profileImageUrl'] ?? '',
      canLogin: json['canLogin'] ?? false,
      status: json['status'] ?? AgentStatus.inactive,
    );
  }

  /// 🔹 To Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'address': address,
      'bikeNumber': bikeNumber,
      'totalDeliveries': totalDeliveries,
      'successfulDeliveries': successfulDeliveries,
      'cancelledDeliveries': cancelledDeliveries,
      'commissionEarned': commissionEarned,
      'rating': rating,
      'joinedAt': joinedAt,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'aadhaarNumber': aadhaarNumber,
      'drivingNumber': drivingNumber,
      'panNumber': panNumber,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approved': approved,
      'profileImageUrl': profileImageUrl,
      'canLogin': canLogin,
      'status': status,
    };
  }

  /// 🔹 Convenience getters
  String get fullName => '$firstName $lastName';

  bool get isActive => status.toLowerCase() == AgentStatus.active;

  @override
  String toString() {
    return 'DeliveryAgentModel(email: $email, address: $address, bikeNumber: $bikeNumber, totalDeliveries: $totalDeliveries, successfulDeliveries: $successfulDeliveries, cancelledDeliveries: $cancelledDeliveries, commissionEarned: $commissionEarned, rating: $rating, joinedAt: $joinedAt, phoneNumber: $phoneNumber, firstName: $firstName, lastName: $lastName, aadhaarNumber: $aadhaarNumber, drivingNumber: $drivingNumber, panNumber: $panNumber, updatedAt: $updatedAt, approved: $approved, profileImageUrl: $profileImageUrl, canLogin: $canLogin, status: $status)';
  }
}
