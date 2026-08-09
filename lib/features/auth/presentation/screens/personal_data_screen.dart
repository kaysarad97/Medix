import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/registration_controller.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 2 регистрации — ФИО и дата рождения.
///
/// Свёрстан по `design/Ваши Данные.png`. Отличия от макета: ИИН и телефон
/// убраны (бэкенд их не хранит), вместо них дата рождения — без неё
/// регистрация на сервере не проходит.
///
/// Именно на этом шаге создаётся заявка и уходит письмо с кодом: раньше
/// нельзя — серверу нужны сразу почта, имя и дата рождения.
class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends ConsumerState<PersonalDataScreen> {
  final _birthDateController = TextEditingController();

  /// Заголовок 261…304 → карточка 354.
  static const double _titleToCard = 50;

  /// Карточка 354…587 → кнопка 631.
  static const double _cardToButton = 44;

  /// Разумная отправная точка календаря: совершеннолетний пользователь.
  /// Открывать его на сегодняшнем дне — значит заставить прокрутить
  /// несколько десятилетий назад.
  static const int _defaultAgeYears = 30;

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

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

    final l10n = AppLocalizations.of(context)!;
    return RegistrationStepLayout(
      progress: RegistrationProgress.personalData,
      title: l10n.personalDataTitle,
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
                  hint: l10n.fullNameHint,
                  height: AppTextField.compactFieldHeight,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  errorText: state.errorOf(RegField.fullName),
                  onChanged: (v) => controller.setField(RegField.fullName, v),
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                // Дата выбирается календарём, руками не вводится: формат
                // «ГГГГ-ММ-ДД», который ждёт сервер, набирать вслепую неудобно
                // и легко ошибиться. AbsorbPointer гасит фокус у поля, чтобы
                // вместо клавиатуры открывался календарь.
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: AbsorbPointer(
                    child: AppTextField(
                      hint: l10n.birthDateHint,
                      height: AppTextField.compactFieldHeight,
                      controller: _birthDateController,
                      errorText: state.errorOf(RegField.birthDate),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: _cardToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: l10n.nextButtonLabel,
            trailingIcon: Icons.arrow_forward,
            isLoading: state.isSubmitting,
            onPressed:
                state.filled(const [RegField.fullName, RegField.birthDate])
                ? _next
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(
      ref.read(registrationControllerProvider).value(RegField.birthDate),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate:
          current ?? DateTime(now.year - _defaultAgeYears, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    // В состоянии храним формат сервера, в поле показываем привычный.
    ref
        .read(registrationControllerProvider.notifier)
        .setField(RegField.birthDate, '${picked.year}-$month-$day');
    _birthDateController.text = '$day.$month.${picked.year}';
  }

  Future<void> _next() async {
    final ok = await ref
        .read(registrationControllerProvider.notifier)
        .submitPersonalData();
    if (ok && mounted) context.push(Routes.verifyCode);
  }
}
