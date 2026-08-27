import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/app_language.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_metrics.dart';

/// «Настройки» — свёрстан по `design/Настройки Клиента.png`.
///
/// Строки «Выйти из аккаунта» в макете нет — добавлена без референса:
/// раньше `AuthRepository.logout()` был реализован, но нигде не вызывался
/// (см. MED-62). Оформлена как обычный `_RowCard`, но красным текстом —
/// тем же токеном `AppColors.error`, что и кнопка «Удалить» в
/// `family_member_screen.dart`, а не новым цветом.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.onOpenProfileSettings,
    this.onOpenPaymentDetails,
    this.onOpenContacts,
    this.onCancelSubscription,
  });

  final VoidCallback? onOpenProfileSettings;
  final VoidCallback? onOpenPaymentDetails;
  final VoidCallback? onOpenContacts;
  final VoidCallback? onCancelSubscription;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _loggingOut = false;

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.logoutTitle,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    // logout() сам решает, что делать с ответом сервера: гасит refresh-токен
    // на бэкенде при удаче, а локальный выход всё равно доводит до конца в
    // `finally`, даже если сеть недоступна — исключение сюда не долетает.
    // Кэш профиля обнуляем явно: `profileProvider` не autoDispose и иначе
    // переживёт разлогин, показав следующему вошедшему чужие данные, если
    // тот войдёт без перезапуска приложения.
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // logout() не бросает ApiException в штатной работе (см. комментарий
      // выше), но контракт метода это не гарантирует — выходим локально в
      // любом случае, а не зависаем на середине.
    } finally {
      ref.invalidate(profileProvider);
    }
    if (!mounted) return;
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final profile = ref.watch(profileProvider).value;
    final l10n = AppLocalizations.of(context)!;

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
                title: l10n.settingsTitle,
                titleColor: AppColors.primaryBright,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 40),
              _Section(
                child: _RowCard(
                  onTap: widget.onOpenProfileSettings,
                  leading: UserAvatar(
                    asset: ref.watch(userAvatarProvider),
                    url: profile?.avatarUrl,
                    size: const Size.square(ProfileMetrics.settingsAvatarSize),
                    borderRadius: AppRadius.allSm,
                  ),
                  title: l10n.profileSettingsTitle,
                ),
              ),
              if (profile?.subscription != null &&
                  profile!.subscription != SubscriptionTier.free) ...[
                const SizedBox(height: ProfileMetrics.settingsGap),
                _Section(
                  child: _RowCard(
                    onTap: widget.onCancelSubscription,
                    title: l10n.cancelSubscriptionTitle,
                  ),
                ),
              ],
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
                        l10n.appLanguageLabel,
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
                  onTap: widget.onOpenPaymentDetails,
                  title: l10n.bankDetailsTitle,
                ),
              ),
              const SizedBox(height: ProfileMetrics.settingsGap),
              _Section(
                child: _RowCard(
                  onTap: widget.onOpenContacts,
                  title: l10n.contactUsTitle,
                ),
              ),
              const SizedBox(height: ProfileMetrics.settingsGap),
              _Section(
                child: _RowCard(
                  onTap: _loggingOut ? null : _confirmLogout,
                  title: l10n.logoutTitle,
                  titleColor: AppColors.error,
                  loading: _loggingOut,
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
  const _RowCard({
    required this.title,
    this.leading,
    this.onTap,
    this.titleColor,
    this.loading = false,
  });

  final String title;
  final Widget? leading;
  final VoidCallback? onTap;

  /// `null` — обычный цвет заголовка (`AppTypography.tileTitle`). Задаётся
  /// явно только для «опасных» строк вроде выхода из аккаунта.
  final Color? titleColor;

  /// Подменяет шеврон на спиннер того же размера, пока идёт асинхронное
  /// действие — тот же приём, что у `_CancelAppointmentButton` в кабинете
  /// врача (`doctor_patient_appointment_screen.dart`).
  final bool loading;

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
                    style: titleColor == null
                        ? AppTypography.tileTitle
                        : AppTypography.tileTitle.copyWith(color: titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (loading)
                  const SizedBox.square(
                    dimension: ProfileMetrics.chevronSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
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
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.notificationsLabel,
              style: AppTypography.tileTitle,
            ),
          ),
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
