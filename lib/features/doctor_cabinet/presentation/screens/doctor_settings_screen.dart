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
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/app_language.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_profile_link_row.dart';
import '../widgets/doctor_profile_metrics.dart';

/// «Настройки» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Настройки Врач.png`. Тот же
/// набор строк, что и у пациентских настроек (`SettingsScreen` в
/// `features/profile`); форма карточек не импортируется оттуда, та лежит
/// в чужой фиче (см. `DoctorProfileLinkRow`).
///
/// У врача-фрилансера сверху добавляются «Настройки профиля» и
/// «Банковские данные» — см. [showFreelancerRows] и
/// `design/врач фрилансер/Настройки Врач.png`: своими данными фрилансер
/// управляет сам, а у врача от клиники это делает администрация, поэтому
/// строк нет вовсе, а не показаны пустыми.
///
/// Провайдер настроек общий с пациентским экраном
/// ([appSettingsProvider] из `shared/providers`) — язык и уведомления
/// одни на всё приложение, а не по одному набору на роль.
///
/// Строки «Выйти из аккаунта» в макете нет, добавлена по тому же поводу и
/// с тем же оформлением, что и у пациента — см. `SettingsScreen` в
/// `features/profile` (MED-62).
class DoctorSettingsScreen extends ConsumerStatefulWidget {
  const DoctorSettingsScreen({super.key, this.showFreelancerRows});

  /// `true` у врача-фрилансера — показывает «Настройки профиля» и
  /// «Банковские данные».
  /// `null` определяет вид настроек по серверному профилю врача.
  final bool? showFreelancerRows;

  @override
  ConsumerState<DoctorSettingsScreen> createState() =>
      _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends ConsumerState<DoctorSettingsScreen> {
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
    // Те же причины, что у пациентского экрана: locally-успешный logout()
    // не зависит от сети, а doctorOwnProfileProvider не autoDispose — без
    // явного invalidate следующий вошедший врач увидит чужой кэш.
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // См. комментарий в SettingsScreen.
    } finally {
      ref.invalidate(doctorOwnProfileProvider);
    }
    if (!mounted) return;
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final profile = widget.showFreelancerRows == null
        ? ref.watch(doctorOwnProfileProvider).value
        : null;
    final shouldShowFreelancerRows =
        widget.showFreelancerRows ?? (profile?.isFreelancer ?? false);

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
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 40),
              if (shouldShowFreelancerRows) ...[
                _Section(
                  child: DoctorProfileLinkRow(
                    icon: MedixIcon.userAvatar,
                    title: l10n.profileSettingsTitle,
                    onTap: () => context.push(Routes.doctorProfileSettings),
                  ),
                ),
                const SizedBox(height: DoctorProfileMetrics.linkRowGap),
              ],
              _Section(
                child: AppCard(
                  borderRadius: _radius,
                  padding: const EdgeInsets.all(
                    DoctorProfileMetrics.cardPadding,
                  ),
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
              if (shouldShowFreelancerRows) ...[
                const SizedBox(height: DoctorProfileMetrics.linkRowGap),
                _Section(
                  child: _RowCard(
                    title: l10n.bankDetailsTitle,
                    onTap: () => context.push(Routes.doctorBankDetails),
                  ),
                ),
              ],
              const SizedBox(height: DoctorProfileMetrics.linkRowGap),
              _Section(
                child: _RowCard(
                  title: l10n.contactUsTitle,
                  onTap: () => context.push(Routes.contacts),
                ),
              ),
              const SizedBox(height: DoctorProfileMetrics.linkRowGap),
              _Section(
                child: _RowCard(
                  title: l10n.logoutTitle,
                  titleColor: AppColors.error,
                  loading: _loggingOut,
                  onTap: _loggingOut ? null : _confirmLogout,
                ),
              ),
              SizedBox(
                height:
                    DoctorProfileMetrics.linkRowGap +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

/// Строка-переключатель уведомлений — та же форма, что у пациентских
/// настроек.
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
          if (language != AppLanguage.values.first) const SizedBox(width: 12),
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
          height: 48,
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

/// Карточка-строка с шевроном, без иконки слева — «Свяжитесь с нами».
class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.title,
    this.onTap,
    this.titleColor,
    this.loading = false,
  });

  final String title;
  final VoidCallback? onTap;

  /// `null` — обычный цвет заголовка. Задаётся явно только для «опасных»
  /// строк вроде выхода из аккаунта (см. `SettingsScreen` в `features/profile`).
  final Color? titleColor;

  /// Подменяет шеврон на спиннер того же размера на время асинхронного
  /// действия — как у `_CancelAppointmentButton` в
  /// `doctor_patient_appointment_screen.dart`.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: _radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: DoctorProfileMetrics.linkRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
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
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const AppIcon(
                    icon: MedixIcon.chevronRight,
                    size: 14,
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

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorProfileMetrics.screenH,
      ),
      child: child,
    );
  }
}
