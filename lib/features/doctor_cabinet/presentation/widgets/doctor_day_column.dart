import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';

/// Колонка дня недели — общая для календаря и «Истории записей»: в обоих
/// макетах (`Календарь.png`, `История записей.png`) она нарисована
/// одинаково.
///
/// Замеры по `История записей.png`: капсула 41×83 обнимает подпись и
/// число целиком, число сидит в белой пилюле 38×29. Капсула красится
/// только у выбранного дня (голубая) и у выходных (серая) — у обычного
/// дня её нет вовсе, поэтому фон подложки прозрачный.
class DoctorDayColumn extends StatelessWidget {
  const DoctorDayColumn({
    super.key,
    required this.day,
    required this.isSelected,
    this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Врач по выходным не принимает — колонка гаснет и не нажимается.
  bool get _isWeekend => day.weekday >= DateTime.saturday;

  static const double width = 41;
  static const double height = 83;
  static const double pillWidth = 38;
  static const double pillHeight = 29;

  @override
  Widget build(BuildContext context) {
    final capsule = _isWeekend
        ? AppColors.surfaceDisabled
        : (isSelected ? AppColors.accentSofter : null);

    return GestureDetector(
      onTap: _isWeekend ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: capsule,
            borderRadius: BorderRadius.circular(width / 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                RuDates.weekdayShort(day),
                style: _isWeekend
                    ? AppTypography.calendarLabel.copyWith(
                        color: AppColors.textDisabled,
                      )
                    : AppTypography.calendarLabel,
              ),
              SizedBox(
                width: pillWidth,
                height: pillHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // У выходного пилюля сливается с капсулой — в макете
                    // видно только число, без белой подложки под ним.
                    color: _isWeekend
                        ? Colors.transparent
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(pillHeight / 2),
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
      ),
    );
  }
}
