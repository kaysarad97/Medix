import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
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
  final _password = TextEditingController();
  var _prefilled = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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
                title: 'Настройки профиля',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 30),
              Center(child: _Avatar(url: profile?.avatarUrl)),
              const SizedBox(height: ProfileMetrics.profileAvatarToCaption),
              GestureDetector(
                onTap: widget.onChangeAvatar,
                child: Text(
                  'изменить аватара',
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
                      _Field(controller: _first, hint: 'Имя'),
                      const SizedBox(height: ProfileMetrics.formFieldGap),
                      _Field(controller: _last, hint: 'Фамилия'),
                      const SizedBox(height: ProfileMetrics.formFieldGap),
                      _Field(controller: _email, hint: 'E-mail'),
                      const SizedBox(height: ProfileMetrics.formFieldGap),
                      _Field(
                        controller: _password,
                        hint: 'Пароль',
                        obscure: true,
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProfileMetrics.profileAvatarSize.width,
      height: ProfileMetrics.profileAvatarSize.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ProfileMetrics.avatarRadius),
        child: url == null
            ? const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.accentSoft),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;

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
              obscureText: obscure,
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
