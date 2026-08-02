import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../providers/profile_providers.dart';
import '../widgets/analyses_card.dart';
import '../widgets/medical_card_summary.dart';
import '../widgets/my_doctors_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_metrics.dart';
import '../widgets/section_header.dart';

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
                      title: 'Ваша Мед-Карта',
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
                    ProfileHeader(profile: profile),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MedicalCardSummary(
                        profile: profile,
                        now: now ?? DateTime.now(),
                        onOpen: () => context.push(Routes.medicalCardForm),
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(child: MyDoctorsCard(doctors: doctors)),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    const _Section(child: _ProceduresCard()),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    if (analyses.isNotEmpty)
                      _Section(
                        child: AnalysesCard(
                          analyses: analyses,
                          filter: filter,
                          onFilterChanged: ref
                              .read(analysesFilterProvider.notifier)
                              .select,
                        ),
                      ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                  ],
                ),
              ),
      ),
    );
  }
}

/// «Предыдущие процедуры» — карточка из одной строки-ссылки.
class _ProceduresCard extends StatelessWidget {
  const _ProceduresCard();

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
        title: 'Предыдущие процедуры',
        onTap: () {},
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
