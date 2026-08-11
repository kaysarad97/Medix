import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/family_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../../family_access/presentation/providers/family_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/analyses_card.dart';

import '../widgets/medical_card_summary.dart';
import '../widgets/my_doctors_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_metrics.dart';

/// Профиль пользователя — «Ваша Мед-Карта».
///
/// Свёрстан по `design/Профиль.png` (440×1511 — страница прокручиваемая).
class MedicalCardScreen extends ConsumerWidget {
  const MedicalCardScreen({super.key, this.now});

  /// Подменяется в тестах: возраст в карточке считается от сегодняшнего дня,
  /// иначе эталон протухнет в ближайший день рождения.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final doctors = ref.watch(myDoctorsProvider).value ?? const [];
    final analyses = ref.watch(analysesProvider).value ?? const [];
    final filter = ref.watch(analysesFilterProvider);
    final family = ref.watch(familyMembersProvider).value ?? const [];
    final l10n = AppLocalizations.of(context)!;

    // Семейный доступ входит в Gold. Без подписки обе ссылки «Моей Семьи»
    // ведут на экран тарифов — там цены и что даёт подписка.
    final isGold = profile?.subscription == SubscriptionTier.gold;
    const gate = Routes.subscription;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: profile == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 36),
                    ScreenTopBar(
                      title: l10n.yourMedicalCardTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: GestureDetector(
                        onTap: () => context.push(Routes.settings),
                        child: const AppIcon(
                          icon: MedixIcon.settings,
                          size: 22,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.topBarToHeader),
                    ProfileHeader(
                      profile: profile,
                      avatarAsset: ref.watch(userAvatarProvider),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MedicalCardSummary(
                        // Раньше здесь был ИИН. Его больше нет ни в профиле,
                        // ни на бэкенде, а почта — то, по чему аккаунт
                        // опознаётся при входе.
                        topFieldValue: profile.email,
                        topFieldPlaceholder: 'E-mail',
                        heightLabel: profile.heightLabel,
                        weightLabel: profile.weightLabel,
                        ageLabel: profile.ageLabel(now ?? DateTime.now()),
                        registrationAddress: profile.registrationAddress,
                        onOpen: () => context.push(Routes.medicalCardForm),
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MyDoctorsCard(
                        doctors: doctors,
                        title: l10n.myDoctorsTitle,
                      ),
                    ),
                    // Карточка рисуется и с пустым списком, в отличие от
                    // главной: это единственный вход в «Мою Семью», и без
                    // неё добавить первого близкого было бы неоткуда.
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: FamilyCard(
                        members: family,
                        title: l10n.familyScreenTitle,
                        // Шеврон в заголовке ведёт на список целиком —
                        // там же добавление. Так устроены и остальные
                        // карточки этого экрана: «Мед-карта», «Предыдущие
                        // процедуры», «Ваши анализы». В макете это место
                        // закрыто наложенным таб-баром, свериться не с чем.
                        //
                        // Обе ссылки под подпиской, как на главной: семейный
                        // доступ входит в Gold, и без него оба пути ведут на
                        // экран тарифов. Раньше строка участника отсюда
                        // открывалась без проверки — обход платного раздела
                        // в обход собственной же двери на главной.
                        onTitleTap: () =>
                            context.push(isGold ? Routes.family : gate),
                        onMemberTap: (member) => context.push(
                          isGold ? Routes.familyMemberOf(member.id) : gate,
                        ),
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: _ProceduresCard(
                        title: l10n.previousProceduresTitle,
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    if (analyses.isNotEmpty)
                      _Section(
                        child: AnalysesCard(
                          analyses: analyses,
                          filter: filter,
                          title: l10n.yourAnalysesTitle,
                          onFilterChanged: ref
                              .read(analysesFilterProvider.notifier)
                              .select,
                        ),
                      ),
                    // Высоту плавающего таб-бара AppShell кладёт в нижний
                    // отступ MediaQuery — без него карточка анализов уедет
                    // под таблетку.
                    SizedBox(
                      height:
                          ProfileMetrics.cardGap +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// «Предыдущие процедуры» — карточка из одной строки-ссылки.
class _ProceduresCard extends StatelessWidget {
  const _ProceduresCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: ProfileMetrics.allRadius,
      padding: const EdgeInsets.symmetric(
        horizontal: ProfileMetrics.cardPadding,
        vertical: 8,
      ),
      child: SectionHeader(
        icon: MedixIcon.procedures,
        title: title,
        onTap: () => context.push(Routes.procedures),
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
      padding: const EdgeInsets.symmetric(horizontal: ProfileMetrics.screenH),
      child: child,
    );
  }
}
