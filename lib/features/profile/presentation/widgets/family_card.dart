import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/family_member.dart';
import 'profile_metrics.dart';
import 'section_header.dart';

/// «Моя Семья» на экране «Ваша Мед-Карта»: список профилей близких.
///
/// Свёрстана по `design/Профиль - GOLD.png` — карточка идёт сразу за «Мои
/// Врачи». Строка на каждого: круглый аватар, имя и синяя подпись, кем он
/// приходится владельцу аккаунта.
///
/// Раньше на этом месте стоял горизонтальный переключатель с кружками —
/// макета на него не было, и он не совпал с присланным.
class FamilyCard extends StatelessWidget {
  const FamilyCard({
    super.key,
    required this.members,
    required this.title,
    this.onMemberTap,
  });

  final List<FamilyMember> members;
  final String title;
  final ValueChanged<FamilyMember>? onMemberTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: ProfileMetrics.allRadius,
      padding: const EdgeInsets.all(ProfileMetrics.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(icon: MedixIcon.family, title: title),
          for (final member in members) ...[
            const SizedBox(height: ProfileMetrics.familyRowGap),
            _MemberRow(
              member: member,
              onTap: onMemberTap == null ? null : () => onMemberTap!(member),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, this.onTap});

  final FamilyMember member;
  final VoidCallback? onTap;

  /// Кем участник приходится владельцу аккаунта — подпись под именем.
  static String _roleLabel(FamilyRelation relation, AppLocalizations l10n) =>
      switch (relation) {
        FamilyRelation.child => l10n.familyRoleChild,
        FamilyRelation.senior => l10n.familyRoleSenior,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: ProfileMetrics.familyRowHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: ProfileMetrics.allRadius,
          ),
          child: Row(
            children: [
              const SizedBox(width: ProfileMetrics.familyAvatarLeft),
              UserAvatar(
                asset: member.avatarAsset,
                size: const Size.square(ProfileMetrics.familyAvatarSize),
              ),
              const SizedBox(width: ProfileMetrics.familyAvatarToText),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: AppTypography.cardItemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: ProfileMetrics.familyNameToRole),
                    Text(
                      _roleLabel(member.relation, l10n),
                      style: AppTypography.tileSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ProfileMetrics.familyAvatarLeft),
            ],
          ),
        ),
      ),
    );
  }
}
