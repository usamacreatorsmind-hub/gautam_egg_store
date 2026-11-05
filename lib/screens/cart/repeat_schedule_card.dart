import 'package:flutter/material.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';

class RepeatScheduleCard extends StatelessWidget {
  final RepeatSchedule schedule;

  const RepeatScheduleCard({super.key, required this.schedule});

  IconData _getIcon() {
    switch (schedule.frequency) {
      case OrderFrequency.daily:
        return Icons.calendar_today;
      case OrderFrequency.weekly:
        return Icons.date_range;
      case OrderFrequency.midWeekly:
        return Icons.event_repeat;
      case OrderFrequency.monthly:
        return Icons.calendar_month;
    }
  }

  Color _badgeColor() {
    switch (schedule.frequency) {
      case OrderFrequency.daily:
        return AppColors.success;
      case OrderFrequency.weekly:
        return AppColors.infoBright;
      case OrderFrequency.midWeekly:
        return AppColors.warning;
      case OrderFrequency.monthly:
        return AppColors.accentPurple;
    }
  }

  String _badgeText() {
    return schedule.frequency.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hour = schedule.timeSlot.hourOfPeriod == 0
        ? 12
        : schedule.timeSlot.hourOfPeriod;
    final minute = schedule.timeSlot.minute.toString().padLeft(2, '0');
    final time = "$hour:$minute ${schedule.period.name.toUpperCase()}";

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _badgeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(),
              color: _badgeColor(),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.displayString,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _badgeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _badgeText(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _badgeColor(),
                        ),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  _subtitle(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 6),

                // Time highlight
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    switch (schedule.frequency) {
      case OrderFrequency.daily:
        return 'Daily delivery';
      case OrderFrequency.weekly:
        return 'Once every week';
      case OrderFrequency.midWeekly:
        return 'Twice weekly';
      case OrderFrequency.monthly:
        return 'Monthly schedule';
    }
  }
}
