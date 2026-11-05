// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import for TimeOfDay and DayPeriod

// Helper extension for capitalizing first letter
extension StringExtension on String {
  String get capitalizeFirst =>
      this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
}

enum OrderFrequency { daily, weekly, midWeekly, monthly }

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class RepeatSchedule {
  final OrderFrequency frequency;

  final WeekDay? weekday; // weekly
  final List<WeekDay>? weekdays; // midWeekly (exactly 2)
  final int? dayOfMonth; // monthly (1–31)

  final TimeOfDay timeSlot;

  RepeatSchedule({
    required this.frequency,
    required this.timeSlot,
    this.weekday,
    this.weekdays,
    this.dayOfMonth,
  }) {
    _validate();
  }

  // ================= VALIDATION =================
  void _validate() {
    switch (frequency) {
      case OrderFrequency.daily:
        if (weekday != null || weekdays != null || dayOfMonth != null) {
          throw Exception("Daily should not have weekday/weekdays/dayOfMonth");
        }
        break;

      case OrderFrequency.weekly:
        if (weekday == null) {
          throw Exception("Weekly requires 1 weekday");
        }
        if (weekdays != null || dayOfMonth != null) {
          throw Exception("Weekly should not have weekdays/dayOfMonth");
        }
        break;

      case OrderFrequency.midWeekly:
        if (weekdays == null || weekdays!.length != 2) {
          throw Exception("MidWeekly requires exactly 2 weekdays");
        }
        if (weekday != null || dayOfMonth != null) {
          throw Exception("MidWeekly should not have weekday/dayOfMonth");
        }
        break;

      case OrderFrequency.monthly:
        if (dayOfMonth == null) {
          throw Exception("Monthly requires dayOfMonth");
        }
        if (dayOfMonth! < 1 || dayOfMonth! > 31) {
          throw Exception("dayOfMonth must be between 1 and 31");
        }
        if (weekday != null || weekdays != null) {
          throw Exception("Monthly should not have weekday/weekdays");
        }
        break;
    }
  }

  // ================= HELPERS =================
  bool get isDaily => frequency == OrderFrequency.daily;
  bool get isWeekly => frequency == OrderFrequency.weekly;
  bool get isMidWeekly => frequency == OrderFrequency.midWeekly;
  bool get isMonthly => frequency == OrderFrequency.monthly;

  /// Returns the period of the day (AM/PM) for the scheduled time slot.
  DayPeriod get period => timeSlot.period;

  // ================= COPY =================
  RepeatSchedule copyWith({
    OrderFrequency? frequency,
    WeekDay? weekday,
    List<WeekDay>? weekdays,
    int? dayOfMonth,
    TimeOfDay? timeSlot,
  }) {
    return RepeatSchedule(
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      timeSlot: timeSlot ?? this.timeSlot,
    );
  }

  // ================= MAP =================
  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'weekday': weekday?.name,
      'weekdays': weekdays?.map((e) => e.name).toList(),
      'dayOfMonth': dayOfMonth,
      'timeSlot': {
        'hour': timeSlot.hour,
        'minute': timeSlot.minute,
        'hourOfPeriod': timeSlot.hourOfPeriod,
        'period': timeSlot.period.name,
      },
    };
  }

  factory RepeatSchedule.fromMap(Map<String, dynamic> map) {
    final timeMap = map['timeSlot'] as Map<String, dynamic>?;

    return RepeatSchedule(
      frequency: OrderFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => OrderFrequency.daily,
      ),
      weekday: map['weekday'] != null
          ? WeekDay.values.firstWhere(
              (e) => e.name == map['weekday'],
              orElse: () => WeekDay.monday,
            )
          : null,
      weekdays: map['weekdays'] != null
          ? List<WeekDay>.from(
              (map['weekdays'] as List).map(
                (e) => WeekDay.values.firstWhere(
                  (w) => w.name == e,
                  orElse: () => WeekDay.monday,
                ),
              ),
            )
          : null,
      dayOfMonth: (map['dayOfMonth'] as num?)?.toInt(),
      timeSlot: _parseTimeSlot(timeMap),
    );
  }

  static TimeOfDay _parseTimeSlot(Map<String, dynamic>? timeMap) {
    if (timeMap == null) return const TimeOfDay(hour: 0, minute: 0);

    int hour = timeMap['hour'] ?? 0;
    final int minute = timeMap['minute'] ?? 0;
    final String? periodStr = timeMap['period'];

    // If hour is 1-12 and a period is provided, convert to 24-hour format
    // for robustness against manual database edits or custom serialization.
    if (periodStr != null && hour > 0 && hour <= 12) {
      final p = periodStr.toLowerCase();
      if (p == 'pm' && hour < 12) hour += 12;
      if (p == 'am' && hour == 12) hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  // ================= JSON =================
  String toJson() => json.encode(toMap());

  factory RepeatSchedule.fromJson(String source) =>
      RepeatSchedule.fromMap(json.decode(source));

  // ================= UTILS =================
  @override
  String toString() {
    return 'RepeatSchedule(frequency: $frequency, weekday: $weekday, weekdays: $weekdays, dayOfMonth: $dayOfMonth, timeSlot: $timeSlot)';
  }

  @override
  bool operator ==(covariant RepeatSchedule other) {
    if (identical(this, other)) return true;

    return other.frequency == frequency &&
        other.weekday == weekday &&
        listEquals(other.weekdays, weekdays) &&
        other.dayOfMonth == dayOfMonth &&
        other.timeSlot == timeSlot;
  }

  @override
  int get hashCode {
    return frequency.hashCode ^
        weekday.hashCode ^
        weekdays.hashCode ^
        dayOfMonth.hashCode ^
        timeSlot.hashCode;
  }

  // New: User-friendly string representation of the schedule
  String get displayString {
    String freqLabel = '';
    switch (frequency) {
      case OrderFrequency.daily:
        freqLabel = 'Every day';
        break;
      case OrderFrequency.weekly:
        freqLabel = 'Every ${weekday?.name.capitalizeFirst ?? ''}';
        break;
      case OrderFrequency.midWeekly:
        final days = weekdays?.map((d) => d.name.capitalizeFirst).join(' & ');
        freqLabel = 'Twice a week on $days';
        break;
      case OrderFrequency.monthly:
        freqLabel = 'Day $dayOfMonth of every month';
        break;
    }

    final hour = timeSlot.hourOfPeriod;
    final minute = timeSlot.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute ${period.name.toUpperCase()}';
    return '$freqLabel at $formattedTime';
  }
}
