import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../providers/registration_controller.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 1 регистрации — почта и пароль.
///
/// Свёрстан по `design/Создайте профиль.png`. Карточка здесь шире, чем на
/// логине (400 против 370), а поля ниже (59 против 66) — геометрия
/// у экранов разная, значения замерены отдельно.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// Заголовок 261…304 → карточка 354.
  static const double _titleToCard = 50;

  /// Карточка 354…587 → кнопка 631.
  static const double _cardToButton = 44;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(registrationControllerProvider.notifier);
    final state = ref.watch(registrationControllerProvider);

    return RegistrationStepLayout(
      progress: RegistrationProgress.credentials,
      title: 'Создайте профиль',
      children: [
        const SizedBox(height: _titleToCard),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            padding: RegistrationFormCard.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  hint: 'Введите Вашу почту',
                  height: AppTextField.compactFieldHeight,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  errorText: state.errorOf(RegField.email),
                  onChanged: (v) => controller.setField(RegField.email, v),
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                AppTextField(
                  hint: 'Придумайте пароль',
                  height: AppTextField.compactFieldHeight,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: state.errorOf(RegField.password),
                  onChanged: (v) => controller.setField(RegField.password, v),
                  suffix: _EyeToggle(
                    obscured: _obscurePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                AppTextField(
                  hint: 'Подтвердите пароль',
                  height: AppTextField.compactFieldHeight,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  errorText: state.errorOf(RegField.passwordConfirm),
                  onChanged: (v) =>
                      controller.setField(RegField.passwordConfirm, v),
                  onSubmitted: (_) => _next(),
                  suffix: _EyeToggle(
                    obscured: _obscureConfirm,
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: _cardToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: 'Далее',
            trailingIcon: Icons.arrow_forward,
            onPressed:
                state.filled(const [
                  RegField.email,
                  RegField.password,
                  RegField.passwordConfirm,
                ])
                ? _next
                : null,
          ),
        ),
      ],
    );
  }

  void _next() {
    if (ref.read(registrationControllerProvider.notifier).submitCredentials()) {
      context.push(Routes.personalData);
    }
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 22,
        color: AppColors.textSecondary,
      ),
      tooltip: obscured ? 'Показать пароль' : 'Скрыть пароль',
    );
  }
}
