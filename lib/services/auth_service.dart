import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(region: 'asia-south1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calls the Cloud Function to send OTP via MSG91
  Future<void> sendOTP(String phoneNumber) async {
    try {
      // Remove any non-digit characters (like '+') for MSG91 compatibility
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      debugPrint('Sending OTP to cleaned number: $cleanNumber');

      final HttpsCallable callable = _functions.httpsCallable('sendOTP');
      final result = await callable.call({
        'phoneNumber': cleanNumber,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to send OTP');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'An error occurred while sending OTP');
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      throw Exception('Failed to connect to authentication service');
    }
  }

  /// Calls the Cloud Function to verify OTP and sign in with Custom Token
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      // Remove any non-digit characters (like '+') for MSG91 compatibility
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      final HttpsCallable callable = _functions.httpsCallable('verifyOTP');
      final result = await callable.call({
        'phoneNumber': cleanNumber,
        'otp': otp,
      });

      if (result.data['success'] == true && result.data['token'] != null) {
        final String customToken = result.data['token'];

        // Sign in to Firebase with the Custom Token received from backend
        final UserCredential userCredential = await _auth.signInWithCustomToken(customToken);
        return userCredential.user != null;
      } else {
        throw Exception(result.data['message'] ?? 'Invalid OTP');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Verification failed');
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      throw Exception('Incorrect OTP or verification failed');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}