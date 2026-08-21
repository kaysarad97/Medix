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
import '../providers/doctor_registration_controller.dart';
import '../widgets/registration_step_layout.dart';

class DoctorRegisterScreen extends ConsumerStatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  ConsumerState<DoctorRegisterScreen> createState() =>
      _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends ConsumerState<DoctorRegisterScreen> {
  final _birthDateController = TextEditingController();

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorRegistrationControllerProvider);
    final controller = ref.read(doctorRegistrationControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    ref.listen(doctorRegistrationControllerProvider, (previous, next) {
      if (next.formError != null && next.formError != previous?.formError) {
        showFormErrorSnackBar(context, next.formError!);
        controller.formErrorShown();
      }
    });

    Widget field(
      DoctorRegField key,
      String hint, {
      TextInputType? keyboardType,
    }) => AppTextField(
      hint: hint,
      height: AppTextField.compactFieldHeight,
      keyboardType: keyboardType,
      errorText: state.errorOf(key),
      onChanged: (value) => controller.setField(key, value),
    );

    return RegistrationStepLayout(
      progress: RegistrationProgress.personalData,
      title: l10n.doctorRegistrationTitle,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            padding: RegistrationFormCard.padding,
            child: Column(
              children: [
                field(
                  DoctorRegField.email,
                  l10n.emailHint,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                field(DoctorRegField.fullName, l10n.fullNameHint),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: AbsorbPointer(
                    child: AppTextField(
                      hint: l10n.birthDateHint,
                      controller: _birthDateController,
                      height: AppTextField.compactFieldHeight,
                      errorText: state.errorOf(DoctorRegField.birthDate),
                    ),
                  ),
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                field(DoctorRegField.specialty, l10n.doctorSpecialtyHint),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                field(
                  DoctorRegField.licenseNumber,
                  l10n.doctorLicenseNumberHint,
                ),
                const SizedBox(height: RegistrationFormCard.fieldGap),
                field(DoctorRegField.city, l10n.doctorCityHint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        RegistrationNextButton(
          child: PrimaryButton(
            label: l10n.nextButtonLabel,
            trailingIcon: Icons.arrow_forward,
            isLoading: state.isSubmitting,
            onPressed: _next,
          ),
        ),
      ],
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    ref
        .read(doctorRegistrationControllerProvider.notifier)
        .setField(DoctorRegField.birthDate, '${picked.year}-$month-$day');
    _birthDateController.text = '$day.$month.${picked.year}';
  }

  Future<void> _next() async {
    final ok = await ref
        .read(doctorRegistrationControllerProvider.notifier)
        .start();
    if (ok && mounted) context.push(Routes.doctorRegisterVerify);
  }
}
