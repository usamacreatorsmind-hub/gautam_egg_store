import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sure_wholesaler/core/constants/app_credentials.dart';

class WhatsappApiService {
  static String get _accessToken => AppCredentials.defaults.whatsappAccessToken;
  static String get _phoneNumberId =>
      AppCredentials.defaults.whatsappPhoneNumberId;
  static String get _graphVersion =>
      AppCredentials.defaults.whatsappGraphVersion;

  static bool get isConfigured =>
      _accessToken.isNotEmpty && _phoneNumberId.isNotEmpty;

  static Future<void> sendPdfBill({
    required String customerPhone,
    required File pdfFile,
    required String orderNumber,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'WhatsApp API is not configured. Missing WHATSAPP_ACCESS_TOKEN or WHATSAPP_PHONE_NUMBER_ID.',
      );
    }

    final normalizedPhone = _normalizePhoneNumber(customerPhone);
    if (normalizedPhone.isEmpty) {
      throw ArgumentError('Customer phone number is empty or invalid.');
    }

    try {
      final mediaId = await _uploadMedia(pdfFile);

      final url = Uri.parse(
        'https://graph.facebook.com/$_graphVersion/$_phoneNumberId/messages',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "recipient_type": "individual",
          "to": normalizedPhone,
          "type": "document",
          "document": {
            "id": mediaId,
            "filename": "Bill_$orderNumber.pdf",
            "caption": "Your order bill is attached.\nOrder: $orderNumber"
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send WhatsApp message: ${response.body}');
      }
    } catch (e) {
      debugPrint("WhatsApp Service Error: $e");
      rethrow;
    }
  }

  static Future<String> _uploadMedia(File pdfFile) async {
    final url = Uri.parse(
      'https://graph.facebook.com/$_graphVersion/$_phoneNumberId/media',
    );

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $_accessToken'
      ..fields['messaging_product'] = 'whatsapp'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfFile.path,
          contentType: MediaType('application', 'pdf'),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to upload media: ${response.body}');
    }
  }

  static String _normalizePhoneNumber(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    return digitsOnly;
  }
}
