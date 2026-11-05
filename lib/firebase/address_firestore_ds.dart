import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/collections.dart';

abstract class AddressFirestoreDs {
  /// Save a new address and return document ID
  Future<String> saveAddress(String userId, Map<String, dynamic> data);

  /// Fetch all addresses for a user
  Stream<List<Map<String, dynamic>>> getAddresses(String userId);

  /// Fetch addresses in real-time
  Stream<List<Map<String, dynamic>>> watchAddresses(String userId);

  /// Update an address
  Future<bool> updateAddress(
      String userId, String addressId, Map<String, dynamic> data);

  /// Delete an address
  Future<bool> deleteAddress(String userId, String addressId);

  /// Get a single address by ID
  Stream<Map<String, dynamic>?> getAddressById(String userId, String addressId);

  /// Set an address as default (and unset others)
  Future<void> setDefaultAddress(String userId, String addressId);

  /// Get current authenticated user ID
  String? getCurrentUserId();
}

class AddressFirestoreDsImpl implements AddressFirestoreDs {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AddressFirestoreDsImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? AppConfig.firestore,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference _addressCollection(String userId) => _firestore
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.addresses);

  @override
  Future<String> saveAddress(String userId, Map<String, dynamic> data) async {
    try {
      final docRef = _addressCollection(userId).doc();
      data['id'] = docRef.id;
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getAddresses(String userId) {
    try {
      return _addressCollection(userId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchAddresses(String userId) {
    try {
      return _addressCollection(userId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to watch addresses: $e');
    }
  }

  @override
  Future<bool> updateAddress(
      String userId, String addressId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _addressCollection(userId).doc(addressId).update(data);
      return true;
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  @override
  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      await _addressCollection(userId).doc(addressId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>?> getAddressById(
      String userId, String addressId) {
    return _addressCollection(userId)
        .doc(addressId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>;
      data['id'] = snapshot.id;
      return data;
    }).handleError((e) {
      throw Exception('Failed to fetch address: $e');
    });
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // Get all addresses
      final snapshot = await _addressCollection(userId).get();

      // Batch update to set all to false, then set selected to true
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': doc.id == addressId});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  @override
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
