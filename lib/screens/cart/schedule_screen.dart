import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sure_wholesaler/core/constants/app_colors.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  final RepeatSchedule? initial;
  const ScheduleScreen({super.key, this.initial});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late OrderFrequency _frequency;
  WeekDay? _weekday;
  List<WeekDay> _weekdays = [];
  int _dayOfMonth = 1;
  late TimeOfDay _timeSlot;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _frequency = s?.frequency ?? OrderFrequency.daily;
    _weekday = s?.weekday;
    _weekdays = s?.weekdays ?? [];
    _dayOfMonth = s?.dayOfMonth ?? 1;
    _timeSlot = s?.timeSlot ?? const TimeOfDay(hour: 9, minute: 0);
  }

  static const _freqLabels = {
    OrderFrequency.daily: 'Daily',
    OrderFrequency.weekly: 'Weekly',
    OrderFrequency.midWeekly: 'Twice a Week',
    OrderFrequency.monthly: 'Monthly',
  };

  static const _dayLabels = {
    WeekDay.monday: 'Mon',
    WeekDay.tuesday: 'Tue',
    WeekDay.wednesday: 'Wed',
    WeekDay.thursday: 'Thu',
    WeekDay.friday: 'Fri',
    WeekDay.saturday: 'Sat',
    WeekDay.sunday: 'Sun',
  };

  static const _dayFull = {
    WeekDay.monday: 'Monday',
    WeekDay.tuesday: 'Tuesday',
    WeekDay.wednesday: 'Wednesday',
    WeekDay.thursday: 'Thursday',
    WeekDay.friday: 'Friday',
    WeekDay.saturday: 'Saturday',
    WeekDay.sunday: 'Sunday',
  };

  bool get _isValid {
    switch (_frequency) {
      case OrderFrequency.daily:
        return true;
      case OrderFrequency.weekly:
        return _weekday != null;
      case OrderFrequency.midWeekly:
        return _weekdays.length == 2;
      case OrderFrequency.monthly:
        return true;
    }
  }

  RepeatSchedule _buildSchedule() {
    switch (_frequency) {
      case OrderFrequency.daily:
        return RepeatSchedule(frequency: _frequency, timeSlot: _timeSlot);
      case OrderFrequency.weekly:
        return RepeatSchedule(
            frequency: _frequency, timeSlot: _timeSlot, weekday: _weekday);
      case OrderFrequency.midWeekly:
        return RepeatSchedule(
            frequency: _frequency, timeSlot: _timeSlot, weekdays: _weekdays);
      case OrderFrequency.monthly:
        return RepeatSchedule(
            frequency: _frequency,
            timeSlot: _timeSlot,
            dayOfMonth: _dayOfMonth);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeSlot,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _timeSlot = picked);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Repeat Schedule',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.badgeText)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Delivery Frequency'),
                    SizedBox(height: 10.h),
                    _frequencySelector(),
                    SizedBox(height: 24.h),
                    if (_frequency == OrderFrequency.weekly) ...[
                      _sectionLabel('Delivery Day'),
                      SizedBox(height: 10.h),
                      _weekDayGrid(multi: false),
                      SizedBox(height: 24.h),
                    ],
                    if (_frequency == OrderFrequency.midWeekly) ...[
                      _sectionLabel('Select 2 Days'),
                      SizedBox(height: 6.h),
                      Text(
                        '${_weekdays.length}/2 selected',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: _weekdays.length == 2
                                ? AppColors.success
                                : AppColors.textSecondary),
                      ),
                      SizedBox(height: 8.h),
                      _weekDayGrid(multi: true),
                      SizedBox(height: 24.h),
                    ],
                    if (_frequency == OrderFrequency.monthly) ...[
                      _sectionLabel('Day of Month'),
                      SizedBox(height: 10.h),
                      _dayOfMonthPicker(),
                      SizedBox(height: 24.h),
                    ],
                    _sectionLabel('Preferred Time'),
                    SizedBox(height: 10.h),
                    _timePicker(),
                    SizedBox(height: 24.h),
                    _summaryCard(),
                  ],
                ),
              ),
            ),
            _confirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }

  Widget _frequencySelector() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: OrderFrequency.values.map((f) {
        final selected = _frequency == f;
        return GestureDetector(
          onTap: () => setState(() {
            _frequency = f;
            _weekday = null;
            _weekdays = [];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.brandSeed : AppColors.surface,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: selected
                    ? AppColors.brandSeed
                    : AppColors.priceStrikethrough,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: AppColors.brandSeed.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Text(
              _freqLabels[f]!,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.onBrand : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _weekDayGrid({required bool multi}) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: WeekDay.values.map((day) {
        final selected = multi ? _weekdays.contains(day) : _weekday == day;
        final disabled = multi && !selected && _weekdays.length >= 2;

        return GestureDetector(
          onTap: disabled
              ? null
              : () => setState(() {
                    if (multi) {
                      if (selected) {
                        _weekdays.remove(day);
                      } else {
                        _weekdays.add(day);
                      }
                    } else {
                      _weekday = day;
                    }
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppColors.brandSeed
                  : disabled
                      ? AppColors.surfaceVariant
                      : AppColors.surface,
              border: Border.all(
                color: selected ? AppColors.brandSeed : AppColors.textHint,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _dayLabels[day]!,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : disabled
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dayOfMonthPicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          Text('Day',
              style:
                  TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color:
                _dayOfMonth > 1 ? AppColors.brandSeed : AppColors.textDisabled,
            onPressed:
                _dayOfMonth > 1 ? () => setState(() => _dayOfMonth--) : null,
          ),
          SizedBox(
            width: 36.w,
            child: Text(
              '$_dayOfMonth',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color:
                _dayOfMonth < 28 ? AppColors.brandSeed : AppColors.textDisabled,
            onPressed:
                _dayOfMonth < 28 ? () => setState(() => _dayOfMonth++) : null,
          ),
        ],
      ),
    );
  }

  Widget _timePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(Icons.schedule, color: AppColors.brandSeed, size: 22.sp),
            SizedBox(width: 12.w),
            Text('Delivery Time',
                style:
                    TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
            const Spacer(),
            Text(_formatTime(_timeSlot),
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            SizedBox(width: 6.w),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    String summary;
    switch (_frequency) {
      case OrderFrequency.daily:
        summary = 'Every day at ${_formatTime(_timeSlot)}';
        break;
      case OrderFrequency.weekly:
        final dayName = _weekday != null ? _dayFull[_weekday!]! : '—';
        summary = 'Every $dayName at ${_formatTime(_timeSlot)}';
        break;
      case OrderFrequency.midWeekly:
        if (_weekdays.length == 2) {
          final names = _weekdays.map((d) => _dayFull[d]!).join(' & ');
          summary = 'Every $names at ${_formatTime(_timeSlot)}';
        } else {
          summary = 'Select 2 days to continue';
        }
        break;
      case OrderFrequency.monthly:
        summary =
            'Day $_dayOfMonth of every month at ${_formatTime(_timeSlot)}';
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.repeat, color: AppColors.brandSeed, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule Summary',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 4.h),
                Text(summary,
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_buildSchedule())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandSeed,
            disabledBackgroundColor: AppColors.border,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r)),
            elevation: 0,
          ),
          child: Text(
            'Confirm Schedule',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ),
      ),
    );
  }
}
