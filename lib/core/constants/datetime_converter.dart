import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDateConverter {
  FirestoreDateConverter._();

  /// Convert Firestore Timestamp / String / int to DateTime
  static DateTime parse(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    // Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // ISO String
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    // Milliseconds timestamp
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.now();
  }

  /// Convert DateTime to Firestore Timestamp
  static Timestamp toTimestamp(DateTime date) {
    return Timestamp.fromDate(date);
  }
}
