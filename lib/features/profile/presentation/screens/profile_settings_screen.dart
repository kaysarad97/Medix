import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_metrics.dart';

/// «Настройки профиля» — свёрстан по `design/Настройки Профиля.png`.
///
/// Поля в макете показаны пустыми, с подсказками вместо значений. Данные
/// профиля подставляются в них как начальный текст: пустая форма поверх
/// заполненного аккаунта выглядела бы как потеря данных.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key, this.onChangeAvatar});

  final VoidCallback? onChangeAvatar;

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  var _prefilled = false;
  var _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Сохраняет и закрывает экран по стрелке назад — другого способа
  /// подтвердить правку в макете нет: ни кнопки «Сохранить», ни галочки в
  /// шапке (см. `design/Настройки Профиля.png`). Почта не отправляется —
  /// `PATCH /users/me` её не принимает, это логин, а не редактируемое поле;
  /// поле в форме остаётся для чтения текущего значения, как и было.
  Future<void> _close() async {
    if (_saving) return;

    final profile = ref.read(profileProvider).value;
    final firstName = _first.text.trim();
    final lastName = _last.text.trim();
    final changed =
        profile != null &&
        (firstName != profile.firstName || lastName != profile.lastName);
    if (!changed) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveProfile(
            UserProfile(
              id: profile.id,
              firstName: firstName,
              lastName: lastName,
              subscription: profile.subscription,
              gender: profile.gender,
              birthDate: profile.birthDate,
              email: profile.email,
              iin: profile.iin,
              registrationAddress: profile.registrationAddress,
              heightCm: profile.heightCm,
              weightKg: profile.weightKg,
              avatarUrl: profile.avatarUrl,
              avatarAsset: profile.avatarAsset,
            ),
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showFormErrorSnackBar(context, e.message);
      return;
    }

    ref.invalidate(profileProvider);
    if (!mounted) return;
    if (!await Navigator.of(context).maybePop() && mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile != null && !_prefilled) {
      _prefilled = true;
      _first.text = profile.firstName;
      _last.text = profile.lastName;
      _email.text = profile.email ?? '';
    }
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.auth,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              ScreenTopBar(
                title: l10n.profileSettingsTitle,
                onBack: () => _close(),
              ),
              const SizedBox(height: 30),
              Center(
                child: UserAvatar(
                  asset: ref.watch(userAvatarProvider),
                  url: profile?.avatarUrl,
                  size: ProfileMetrics.profileAvatarSize,
                  borderRadius: BorderRadius.circular(
                    ProfileMetrics.avatarRadius,
                  ),
                  onTap: widget.onChangeAvatar,
                ),
              ),
              const SizedBox(height: ProfileMetrics.profileAvatarToCaption),
              GestureDetector(
                onTap: widget.onChangeAvatar,
                child: Text(
                  l10n.changeAvatarLink,
                  textAlign: TextAlign.center,
                  style: AppTypography.captionMuted,
                ),
              ),
              const SizedBox(height: ProfileMetrics.captionToForm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProfileMetrics.screenH,
                ),
                child: AppCard(
                  borderRadius: ProfileMetrics.allRadius,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Field(
                        controller: _first,
                        hint: l10n.firstNameHint,
                        enabled: !_saving,
                      ),
                      const SizedBox(height: ProfileMetrics.formFieldGap),
                      _Field(
                        controller: _last,
                        hint: l10n.lastNameHint,
                        enabled: !_saving,
                      ),
                      const SizedBox(height: ProfileMetrics.formFieldGap),
                      // Поля пароля здесь нет: паролей в MedIx нет вообще,
                      // вход идёт по одноразовому коду на эту самую почту.
                      // Почта в `_close` не отправляется — `PATCH /users/me`
                      // её не принимает; поле остаётся редактируемым, чтобы
                      // не менять вид формы без дизайнера, но правка тут
                      // молча не сохранится, как и раньше у всех полей.
                      _Field(
                        controller: _email,
                        hint: 'E-mail',
                        enabled: !_saving,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.formFieldHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: AppTypography.bodyMd,
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.placeholder.copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
