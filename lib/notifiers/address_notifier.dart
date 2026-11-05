import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/firebase/address_firestore_ds.dart';
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/repositories/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepositoryImpl(AddressFirestoreDsImpl());
});

final addressProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<UserAddressModel>>>(
        (ref) {
  return AddressNotifier(ref.read(addressRepositoryProvider));
});

class AddressNotifier
    extends StateNotifier<AsyncValue<List<UserAddressModel>>> {
  final AddressRepository _repository;
  StreamSubscription<List<UserAddressModel>>? _subscription;

  AddressNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchAddresses().listen(
      (addresses) {
        state = AsyncValue.data(addresses);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<void> saveAddress(UserAddressModel address) async {
    await _repository.saveAddress(address);
  }

  Future<void> updateAddress(UserAddressModel address) async {
    await _repository.updateAddress(address);
  }

  Future<void> deleteAddress(String addressId) async {
    await _repository.deleteAddress(addressId);
  }

  Future<void> setDefaultAddress(String addressId) async {
    await _repository.setDefaultAddress(addressId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
