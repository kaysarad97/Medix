import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import 'doctor_day_column.dart';
import 'doctor_history_metrics.dart';

/// Карточка месяца «Истории записей»: «Июль, 2026» со стрелками в правом
/// углу и неделя выбранного дня под ним.
///
/// Отличается от `DoctorCalendarDayStrip` не колонками (они общие), а
/// шапкой: в календаре стрелки листают неделю и стоят по бокам полосы, а
/// здесь — листают месяц и стоят у заголовка.
class DoctorHistoryMonthCard extends StatelessWidget {
  const DoctorHistoryMonthCard({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

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
        horizontal: DoctorHistoryMetrics.cardPadding,
        vertical: 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  RuDates.monthAndYear(selectedDay),
                  style: AppTypography.monthTitle,
                ),
              ),
              _Arrow(icon: Icons.chevron_left, onTap: onPreviousMonth),
              const SizedBox(width: 14),
              _Arrow(icon: Icons.chevron_right, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in _weekDays)
                DoctorDayColumn(
                  day: day,
                  isSelected: _isSameDay(day, selectedDay),
                  onTap: () => onDaySelected(day),
                ),
            ],
          ),
        ],
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
