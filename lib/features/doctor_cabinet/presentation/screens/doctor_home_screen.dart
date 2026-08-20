import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_action_tiles_card.dart';
import '../widgets/doctor_home_header.dart';
import '../widgets/doctor_home_metrics.dart';
import '../widgets/doctor_upcoming_appointments_card.dart';
import '../widgets/regular_patients_card.dart';

/// Главная кабинета врача.
///
/// Свёрстан по `design/для врача от клиники/Главная - в.ф.png` (440×1330).
/// У фрилансера тот же экран без плитки «Администрация» — макет
/// `design/врач прилансер/Главная - в.ф.png` отличается только этим,
/// см. [showAdminTile].
///
/// Маршрут зарегистрирован, но пока не связан с реальным входом — роли
/// пользователя в приложении ещё нет, см. HANDOFF.md.
class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key, this.showAdminTile = true});

  /// `false` у врача-фрилансера: своей администрации нет.
  final bool showAdminTile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appointments = ref.watch(doctorUpcomingAppointmentsProvider);
    final patients = ref.watch(doctorRegularPatientsProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorHomeMetrics.headerTop),
              DoctorHomeHeader(
                unreadCount: 2,
                onAvatarTap: () => context.push(Routes.doctorProfile),
              ),
              const SizedBox(height: DoctorHomeMetrics.headerToGreeting),
              _Section(
                child: Text(
                  l10n.doctorHomeGreeting('Имя Отчество'),
                  style: AppTypography.homeGreeting,
                ),
              ),
              const SizedBox(height: DoctorHomeMetrics.greetingToTiles),
              _Section(
                child: DoctorActionTilesCard(
                  scheduleTitle: l10n.doctorScheduleTileTitle,
                  scheduleSubtitle: l10n.doctorScheduleTileSubtitle,
                  historyTitle: l10n.doctorHistoryTileTitle,
                  historySubtitle: l10n.doctorHistoryTileSubtitle,
                  analyticsTitle: l10n.doctorAnalyticsTileTitle,
                  analyticsSubtitle: l10n.doctorAnalyticsTileSubtitle,
                  onSchedule: () => context.push(Routes.doctorCalendar),
                  onHistory: () => context.push(Routes.doctorHistory),
                  onAnalytics: () => context.push(Routes.doctorAnalytics),
                ),
              ),
              const SizedBox(height: DoctorHomeMetrics.cardGap),
              _Section(
                child: DoctorWideInfoTile(
                  title: l10n.doctorMessagesTileTitle,
                  subtitle: l10n.doctorMessagesTileSubtitle,
                  icon: MedixIcon.attachment,
                ),
              ),
              const SizedBox(height: DoctorHomeMetrics.cardGap),
              _Section(
                child: DoctorUpcomingAppointmentsCard(
                  appointments: appointments.value ?? const [],
                  onSeeAll: () => context.push(Routes.doctorCalendar),
                ),
              ),
              const SizedBox(height: DoctorHomeMetrics.cardGap),
              const _MediBotField(),
              const SizedBox(height: DoctorHomeMetrics.cardGap),
              _Section(
                child: RegularPatientsCard(
                  patients: patients.value ?? const [],
                  onPatientTap: (patient) =>
                      context.push(Routes.doctorPatientOf(patient.id)),
                ),
              ),
              if (showAdminTile) ...[
                const SizedBox(height: DoctorHomeMetrics.cardGap),
                _Section(
                  child: DoctorWideInfoTile(
                    title: l10n.doctorAdminTileTitle,
                    subtitle: l10n.doctorAdminTileSubtitle,
                    icon: MedixIcon.planFamily,
                    background: AppColors.surfaceInfo,
                  ),
                ),
              ],
              SizedBox(
                height:
                    DoctorHomeMetrics.cardGap +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Общие горизонтальные поля карточек — тот же приём, что на пациентской
/// главной.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorHomeMetrics.screenH,
      ),
      child: child,
    );
  }
}

/// Поле «Напишите Medi-bot...». Вести пока некуда — своего чат-экрана у
/// кабинета врача ещё нет, поле пока декоративное.
class _MediBotField extends StatelessWidget {
  const _MediBotField();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      child: SizedBox(
        height: DoctorHomeMetrics.mediBotFieldHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allPill,
          ),
          child: Row(
            children: [
              const SizedBox(width: 26),
              const AppIcon(icon: MedixIcon.chat, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.doctorMediBotHint,
                  style: AppTypography.placeholder,
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}
