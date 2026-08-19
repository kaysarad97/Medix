import '../../../../shared/models/subscription_tier.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_metrics.dart';

/// Шапка экрана «Ваша Мед-Карта»: аватар, имя, пол с датой рождения
/// и значок подписки.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.avatarAsset,
    this.onAvatarTap,
  });

  final UserProfile profile;

  /// Что показать вместо картинки из профиля — выбор пользователя на
  /// экране «Выбор аватарки». Пусто, пока он ничего не выбирал.
  final String? avatarAsset;

  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: ProfileMetrics.avatarLeft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            asset: avatarAsset ?? profile.avatarAsset,
            url: profile.avatarUrl,
            size: ProfileMetrics.avatarSize,
            borderRadius: BorderRadius.circular(ProfileMetrics.avatarRadius),
            onTap: onAvatarTap,
          ),
          const SizedBox(width: ProfileMetrics.avatarToInfo),
          Expanded(child: _Info(profile: profile)),
          _SubscriptionBadge(tier: profile.subscription),
          const SizedBox(width: ProfileMetrics.screenH),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. Имя в макете набрано курсивом,
        // а Golos Text подключён вариативным файлом с единственной осью
        // `wght` — курсивного начертания в нём нет, и Flutter его не
        // синтезирует. Рисуем прямым; либо дизайнер отказывается от
        // курсива, либо нужен отдельный файл с наклоном.
        Text(profile.firstName, style: AppTypography.profileName),
        Text(profile.lastName, style: AppTypography.profileName),
        const SizedBox(height: ProfileMetrics.nameToMeta),
        // Колонки в макете разведены на 140, но это ширина макета: вместе
        // с аватаром и значком подписки фиксированный зазор не помещается
        // на 440. Делим остаток поровну — расстояние выходит близким, а на
        // узких экранах вёрстка не рвётся.
        Row(
          children: [
            Expanded(
              child: _MetaColumn(
                value: profile.genderLabel,
                label: l10n.genderLabel,
              ),
            ),
            Expanded(
              child: _MetaColumn(
                value: profile.birthDateLabel,
                label: l10n.birthDateLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Значение сверху, подпись под ним — так в макете, а не наоборот.
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

class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge({required this.tier});

  final SubscriptionTier tier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Ромб в макете на 199, то есть на 18 ниже верхней кромки аватара.
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            icon: MedixIcon.subscriptionBadge,
            size: ProfileMetrics.badgeIconSize,
            color: AppColors.gold,
          ),
          const SizedBox(height: ProfileMetrics.badgeIconToLabel),
          Text(tier.label, style: AppTypography.subscriberLabel),
        ],
      ),
    );
  }
}
