import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/family_member.dart';
import '../../../profile/presentation/widgets/analyses_card.dart';
import '../../../profile/presentation/widgets/medical_card_summary.dart';
import '../../../profile/presentation/widgets/my_doctors_card.dart';
import '../../../profile/presentation/widgets/profile_metrics.dart';
import '../providers/family_providers.dart';

/// Карточка члена семьи — «Моя Семья».
///
/// Свёрстан по `design/Моя Семья Ребенок.png` и `design/Моя Семья
/// Старшие.png`: один экран на оба макета, различие только в подписях
/// ([FamilyMember.doctorsCardTitle], [FamilyMember.analysesCardTitle]) и
/// аватаре. Верхняя строка проще, чем на «Ваша Мед-Карта»: без шестерёнки
/// настроек и без значка Gold — у члена семьи нет ни того, ни другого.
///
/// Карточки «Мед-карта», «Врачи…» и «Анализы…» — те же виджеты, что и на
/// экране пользователя (`MedicalCardSummary`, `MyDoctorsCard`,
/// `AnalysesCard`), с другими подписями и данными.
class FamilyMemberScreen extends ConsumerWidget {
  const FamilyMemberScreen({super.key, required this.memberId, this.now});

  final String memberId;

  /// Подменяется в тестах: возраст в карточке считается от сегодняшнего дня.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyMemberProvider(memberId)).value;
    final doctors =
        ref.watch(familyDoctorsProvider(memberId)).value ?? const [];
    final analyses =
        ref.watch(familyAnalysesProvider(memberId)).value ?? const [];
    final filter = ref.watch(familyAnalysesFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: member == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 36),
                    ScreenTopBar(
                      title: l10n.familyScreenTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: ProfileMetrics.topBarToHeader),
                    _MemberHeader(member: member),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MedicalCardSummary(
                        topFieldValue: member.relationshipLabel,
                        topFieldPlaceholder: l10n.relationshipPlaceholder,
                        heightLabel: member.heightLabel,
                        weightLabel: member.weightLabel,
                        ageLabel: member.ageLabel(now ?? DateTime.now()),
                        registrationAddress: member.registrationAddress,
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MyDoctorsCard(
                        doctors: doctors,
                        title: member.doctorsCardTitle,
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    if (analyses.isNotEmpty)
                      _Section(
                        child: AnalysesCard(
                          analyses: analyses,
                          filter: filter,
                          title: member.analysesCardTitle,
                          onFilterChanged: ref
                              .read(familyAnalysesFilterProvider.notifier)
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

/// Шапка: аватар, имя, пол и дата рождения. В отличие от `ProfileHeader` —
/// без значка Gold: подписка привязана к аккаунту, а не к члену семьи.
class _MemberHeader extends StatelessWidget {
  const _MemberHeader({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: ProfileMetrics.avatarLeft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            asset: member.avatarAsset,
            size: ProfileMetrics.avatarSize,
            borderRadius: BorderRadius.circular(ProfileMetrics.avatarRadius),
          ),
          const SizedBox(width: ProfileMetrics.avatarToInfo),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(member.firstName, style: AppTypography.profileName),
                Text(member.lastName, style: AppTypography.profileName),
                const SizedBox(height: ProfileMetrics.nameToMeta),
                Row(
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        value: member.gender.label,
                        label: l10n.genderLabel,
                      ),
                    ),
                    Expanded(
                      child: _MetaColumn(
                        value: member.birthDateLabel,
                        label: l10n.birthDateLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: ProfileMetrics.screenH),
        ],
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTypography.profileMetaValue),
        const SizedBox(height: ProfileMetrics.metaValueToLabel),
        Text(label, style: AppTypography.profileMetaLabel),
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
      padding: const EdgeInsets.symmetric(horizontal: ProfileMetrics.screenH),
      child: child,
    );
  }
}
