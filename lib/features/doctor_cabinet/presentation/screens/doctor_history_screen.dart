import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_history_metrics.dart';
import '../widgets/doctor_history_month_card.dart';
import '../widgets/doctor_history_row.dart';

/// «История записей» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/История записей.png`
/// (440×956). Экран общий для клиники и фрилансера: в обоих комплектах
/// макет один и тот же.
///
/// Маршрут зарегистрирован отдельно от реального входа — см.
/// `DoctorHomeScreen` и HANDOFF.md, «Кабинет врача».
class DoctorHistoryScreen extends ConsumerWidget {
  const DoctorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final day = ref.watch(selectedHistoryDayProvider);
    final previous = ref.watch(doctorPreviousAppointmentProvider).value;
    final others = ref.watch(doctorPastAppointmentsProvider).value ?? const [];
    final range = historyWeekRange(day, ref.watch(historyWeekOffsetProvider));

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorHistoryMetrics.topBarTop),
              ScreenTopBar(
                title: l10n.doctorHistoryTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: DoctorHistoryMetrics.topBarToCard),
              _Section(
                child: DoctorHistoryMonthCard(
                  selectedDay: day,
                  onDaySelected: (value) => ref
                      .read(selectedHistoryDayProvider.notifier)
                      .select(value),
                  onPreviousMonth: () => ref
                      .read(selectedHistoryDayProvider.notifier)
                      .previousMonth(),
                  onNextMonth: () =>
                      ref.read(selectedHistoryDayProvider.notifier).nextMonth(),
                ),
              ),
              const SizedBox(height: DoctorHistoryMetrics.monthCardToSearch),
              const _Section(child: _SearchField()),
              const SizedBox(height: DoctorHistoryMetrics.searchToPrevious),
              if (previous != null) ...[
                _Section(child: _PreviousCard(appointment: previous)),
                const SizedBox(height: DoctorHistoryMetrics.previousToOthers),
              ],
              _Section(
                child: _OthersCard(
                  appointments: others,
                  rangeLabel:
                      '${RuDates.dayMonth(range.from)}-${RuDates.dayMonth(range.to)}',
                  onPrevious: () =>
                      ref.read(historyWeekOffsetProvider.notifier).previous(),
                  onNext: () =>
                      ref.read(historyWeekOffsetProvider.notifier).next(),
                ),
              ),
              SizedBox(
                height:
                    DoctorHistoryMetrics.screenH +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Выделенная карточка с последней прошедшей записью.
class _PreviousCard extends StatelessWidget {
  const _PreviousCard({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.accentSoft,
      padding: const EdgeInsets.all(DoctorHistoryMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height:
                DoctorHistoryMetrics.cardHeaderHeight -
                DoctorHistoryMetrics.cardPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.doctorHistoryPreviousTitle,
                    style: AppTypography.cardItemTitle,
                  ),
                ),
                Text(appointment.shortDate, style: AppTypography.cardItemTitle),
              ],
            ),
          ),
          DoctorHistoryRow(
            appointment: appointment,
            onTap: () =>
                context.push(Routes.doctorPastAppointmentOf(appointment.id)),
          ),
        ],
      ),
    );
  }
}

/// «Другие записи» за отлистанную неделю.
class _OthersCard extends StatelessWidget {
  const _OthersCard({
    required this.appointments,
    required this.rangeLabel,
    this.onPrevious,
    this.onNext,
  });

  final List<DoctorAppointment> appointments;
  final String rangeLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(DoctorHistoryMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height:
                DoctorHistoryMetrics.othersHeaderHeight -
                DoctorHistoryMetrics.cardPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.doctorHistoryOthersTitle,
                    style: AppTypography.sectionTitle,
                  ),
                ),
                _PagerArrow(icon: Icons.chevron_left, onTap: onPrevious),
                const SizedBox(width: 6),
                Text(
                  rangeLabel,
                  style: AppTypography.linkSmall.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryBright,
                  ),
                ),
                const SizedBox(width: 6),
                _PagerArrow(icon: Icons.chevron_right, onTap: onNext),
              ],
            ),
          ),
          if (appointments.isEmpty)
            SizedBox(
              height: DoctorHistoryMetrics.rowHeight,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: AppRadius.allMd,
                ),
                child: Center(
                  child: Text(
                    l10n.doctorCalendarEmptyLabel,
                    style: AppTypography.tileSubtitle,
                  ),
                ),
              ),
            )
          else
            for (final (index, appointment) in appointments.indexed) ...[
              if (index > 0)
                const SizedBox(height: DoctorHistoryMetrics.rowGap),
              DoctorHistoryRow(
                appointment: appointment,
                onTap: () => context.push(
                  Routes.doctorPastAppointmentOf(appointment.id),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _PagerArrow extends StatelessWidget {
  const _PagerArrow({required this.icon, this.onTap});

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
          child: Icon(icon, size: 18, color: AppColors.primaryBright),
        ),
      ),
    );
  }
}

/// «Поиск по имени» — фильтрует список «Других записей» по мере ввода.
class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: DoctorHistoryMetrics.searchHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.allPill,
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            const AppIcon(icon: MedixIcon.search, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: TextField(
                  onChanged: (value) =>
                      ref.read(historySearchQueryProvider.notifier).set(value),
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l10n.doctorHistorySearchHint,
                    hintStyle: AppTypography.placeholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
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
        horizontal: DoctorHistoryMetrics.screenH,
      ),
      child: child,
    );
  }
}
