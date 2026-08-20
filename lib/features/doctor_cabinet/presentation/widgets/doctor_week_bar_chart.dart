import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import 'doctor_analytics_metrics.dart';

/// Столбики записей по дням недели — «Аналитика Работы.png».
///
/// Самый высокий столбик залит ярким синим, остальные — светлым: так в
/// макете выделен день с максимумом, а не какой-то конкретный день недели.
/// Выходные серые, как и в полосе дней календаря: врач по ним не работает.
/// Пустой день рисуется белой рамкой, иначе на его месте была бы дыра, а
/// подпись «0» висела бы в воздухе.
class DoctorWeekBarChart extends StatelessWidget {
  const DoctorWeekBarChart({
    super.key,
    required this.from,
    required this.perDay,
  });

  /// Понедельник недели — от него считаются подписи дней.
  final DateTime from;

  /// Семь значений, с понедельника.
  final List<int> perDay;

  int get _max => perDay.fold(0, (max, value) => value > max ? value : max);

  @override
  Widget build(BuildContext context) {
    final max = _max == 0 ? 1 : _max;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (index, value) in perDay.indexed)
          _Bar(
            day: from.add(Duration(days: index)),
            value: value,
            // Доля от максимума: абсолютных высот в макете нет, столбики
            // соотносятся между собой.
            share: value / max,
            isTallest: value == _max && value > 0,
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.value,
    required this.share,
    required this.isTallest,
  });

  final DateTime day;
  final int value;
  final double share;
  final bool isTallest;

  bool get _isWeekend => day.weekday >= DateTime.saturday;

  /// Шкала в макете сжата: столбик за одну запись вдвое ниже столбика за
  /// три, а не втрое, и пустой день не исчезает вовсе. Замер по
  /// «Аналитика Работы.png»: пустой и выходной ≈ 37 px, максимум ≈ 67 px.
  /// Поэтому доля считается не от нуля, а от этой отметки.
  static const double _minShare = 0.55;

  double get _heightFactor {
    if (_isWeekend || value == 0) return _minShare;
    return _minShare + (1 - _minShare) * share;
  }

  @override
  Widget build(BuildContext context) {
    final color = _isWeekend
        ? AppColors.surfaceDisabled
        : (value == 0
              ? AppColors.surfaceWhite
              : (isTallest ? AppColors.primaryBright : AppColors.accent));

    return SizedBox(
      width: DoctorAnalyticsMetrics.barWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isWeekend ? '' : '$value', style: AppTypography.tileSubtitle),
          const SizedBox(height: 4),
          SizedBox(
            height: DoctorAnalyticsMetrics.barChartHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              // Высота считается сама, а не через FractionallySizedBox:
              // тот задаёт только высоту, ширина остаётся свободной, и
              // пустой DecoratedBox схлопывается в ноль — столбиков на
              // экране не было вовсе.
              child: SizedBox(
                width: DoctorAnalyticsMetrics.barWidth,
                height: DoctorAnalyticsMetrics.barChartHeight * _heightFactor,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.allXs,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(RuDates.weekdayShort(day), style: AppTypography.tileSubtitle),
        ],
      ),
    );
  }
}
