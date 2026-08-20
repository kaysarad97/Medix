import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_appointment_bucket.dart';
import '../widgets/doctor_calendar_day_strip.dart';
import '../widgets/doctor_calendar_metrics.dart';

/// Календарь на день — кабинет врача.
///
/// Свёрстан по `design/.../Календарь.png` (440×956) — один и тот же файл
/// в обоих комплектах макетов, экран общий для клиники и фрилансера.
///
/// Маршрут зарегистрирован отдельно от реального входа — см.
/// `DoctorHomeScreen` и HANDOFF.md, «Кабинет врача».
class DoctorCalendarScreen extends ConsumerWidget {
  const DoctorCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final appointments =
        ref.watch(doctorAppointmentsForDayProvider).value ??
        const <DoctorAppointment>[];

    final byPeriod = <DoctorDayPeriod, List<DoctorAppointment>>{
      for (final period in DoctorDayPeriod.values)
        period: [
          for (final a in appointments)
            if (a.period == period) a,
        ],
    };

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorCalendarMetrics.topBarToHeading),
              ScreenTopBar(
                title: l10n.upcomingAppointmentsTitle,
                onBack: () => Navigator.of(context).maybePop(),
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
                      .read(selectedCalendarDayProvider.notifier)
                      .select(day),
                  onPreviousWeek: () => ref
                      .read(selectedCalendarDayProvider.notifier)
                      .previousWeek(),
                  onNextWeek: () =>
                      ref.read(selectedCalendarDayProvider.notifier).nextWeek(),
                ),
              ),
              const SizedBox(height: DoctorCalendarMetrics.dayStripToBuckets),
              _Section(
                child: AppCard(
                  padding: const EdgeInsets.all(
                    DoctorCalendarMetrics.cardPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DoctorAppointmentBucket(
                        title: l10n.doctorCalendarMorningTitle,
                        appointments: byPeriod[DoctorDayPeriod.morning]!,
                      ),
                      const SizedBox(height: DoctorCalendarMetrics.bucketGap),
                      DoctorAppointmentBucket(
                        title: l10n.doctorCalendarAfternoonTitle,
                        appointments: byPeriod[DoctorDayPeriod.afternoon]!,
                      ),
                      const SizedBox(height: DoctorCalendarMetrics.bucketGap),
                      DoctorAppointmentBucket(
                        title: l10n.doctorCalendarEveningTitle,
                        appointments: byPeriod[DoctorDayPeriod.evening]!,
                      ),
                    ],
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
