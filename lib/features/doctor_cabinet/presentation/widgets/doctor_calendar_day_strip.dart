import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/utils/ru_dates.dart';
import 'doctor_calendar_metrics.dart';

/// Полоса дней недели с перелистыванием — «Календарь.png»: семь колонок,
/// суббота и воскресенье погашены (врач по выходным не работает — не то
/// же самое, что «нет свободных слотов» у пациентской `_WeekStrip`,
/// поэтому виджет свой, не переиспользует телемедицину).
class DoctorCalendarDayStrip extends StatelessWidget {
  const DoctorCalendarDayStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.onPreviousWeek,
    this.onNextWeek,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  List<DateTime> get _weekDays {
    final monday = selectedDay.subtract(
      Duration(days: selectedDay.weekday - 1),
    );
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorCalendarMetrics.cardPadding,
        vertical: 12,
      ),
      child: SizedBox(
        height: DoctorCalendarMetrics.dayStripHeight - 24,
        child: Row(
          children: [
            _Arrow(icon: Icons.chevron_left, onTap: onPreviousWeek),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final day in _weekDays)
                    _DayColumn(
                      day: day,
                      isSelected: _isSameDay(day, selectedDay),
                      onTap: () => onDaySelected(day),
                    ),
                ],
              ),
            ),
            _Arrow(icon: Icons.chevron_right, onTap: onNextWeek),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;

  bool get _isWeekend => day.weekday >= DateTime.saturday;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isWeekend ? null : onTap,
      child: SizedBox(
        width: DoctorCalendarMetrics.dayColumnWidth,
        child: Column(
          children: [
            SizedBox(
              height: DoctorCalendarMetrics.dayLabelHeight,
              child: Center(
                child: Text(
                  RuDates.weekdayShort(day),
                  style: AppTypography.calendarLabel,
                ),
              ),
            ),
            SizedBox(
              width: DoctorCalendarMetrics.dayPillSize,
              height: DoctorCalendarMetrics.dayPillSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isWeekend
                      ? AppColors.surfaceDisabled
                      : (isSelected ? AppColors.accentSofter : null),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: _isWeekend
                        ? AppTypography.calendarLabel.copyWith(
                            color: AppColors.textDisabled,
                          )
                        : AppTypography.calendarLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
