import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../providers/registration_controller.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 2 регистрации — ИИН, ФИО и телефон.
///
/// Свёрстан по `design/Ваши Данные.png`. Геометрия карточки и кнопки
/// совпадает с шагом 1.
class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends ConsumerState<PersonalDataScreen> {
  /// Заголовок 261…304 → карточка 354.
  static const double _titleToCard = 50;

  /// Карточка 354…587 → кнопка 631.
  static const double _cardToButton = 44;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(registrationControllerProvider.notifier);
    final state = ref.watch(registrationControllerProvider);

    ref.listen(registrationControllerProvider, (previous, next) {
      final error = next.formError;
      if (error != null && error != previous?.formError) {
        showFormErrorSnackBar(context, error);
        controller.formErrorShown();
      }
    });

    return RegistrationStepLayout(
      progress: RegistrationProgress.personalData,
      title: 'Ваши данные',
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
                  hint: 'ИИН',
                  height: AppTextField.compactFieldHeight,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: AppConstants.iinLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: state.errorOf(RegField.iin),
                  onChanged: (v) => controller.setField(RegField.iin, v),
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                AppTextField(
                  hint: 'ФИО',
                  height: AppTextField.compactFieldHeight,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  errorText: state.errorOf(RegField.fullName),
                  onChanged: (v) => controller.setField(RegField.fullName, v),
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                AppTextField(
                  hint: 'Номер телефона',
                  height: AppTextField.compactFieldHeight,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  errorText: state.errorOf(RegField.phone),
                  onChanged: (v) => controller.setField(RegField.phone, v),
                  onSubmitted: (_) => _next(),
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
            isLoading: state.isSubmitting,
            onPressed:
                state.filled(const [
                  RegField.iin,
                  RegField.fullName,
                  RegField.phone,
                ])
                ? _next
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _next() async {
    final ok = await ref
        .read(registrationControllerProvider.notifier)
        .submitPersonalData();
    if (ok && mounted) context.push(Routes.verifyCode);
  }
}
