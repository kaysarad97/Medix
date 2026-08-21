import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/registration_controller.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 1 регистрации — почта.
///
/// Свёрстан по `design/Создайте профиль.png`. Отличие от макета: полей
/// пароля нет — бэкенд паролей не хранит, вместо них на шаге 3 приходит
/// одноразовый код. Карточка из-за этого ниже, чем нарисовано.
///
/// Ссылка «Я — врач» под кнопкой — тоже вне макета: развилка на
/// врача-фрилансера есть в решениях HANDOFF (20 августа 2026), но сам PNG
/// с ней в рабочем дереве не сохранился. Форма ссылки взята с готового
/// образца — «или создать профиль» на `LoginScreen`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  /// Заголовок 261…304 → карточка 354.
  static const double _titleToCard = 50;

  /// Карточка 354…587 → кнопка 631.
  static const double _cardToButton = 44;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(registrationControllerProvider.notifier);
    final state = ref.watch(registrationControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return RegistrationStepLayout(
      progress: RegistrationProgress.credentials,
      title: l10n.createProfileTitle,
      children: [
        const SizedBox(height: _titleToCard),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            padding: RegistrationFormCard.padding,
            child: AppTextField(
              hint: l10n.emailHint,
              height: AppTextField.compactFieldHeight,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              errorText: state.errorOf(RegField.email),
              onChanged: (v) => controller.setField(RegField.email, v),
              onSubmitted: (_) => _next(),
            ),
          ),
        ),
        const SizedBox(height: _cardToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: l10n.nextButtonLabel,
            trailingIcon: Icons.arrow_forward,
            onPressed: state.filled(const [RegField.email]) ? _next : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: GestureDetector(
            onTap: () => context.push(Routes.doctorRegister),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.md,
              ),
              child: Text(
                l10n.registerAsDoctorAction,
                style: AppTypography.link,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _next() {
    if (ref.read(registrationControllerProvider.notifier).submitEmail()) {
      context.push(Routes.personalData);
    }
  }
}
