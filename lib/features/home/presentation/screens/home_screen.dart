import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/family_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_access/presentation/providers/family_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/doctors_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_metrics.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/upcoming_appointments_card.dart';
import '../widgets/upload_analyses_card.dart';

/// Главный экран.
///
/// Свёрстан по `design/Главная.png` (440×1580 — коллаж, ниже основной
/// прокрутки наложены таб-бар и шторка переключения профиля семьи, это не
/// буквальная высота страницы).
///
/// Блок «Видео-инструкция» из макета не перенесён — решение подтверждено
/// заказчиком 2 августа 2026. Если когда-нибудь понадобится, он устроен так
/// же, как [UploadAnalysesCard], и добавляется одной строкой.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialties = ref.watch(specialtiesProvider);
    final appointments = ref.watch(upcomingAppointmentsProvider);
    final family = ref.watch(familyMembersProvider).value ?? const [];
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HomeMetrics.headerTop),
              HomeHeader(
                unreadCount: 2,
                // Вкладки нижней навигации переключаются через `go`: `push`
                // поднимает вторую копию оболочки, и навигатор падает на
                // повторных глобальных ключах.
                onAvatarTap: () => context.go(Routes.profile),
              ),
              const SizedBox(height: HomeMetrics.headerToGreeting),
              _Section(
                child: Text(
                  l10n.homeGreeting,
                  style: AppTypography.homeGreeting,
                ),
              ),
              const SizedBox(height: HomeMetrics.greetingToSearch),
              const _SymptomSearchField(),
              const SizedBox(height: HomeMetrics.searchToActions),
              _Section(
                child: QuickActionsCard(
                  // «Сдать анализы» — каталог анализов с ценами, а не бот:
                  // это прямое действие, а не диалог. Бот остаётся доступен
                  // через поиск симптомов и «Загрузить анализы» ниже.
                  onLabTests: () => context.push(Routes.labServices),
                  onMessages: () => context.go(Routes.chats),
                  // Быстрый переход сразу к записи, в отличие от карусели
                  // специальностей ниже — там сначала список врачей.
                  onDoctorAppointment: () =>
                      context.push(Routes.doctorOf('d1')),
                  onFindFacility: () => context.go(Routes.mapSearch),
                ),
              ),
              const SizedBox(height: HomeMetrics.cardGap),
              _Section(
                child: DoctorsCard(
                  specialties: specialties.value ?? const [],
                  onSeeAll: () => context.push(Routes.doctorSearch),
                  onSpecialtyTap: (specialty) => context.push(
                    Routes.doctorSearchResultsOf(specialty.title),
                  ),
                ),
              ),
              const SizedBox(height: HomeMetrics.cardGap),
              _Section(
                child: UploadAnalysesCard(
                  onTap: () => context.push(Routes.chatbot),
                ),
              ),
              if (family.isNotEmpty) ...[
                const SizedBox(height: HomeMetrics.cardGap),
                _Section(
                  child: FamilyCard(
                    members: family,
                    title: l10n.familyScreenTitle,
                    // На главной строка — вход в чужой профиль, а не сведения
                    // о человеке: «Профиль для ребенка» вместо имени.
                    rowStyle: FamilyRowStyle.entry,
                    onMemberTap: (member) =>
                        context.push(Routes.familyMemberOf(member.id)),
                  ),
                ),
              ],
              const SizedBox(height: HomeMetrics.cardGap),
              _Section(
                child: UpcomingAppointmentsCard(
                  appointments: appointments.value ?? const [],
                  onAppointmentTap: (appointment) =>
                      context.push(Routes.appointmentOf(appointment.id)),
                ),
              ),
              // Плавающий таб-бар накрывает низ экрана: его высоту AppShell
              // кладёт в нижний отступ MediaQuery, и последняя карточка
              // должна на неё подняться.
              SizedBox(
                height:
                    HomeMetrics.cardGap + MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Общие горизонтальные поля карточек.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeMetrics.screenH),
      child: child,
    );
  }
}

class _SymptomSearchField extends StatelessWidget {
  const _SymptomSearchField();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      child: SizedBox(
        height: HomeMetrics.searchHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allPill,
          ),
          child: Row(
            children: [
              // Замер по `design/Главная.png`: краска облачка 19×19,
              // начинается на x 47 при поле с x 21.
              const SizedBox(width: 26),
              const AppIcon(icon: MedixIcon.symptomSearch, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: TextField(
                    // Здесь не печатают: плейсхолдер тот же, что у бота, и
                    // строка работает как вход в переписку с ним.
                    readOnly: true,
                    onTap: () => context.push(Routes.chatbot),
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: l10n.symptomSearchHint,
                      hintStyle: AppTypography.placeholder,
                    ),
                  ),
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
