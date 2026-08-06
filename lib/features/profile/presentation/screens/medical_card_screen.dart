import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../shared/models/family_member.dart';
import '../../../family_access/presentation/providers/family_providers.dart';
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
    final family = ref.watch(familyMembersProvider).value ?? const [];

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
                    if (family.isNotEmpty) ...[
                      const SizedBox(height: ProfileMetrics.cardGap),
                      _Section(child: _FamilySwitcher(members: family)),
                    ],
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MedicalCardSummary(
                        topFieldValue: profile.iin,
                        topFieldPlaceholder: 'ИИН',
                        heightLabel: profile.heightLabel,
                        weightLabel: profile.weightLabel,
                        ageLabel: profile.ageLabel(now ?? DateTime.now()),
                        registrationAddress: profile.registrationAddress,
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
        onTap: () => context.push(Routes.procedures),
      ),
    );
  }
}

/// Переключатель «Моя семья» — своего макета нет ни у самой строки, ни у
/// перехода с главной; есть только карточки, на которые она ведёт
/// (`design/Моя Семья Ребенок.png`, `design/Моя Семья Старшие.png`).
/// Помещена под шапкой профиля как самое естественное место входа.
class _FamilySwitcher extends StatelessWidget {
  const _FamilySwitcher({required this.members});

  final List<FamilyMember> members;

  static const double _chipSize = 48;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Моя семья', style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        SizedBox(
          height: _chipSize + 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberChip(
                member: member,
                onTap: () => context.push(Routes.familyMemberOf(member.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member, required this.onTap});

  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            UserAvatar(
              asset: member.avatarAsset,
              size: const Size.square(_FamilySwitcher._chipSize),
            ),
            const SizedBox(height: 6),
            Text(
              member.firstName,
              style: AppTypography.cardItemMeta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: ProfileMetrics.screenH),
      child: child,
    );
  }
}
