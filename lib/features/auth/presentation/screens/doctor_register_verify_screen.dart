import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_registration_controller.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/otp_resend_timer.dart';
import '../widgets/registration_step_layout.dart';

class DoctorRegisterVerifyScreen extends ConsumerWidget {
  const DoctorRegisterVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorRegistrationControllerProvider);
    final controller = ref.read(doctorRegistrationControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    ref.listen(doctorRegistrationControllerProvider, (previous, next) {
      if (next.formError != null && next.formError != previous?.formError) {
        showFormErrorSnackBar(context, next.formError!);
        controller.formErrorShown();
      }
    });

    return RegistrationStepLayout(
      progress: RegistrationProgress.verifyCode,
      title: l10n.verifyCodeTitle,
      children: [
        const SizedBox(height: 17),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            l10n.verifyCodeSubtitle(state.value(DoctorRegField.email)),
            style: AppTypography.subtitle,
          ),
        ),
        const SizedBox(height: 43),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: OtpCodeInput(
            onChanged: (value) =>
                controller.setField(DoctorRegField.code, value),
            onCompleted: (_) => _next(context, ref),
          ),
        ),
        const SizedBox(height: 70),
        Center(child: OtpResendTimer(onResend: controller.resendCode)),
        const SizedBox(height: 40),
        RegistrationNextButton(
          child: PrimaryButton(
            label: l10n.nextButtonLabel,
            isLoading: state.isSubmitting,
            onPressed: () => _next(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _next(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(doctorRegistrationControllerProvider.notifier)
        .verify();
    if (ok && context.mounted) {
      context.go('${Routes.doctorCertificates}?upload=true');
    }
  }
}
