import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_constants.dart';

class AppCredentials {
  final String googleMapApiKey;
  final String googleWebServiceApiKey;
  final String whatsappAccessToken;
  final String whatsappPhoneNumberId;
  final String whatsappGraphVersion;

  AppCredentials({
    this.googleMapApiKey = '',
    this.googleWebServiceApiKey = '',
    this.whatsappAccessToken = '',
    this.whatsappPhoneNumberId = '',
    this.whatsappGraphVersion = 'v22.0',
  });

  static final AppCredentials defaults = AppCredentials();
}

class RemoteCredentials {
  static Future<AppCredentials> load() async {
    final doc = await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: AppConfig.databaseId,
    ).collection('app_credentials').doc('credentials').get();

    final data = doc.data() ?? {};

    return AppCredentials(
      googleMapApiKey: data['googleMapApiKey'] ?? AppCredentials.defaults.googleMapApiKey,
      googleWebServiceApiKey: data['googleWebServiceApiKey'] ?? AppCredentials.defaults.googleWebServiceApiKey,
      whatsappAccessToken: data['whatsappAccessToken'] ?? AppCredentials.defaults.whatsappAccessToken,
      whatsappPhoneNumberId: data['whatsappPhoneNumberId'] ?? AppCredentials.defaults.whatsappPhoneNumberId,
      whatsappGraphVersion: data['whatsappGraphVersion'] ?? AppCredentials.defaults.whatsappGraphVersion,
    );
  }
}
