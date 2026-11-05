import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppDebug {
  static void log(dynamic message) {
    if (kDebugMode) {
      debugPrint(message.toString());
    }
  }

  /// For UI widget
  static Widget errorWidget({String text = "Something went wrong"}) {
    return Center(
      child: Text(text),
    );
  }

  /// For popup
  static void showError(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(text),
      ),
    );
  }
}

