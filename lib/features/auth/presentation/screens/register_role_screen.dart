import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/registration_step_layout.dart';

/// Выбор роли перед регистрацией — «Я — клиент» / «Я — врач».
///
/// Свёрстан по `design/врач фрилансер/Логин Выбор.png`. Раньше развилка на
/// врача-фрилансера была текстовой ссылкой под кнопкой на [RegisterScreen]
/// (macet для неё тогда отсутствовал — см. HANDOFF, «Восьмой заход»); макет
/// нашёлся и рисует выбор роли как отдельный первый шаг, а не довесок к
/// шагу почты. Ссылка с `RegisterScreen` убрана — теперь это единственная
/// точка входа в обе ветки.
class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  static const double _buttonsTop = 32;
  static const double _buttonGap = 16;
  static const double _buttonHeight = 61;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RegistrationStepLayout(
      progress: RegistrationProgress.roleChoice,
      title: l10n.createProfileTitle,
      children: [
        const SizedBox(height: _buttonsTop),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            children: [
              _RolePill(
                label: l10n.registerAsPatientAction,
                background: AppColors.surfaceWhite,
                textColor: AppColors.textPrimary,
                onTap: () => context.push(Routes.register),
              ),
              const SizedBox(height: _buttonGap),
              _RolePill(
                label: l10n.registerAsDoctorAction,
                background: AppColors.primaryBright,
                textColor: AppColors.textOnPrimary,
                onTap: () => context.push(Routes.doctorRegister),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RegisterRoleScreen._buttonHeight,
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppTypography.buttonMd.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
