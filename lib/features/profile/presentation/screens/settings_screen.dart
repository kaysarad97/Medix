import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../shared/models/app_language.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_metrics.dart';

/// «Настройки» — свёрстан по `design/Настройки Клиента.png`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.onOpenProfileSettings,
    this.onOpenPaymentDetails,
    this.onOpenContacts,
  });

  final VoidCallback? onOpenProfileSettings;
  final VoidCallback? onOpenPaymentDetails;
  final VoidCallback? onOpenContacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final profile = ref.watch(profileProvider).value;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              ScreenTopBar(
                title: 'Настройки',
                titleColor: AppColors.primaryBright,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 40),
              _Section(
                child: _RowCard(
                  onTap: onOpenProfileSettings,
                  leading: UserAvatar(
                    asset: profile?.avatarAsset,
                    url: profile?.avatarUrl,
                    size: const Size.square(ProfileMetrics.settingsAvatarSize),
                    borderRadius: AppRadius.allSm,
                  ),
                  title: 'Настройки профиля',
                ),
              ),
              const SizedBox(height: ProfileMetrics.settingsGap),
              _Section(
                child: AppCard(
                  borderRadius: ProfileMetrics.allRadius,
                  padding: const EdgeInsets.all(ProfileMetrics.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NotificationsRow(
                        enabled: settings.notificationsEnabled,
                        onChanged: notifier.toggleNotifications,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Язык приложения',
                        style: AppTypography.cardItemMeta,
                      ),
                      const SizedBox(height: 10),
                      _LanguageRow(
                        selected: settings.language,
                        onSelected: notifier.selectLanguage,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ProfileMetrics.settingsGap),
              _Section(
                child: _RowCard(
                  onTap: onOpenPaymentDetails,
                  title: 'Банковские данные',
                ),
              ),
              const SizedBox(height: ProfileMetrics.settingsGap),
              _Section(
                child: _RowCard(
                  onTap: onOpenContacts,
                  title: 'Свяжитесь с нами',
                ),
              ),
              const SizedBox(height: ProfileMetrics.settingsGap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка-строка с шевроном; необязательная картинка слева.
class _RowCard extends StatelessWidget {
  const _RowCard({required this.title, this.leading, this.onTap});

  final String title;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: ProfileMetrics.allRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: ProfileMetrics.settingsRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.tileTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const AppIcon(
                  icon: MedixIcon.chevronRight,
                  size: ProfileMetrics.chevronSize,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsRow extends StatelessWidget {
  const _NotificationsRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        children: [
          Expanded(child: Text('Уведомления', style: AppTypography.tileTitle)),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.surfaceWhite,
            activeTrackColor: AppColors.primaryBright,
            inactiveThumbColor: AppColors.surfaceWhite,
            inactiveTrackColor: AppColors.surfaceDisabled,
          ),
        ],
      ),
    );
  }
}

/// Три пилюли выбора языка с кружком-отметкой слева.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.selected, required this.onSelected});

  final AppLanguage? selected;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final language in AppLanguage.values) ...[
          if (language != AppLanguage.values.first)
            const SizedBox(width: ProfileMetrics.languagePillGap),
          Expanded(
            child: _LanguagePill(
              language: language,
              selected: language == selected,
              onTap: () => onSelected(language),
            ),
          ),
        ],
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceChip,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: ProfileMetrics.languagePillHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Mark(selected: selected),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  language.label,
                  style: AppTypography.chipLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return const SizedBox(
      width: 22,
      height: 22,
      child: Icon(Icons.check, size: 18, color: AppColors.primary),
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
