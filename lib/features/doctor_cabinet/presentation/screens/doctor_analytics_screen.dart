import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/work_analytics.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_analytics_metrics.dart';
import '../widgets/doctor_analytics_stat_tile.dart';
import '../widgets/doctor_month_line_chart.dart';
import '../widgets/doctor_week_bar_chart.dart';

/// «Аналитика Работы» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Аналитика Работы.png`
/// (440×956). Две карточки одного состава: неделя светлая со столбиками,
/// месяц синий с ломаной.
///
/// Стрелки пейджеров в макете нарисованы, но листать нечего: цифры за
/// другие недели и месяцы взять негде — бэкенда под кабинет врача нет.
/// Поэтому они показаны, но неактивны, — как «Загрузить заключение» на
/// «О прошлой записи».
class DoctorAnalyticsScreen extends ConsumerWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final analytics = ref.watch(doctorWorkAnalyticsProvider).value;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: analytics == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DoctorAnalyticsMetrics.topBarTop),
                    ScreenTopBar(
                      title: l10n.doctorAnalyticsTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: DoctorAnalyticsMetrics.topBarToCard),
                    _Section(child: _WeekCard(week: analytics.week)),
                    const SizedBox(height: DoctorAnalyticsMetrics.cardGap),
                    _Section(child: _MonthCard(month: analytics.month)),
                    SizedBox(
                      height:
                          DoctorAnalyticsMetrics.screenH +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final DoctorWeekAnalytics week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(DoctorAnalyticsMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.doctorAnalyticsWeekTitle,
            rangeLabel:
                '${RuDates.dayMonth(week.from)}-${RuDates.dayMonth(week.to)}',
            onLightCard: true,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Total(
                appointments: week.stats.appointments,
                delta: week.stats.deltaVsUsual,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DoctorWeekBarChart(from: week.from, perDay: week.perDay),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.doctorAnalyticsWeekCardTitle,
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: 14),
                  _StatRow(stats: week.stats, onLightCard: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month});

  final DoctorMonthAnalytics month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.accentSofter,
      padding: const EdgeInsets.all(DoctorAnalyticsMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.doctorAnalyticsMonthCardTitle,
            // Без запятой, в отличие от карточки месяца в истории: так в
            // макете аналитики.
            rangeLabel: RuDates.monthAndYear(month.month).replaceFirst(',', ''),
            onLightCard: false,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Total(
                appointments: month.stats.appointments,
                delta: month.stats.deltaVsUsual,
              ),
              const SizedBox(width: 12),
              Expanded(child: DoctorMonthLineChart(perDay: month.perDay)),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(stats: month.stats, onLightCard: false),
        ],
      ),
    );
  }
}

/// Заголовок карточки с пейджером справа.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.rangeLabel,
    required this.onLightCard,
  });

  final String title;
  final String rangeLabel;
  final bool onLightCard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorAnalyticsMetrics.headerHeight,
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.sectionTitle)),
          const Icon(
            Icons.chevron_left,
            size: 18,
            color: AppColors.primaryBright,
          ),
          const SizedBox(width: 6),
          Text(
            rangeLabel,
            style: AppTypography.linkSmall.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryBright,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.primaryBright,
          ),
        ],
      ),
    );
  }
}

/// «7 записей» и плашка сравнения с обычным числом.
class _Total extends StatelessWidget {
  const _Total({required this.appointments, required this.delta});

  final int appointments;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.doctorAnalyticsAppointments(appointments),
            style: AppTypography.h2,
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allSm,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    delta < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 12,
                    // Тот же зелёный, что у нормы в шкале анализов: пипетка
                    // по макету даёт ровно #449D2B, отдельный токен заводить
                    // не под что.
                    color: AppColors.scaleNormal,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      delta < 0
                          ? l10n.doctorAnalyticsDeltaLess(delta.abs())
                          : l10n.doctorAnalyticsDeltaMore(delta),
                      style: AppTypography.tileSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Три плитки показателей в ряд.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats, required this.onLightCard});

  final DoctorWorkStats stats;
  final bool onLightCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: DoctorAnalyticsStatTile(
            value: l10n.doctorAnalyticsMinutes(stats.averageMinutes),
            label: l10n.doctorAnalyticsAverageLabel,
            onLightCard: onLightCard,
          ),
        ),
        const SizedBox(width: DoctorAnalyticsMetrics.statTileGap),
        Expanded(
          child: DoctorAnalyticsStatTile(
            value: stats.ratingDeltaLabel,
            label: l10n.doctorAnalyticsRatingLabel,
            onLightCard: onLightCard,
            showStar: true,
          ),
        ),
        const SizedBox(width: DoctorAnalyticsMetrics.statTileGap),
        Expanded(
          child: DoctorAnalyticsStatTile(
            value: stats.earningsPercentLabel,
            label: l10n.doctorAnalyticsEarningsLabel,
            onLightCard: onLightCard,
          ),
        ),
      ],
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
        horizontal: DoctorAnalyticsMetrics.screenH,
      ),
      child: child,
    );
  }
}
