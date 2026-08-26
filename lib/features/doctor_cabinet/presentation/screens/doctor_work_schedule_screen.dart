import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_work_slot.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_calendar_day_strip.dart';
import '../widgets/doctor_calendar_metrics.dart';

/// «Рабочие часы» — свои свободные слоты, отдельно от календаря записей
/// пациентов ([DoctorCalendarScreen]).
///
/// Макета нет: сервер получил `/doctors/me/schedule` и `/doctors/me/slots`
/// 21 августа 2026, но дизайнер эти экраны ещё не рисовал. Вёрстка
/// собрана из уже принятых в кабинете врача частей — полосы дней
/// [DoctorCalendarDayStrip] и карточки-корзины, — чтобы не изобретать
/// новый визуальный язык без утверждения. Требует ревью дизайнера, когда
/// макет появится.
class DoctorWorkScheduleScreen extends ConsumerWidget {
  const DoctorWorkScheduleScreen({super.key, this.now});

  /// Момент, от которого форма нового слота берёт время по умолчанию.
  /// Параметризовано ради детерминированных тестов — так же, как
  /// `MedicalCardScreen.now`.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = ref.watch(selectedWorkScheduleDayProvider);
    final slots = ref.watch(doctorWorkSlotsForDayProvider).value ?? const [];
    final sorted = [...slots]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorCalendarMetrics.topBarToHeading),
              _Section(
                child: ScreenTopBar(
                  title: l10n.doctorWorkScheduleTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: GestureDetector(
                    onTap: () => _openAddSlotSheet(context, ref, selectedDay),
                    child: const AppIcon(
                      icon: MedixIcon.settings,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                RuDates.weekdayFull(selectedDay),
                textAlign: TextAlign.center,
                style: AppTypography.calendarDayHeading,
              ),
              const SizedBox(height: DoctorCalendarMetrics.headingToSubtitle),
              Text(
                RuDates.dayOrdinalMonthYear(selectedDay),
                textAlign: TextAlign.center,
                style: AppTypography.calendarDaySubtitle,
              ),
              const SizedBox(height: DoctorCalendarMetrics.subtitleToDayStrip),
              _Section(
                child: DoctorCalendarDayStrip(
                  selectedDay: selectedDay,
                  onDaySelected: (day) => ref
                      .read(selectedWorkScheduleDayProvider.notifier)
                      .select(day),
                  onPreviousWeek: () => ref
                      .read(selectedWorkScheduleDayProvider.notifier)
                      .previousWeek(),
                  onNextWeek: () => ref
                      .read(selectedWorkScheduleDayProvider.notifier)
                      .nextWeek(),
                ),
              ),
              const SizedBox(height: DoctorCalendarMetrics.dayStripToBuckets),
              _Section(
                child: AppCard(
                  padding: const EdgeInsets.all(
                    DoctorCalendarMetrics.cardPadding,
                  ),
                  child: sorted.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            l10n.doctorWorkScheduleEmpty,
                            textAlign: TextAlign.center,
                            style: AppTypography.captionMuted,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final slot in sorted) ...[
                              if (slot != sorted.first)
                                const SizedBox(
                                  height: DoctorCalendarMetrics.rowGap,
                                ),
                              _WorkSlotRow(
                                slot: slot,
                                onDelete:
                                    slot.status == DoctorWorkSlotStatus.open
                                    ? () => _deleteSlot(context, ref, slot)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: DoctorCalendarMetrics.bucketGap),
              _Section(
                child: Center(
                  child: GestureDetector(
                    onTap: () => _openAddSlotSheet(context, ref, selectedDay),
                    child: Text(
                      l10n.doctorAddSlotAction,
                      style: AppTypography.link,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height:
                    DoctorCalendarMetrics.screenH +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSlot(
    BuildContext context,
    WidgetRef ref,
    DoctorWorkSlot slot,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(doctorScheduleRepositoryProvider).deleteSlot(slot.id);
      ref.invalidate(doctorWorkSlotsForDayProvider);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      showFormErrorSnackBar(
        context,
        error.message.isEmpty ? l10n.doctorSlotDeleteError : error.message,
      );
    }
  }

  Future<void> _openAddSlotSheet(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _AddSlotSheet(day: day, now: now ?? DateTime.now),
    );
  }
}

/// Строка слота: время слева, статус или крестик удаления справа.
class _WorkSlotRow extends StatelessWidget {
  const _WorkSlotRow({required this.slot, this.onDelete});

  final DoctorWorkSlot slot;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range =
        '${RuDates.hourMinute(slot.startsAt)}–${RuDates.hourMinute(slot.endsAt)}';

    return SizedBox(
      height: DoctorCalendarMetrics.rowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: AppRadius.allMd,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(range, style: AppTypography.tileTitle),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusLabel(l10n),
                  style: AppTypography.tileSubtitle,
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _background => switch (slot.status) {
    DoctorWorkSlotStatus.open => AppColors.surfaceWhite,
    DoctorWorkSlotStatus.held => AppColors.surfaceChip,
    DoctorWorkSlotStatus.booked => AppColors.surfaceInfo,
    DoctorWorkSlotStatus.cancelled => AppColors.surface,
    DoctorWorkSlotStatus.unknown => AppColors.surfaceWhite,
  };

  String _statusLabel(AppLocalizations l10n) => switch (slot.status) {
    DoctorWorkSlotStatus.open => l10n.doctorWorkSlotStatusOpen,
    DoctorWorkSlotStatus.held => l10n.doctorWorkSlotStatusHeld,
    DoctorWorkSlotStatus.booked => l10n.doctorWorkSlotStatusBooked,
    DoctorWorkSlotStatus.cancelled => l10n.doctorWorkSlotStatusCancelled,
    DoctorWorkSlotStatus.unknown => '',
  };
}

/// Шторка добавления слота: два `showTimePicker`, отправка через
/// `createSlots`. Форма своя, не по макету — см. doc-комментарий экрана.
class _AddSlotSheet extends ConsumerStatefulWidget {
  const _AddSlotSheet({required this.day, required this.now});

  final DateTime day;
  final DateTime Function() now;

  @override
  ConsumerState<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends ConsumerState<_AddSlotSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hour = widget.now().hour;
    _start = TimeOfDay(hour: hour, minute: 0);
    // Не через `(hour + 1) % 24`: под конец суток это заворачивает конец
    // раньше начала, и форма открывается уже с ошибкой валидации.
    _end = hour >= 23
        ? const TimeOfDay(hour: 23, minute: 59)
        : TimeOfDay(hour: hour + 1, minute: 0);
    _syncControllers();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _startController.text = _formatted(_start);
    _endController.text = _formatted(_end);
  }

  static String _formatted(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  DateTime _at(TimeOfDay time) => DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day,
    time.hour,
    time.minute,
  );

  Future<void> _pick({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _syncControllers();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final startsAt = _at(_start);
    final endsAt = _at(_end);
    if (!endsAt.isAfter(startsAt)) {
      setState(() => _error = l10n.doctorSlotEndBeforeStartError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(doctorScheduleRepositoryProvider).createSlots([
        DoctorWorkSlotDraft(startsAt: startsAt, endsAt: endsAt),
      ]);
      ref.invalidate(doctorWorkSlotsForDayProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.doctorSlotCreateSuccess)));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message.isEmpty
            ? l10n.doctorSlotCreateError
            : error.message;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 21,
          right: 21,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.doctorAddSlotTitle, style: AppTypography.h2),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: l10n.doctorSlotStartLabel,
                        controller: _startController,
                        onTap: () => _pick(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _TimeField(
                        label: l10n.doctorSlotEndLabel,
                        controller: _endController,
                        onTap: () => _pick(isStart: false),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTypography.captionMuted.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l10n.doctorSlotSaveAction,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Поле само по себе read-only: значение меняет только `showTimePicker`
    // через AbsorbPointer, не клавиатура — тот же приём, что у даты
    // рождения в DoctorRegisterScreen.
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: AppTextField(
          label: label,
          controller: controller,
          height: AppTextField.compactFieldHeight,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorCalendarMetrics.screenH,
      ),
      child: child,
    );
  }
}
