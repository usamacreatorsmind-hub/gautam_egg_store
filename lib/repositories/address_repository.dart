import 'package:sure_wholesaler/firebase/address_firestore_ds.dart';
import 'package:sure_wholesaler/models/address_model.dart';

abstract class AddressRepository {
  Future<String> saveAddress(UserAddressModel address);
  Stream<List<UserAddressModel>> getAddresses();
  Stream<List<UserAddressModel>> watchAddresses();
  Future<void> updateAddress(UserAddressModel address);
  Future<void> deleteAddress(String addressId);
  Future<void> setDefaultAddress(String addressId);
}

class AddressRepositoryImpl implements AddressRepository {
  final AddressFirestoreDs _dataSource;

  AddressRepositoryImpl(this._dataSource);

  @override
  Future<String> saveAddress(UserAddressModel address) async {
    final userId = _dataSource.getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');

    return await _dataSource.saveAddress(userId, address.toMap());
  }

  @override
  Stream<List<UserAddressModel>> getAddresses() {
    final userId = _dataSource.getCurrentUserId();
    if (userId == null) return Stream.value([]);
    return _dataSource.getAddresses(userId).map((list) {
      return list.map((e) => UserAddressModel.fromMap(e)).toList();
    });
  }

  @override
  Stream<List<UserAddressModel>> watchAddresses() {
    final userId = _dataSource.getCurrentUserId();
    if (userId == null) return Stream.value([]);
    return _dataSource.watchAddresses(userId).map((list) {
      return list.map((e) => UserAddressModel.fromMap(e)).toList();
    });
  }

  @override
  Future<void> updateAddress(UserAddressModel address) async {
    final userId = _dataSource.getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    if (address.id == null) throw Exception('Address ID is null');
    await _dataSource.updateAddress(userId, address.id!, address.toMap());
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    final userId = _dataSource.getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    await _dataSource.deleteAddress(userId, addressId);
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    final userId = _dataSource.getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    await _dataSource.setDefaultAddress(userId, addressId);
  }
}
