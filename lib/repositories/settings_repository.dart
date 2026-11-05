import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/firebase/settings_firestore_ds.dart';
import 'package:sure_wholesaler/models/app_settings_model.dart';

final settingsDataSourceProvider = Provider<SettingsFirestoreDs>((ref) {
  return SettingsFirestoreDsImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(settingsDataSourceProvider));
});

final appSettingsProvider = StreamProvider<AppSettingsModel>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

class SettingsRepository {
  final SettingsFirestoreDs _dataSource;

  SettingsRepository(this._dataSource);

  Future<AppSettingsModel> getSettings() async {
    final data = await _dataSource.getGeneralSettings();
    if (data == null) return AppSettingsModel.defaults;
    return AppSettingsModel.fromMap(data);
  }

  Stream<AppSettingsModel> watchSettings() {
    return _dataSource.watchGeneralSettings().map((data) {
      if (data == null) return AppSettingsModel.defaults;
      return AppSettingsModel.fromMap(data);
    });
  }
}
