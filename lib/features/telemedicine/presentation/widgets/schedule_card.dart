import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/doctor_schedule.dart';
import 'action_button_row.dart';
import 'doctor_metrics.dart';

/// Карточка расписания: месяц, недельная лента, слоты времени и пара кнопок.
///
/// Одна и та же карточка на обоих макетах — «Расписание» на профиле врача
/// и «Перенести запись» на экране записи. Отличаются только заголовок и
/// стрелки перелистывания месяца, которых на экране записи нет.
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.title,
    required this.schedule,
    required this.primaryAction,
    required this.secondaryAction,
    this.selectedDay,
    this.selectedSlot,
    this.onDaySelected,
    this.onSlotSelected,
    this.onPreviousMonth,
    this.onNextMonth,
    this.showMonthArrows = true,
  });

  final String title;
  final DoctorSchedule schedule;
  final ActionButtonData primaryAction;
  final ActionButtonData secondaryAction;

  final ScheduleDay? selectedDay;
  final ScheduleSlot? selectedSlot;
  final ValueChanged<ScheduleDay>? onDaySelected;
  final ValueChanged<ScheduleSlot>? onSlotSelected;

  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final bool showMonthArrows;

  @override
  Widget build(BuildContext context) {
    final slots = selectedDay?.slots ?? const <ScheduleSlot>[];

    return AppCard(
      padding: DoctorMetrics.cardPadding,
      borderRadius: DoctorMetrics.allRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.cardTitleAccent),
          const SizedBox(height: DoctorMetrics.titleToMonth),
          _MonthRow(
            label: schedule.monthLabel,
            showArrows: showMonthArrows,
            onPrevious: onPreviousMonth,
            onNext: onNextMonth,
          ),
          const SizedBox(height: DoctorMetrics.monthToDays),
          _WeekStrip(
            days: schedule.days,
            selected: selectedDay,
            onSelected: onDaySelected,
          ),
          const SizedBox(height: DoctorMetrics.daysToSlots),
          _SlotStrip(
            slots: slots,
            selected: selectedSlot,
            onSelected: onSlotSelected,
          ),
          const SizedBox(height: DoctorMetrics.slotsToActions),
          ActionButtonRow(
            primary: primaryAction,
            secondary: secondaryAction,
            height: DoctorMetrics.cardActionHeight,
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.label,
    required this.showArrows,
    this.onPrevious,
    this.onNext,
  });

  final String label;
  final bool showArrows;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Стрелки не прижаты к краю карточки: в макете правая кончается на 380
  /// при внутренней кромке 401.
  static const double arrowsRight = 13;
  static const double arrowBox = 20;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.monthTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showArrows) ...[
          _Arrow(icon: Icons.chevron_left, onTap: onPrevious),
          _Arrow(icon: Icons.chevron_right, onTap: onNext),
          const SizedBox(width: arrowsRight),
        ],
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MonthRow.arrowBox,
      height: _MonthRow.arrowBox,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            // Гаснет, когда листать некуда: иначе нажатие без отклика
            // читается как поломка.
            color: onTap == null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Лента из семи дней.
///
/// В макете колонки шириной 40 с шагом 53 — вместе 358 при внутренней
/// ширине карточки 362. На узких экранах строка не помещается, поэтому
/// уменьшается целиком: разъехавшийся календарь читается хуже мелкого.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, this.selected, this.onSelected});

  final List<ScheduleDay> days;
  final ScheduleDay? selected;
  final ValueChanged<ScheduleDay>? onSelected;

  static const double gap = 13;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.daysHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final day in days) ...[
              if (day != days.first) const SizedBox(width: gap),
              _DayColumn(
                day: day,
                isSelected: day.date == selected?.date,
                onTap: () => onSelected?.call(day),
              ),
            ],
          ],
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

  final ScheduleDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Подложка выделения в макете #C5E3FF — светлее accentSofter на 2 %.
    // Считаем тем же токеном: разница неразличима, а лишний оттенок в
    // палитре дороже.
    final Color? background = day.isAvailable
        ? (isSelected ? AppColors.accentSofter : null)
        : AppColors.surfaceDisabled;

    return GestureDetector(
      onTap: day.isAvailable ? onTap : null,
      child: SizedBox(
        width: DoctorMetrics.dayColumnWidth,
        height: DoctorMetrics.daysHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: DoctorMetrics.allRadius,
          ),
          child: Column(
            children: [
              SizedBox(
                height: DoctorMetrics.dayPillTop,
                child: Center(
                  child: Text(
                    day.weekdayLabel,
                    style: AppTypography.calendarLabel,
                  ),
                ),
              ),
              _DayPill(day: day),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day});

  final ScheduleDay day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DoctorMetrics.dayPillSize.width,
      height: DoctorMetrics.dayPillSize.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: DoctorMetrics.allRadius,
        ),
        child: Center(
          child: Text(
            day.dayLabel,
            style: day.isAvailable
                ? AppTypography.calendarLabel
                : AppTypography.calendarLabel.copyWith(
                    color: AppColors.textDisabled,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Слоты времени. Ширина по содержимому, поэтому «9:30» уже «10:30» —
/// так и в макете.
class _SlotStrip extends StatelessWidget {
  const _SlotStrip({required this.slots, this.selected, this.onSelected});

  final List<ScheduleSlot> slots;
  final ScheduleSlot? selected;
  final ValueChanged<ScheduleSlot>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.slotHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final slot in slots) ...[
              if (slot != slots.first)
                const SizedBox(width: DoctorMetrics.slotGap),
              _Slot(
                slot: slot,
                // Сравнение по идентификатору: слоты приходят с сервера
                // разными объектами при каждом чтении расписания.
                isSelected: slot.id == selected?.id,
                onTap: () => onSelected?.call(slot),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final ScheduleSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.slotHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: DoctorMetrics.allRadius,
          // Выбранный слот в макете обведён, а не залит.
          side: isSelected
              ? const BorderSide(color: AppColors.primaryBright)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorMetrics.slotPaddingH,
            ),
            child: Center(
              child: Text(slot.timeLabel, style: AppTypography.calendarLabel),
            ),
          ),
        ),
      ),
    );
  }
}
