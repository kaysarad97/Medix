import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/certificate_grid.dart';
import '../widgets/doctor_profile_metrics.dart';

/// «Ваши сертификаты» — кабинет врача.
///
/// Обычный режим свёрстан по
/// `design/для врача от клиники/Сертификаты -  в.ф.png`.
///
/// При [showUploadRow] это шаг регистрации врача-фрилансера по отдельному
/// макету `design/врач фрилансер/Загрузки документов.png`: прогресс, выбор
/// файла, специализация и кнопка «Далее». Кабинетный грид в этом состоянии
/// намеренно не показывается.
class DoctorCertificatesScreen extends ConsumerStatefulWidget {
  const DoctorCertificatesScreen({super.key, this.showUploadRow = false});

  final bool showUploadRow;

  @override
  ConsumerState<DoctorCertificatesScreen> createState() =>
      _DoctorCertificatesScreenState();
}

class _DoctorCertificatesScreenState
    extends ConsumerState<DoctorCertificatesScreen> {
  bool _isUploading = false;
  String? _selectedCertificateName;

  Future<void> _uploadCertificate() async {
    if (_isUploading) return;

    final file = await ref.read(doctorFilePickerProvider).pickCertificate();
    if (file == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _selectedCertificateName = file.name;
    });
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(doctorMediaRepositoryProvider)
          .uploadCredentials(
            filename: file.name,
            contentType: file.contentType,
            bytes: file.bytes,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.doctorCertificateUploadSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.doctorCertificateUploadError)),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final certificates =
        ref.watch(doctorCertificatesProvider).value ?? const [];

    if (widget.showUploadRow) {
      return _RegistrationCertificateStep(
        isUploading: _isUploading,
        selectedCertificateName: _selectedCertificateName,
        onPickCertificate: _isUploading ? null : _uploadCertificate,
        onNext: _isUploading
            ? null
            : () => context.push(Routes.doctorRegisterCard),
      );
    }

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorProfileMetrics.screenH,
                ),
                child: ScreenTopBar(
                  title: l10n.doctorCertificatesTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: const AppIcon(
                    icon: MedixIcon.settings,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              _Section(child: CertificateGrid(certificates: certificates)),
              SizedBox(
                height:
                    DoctorProfileMetrics.cardGap +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistrationCertificateStep extends StatelessWidget {
  const _RegistrationCertificateStep({
    required this.isUploading,
    required this.selectedCertificateName,
    required this.onPickCertificate,
    required this.onNext,
  });

  final bool isUploading;
  final String? selectedCertificateName;
  final VoidCallback? onPickCertificate;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 125),
              const Center(child: StepProgressBar(progress: 0.313)),
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(
                  l10n.doctorCertificatesTitle,
                  style: AppTypography.h1,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(
                  l10n.doctorUploadCertificateTitle,
                  style: AppTypography.subtitle,
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: AppCard(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    children: [
                      GestureDetector(
                        key: const ValueKey(
                          'doctor-registration-certificate-picker',
                        ),
                        onTap: onPickCertificate,
                        child: AbsorbPointer(
                          child: AppTextField(
                            hint:
                                selectedCertificateName ??
                                l10n.doctorUploadCertificateTitle,
                            height: AppTextField.compactFieldHeight,
                          ),
                        ),
                      ),
                      if (isUploading) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                          key: ValueKey('doctor-certificate-upload-progress'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      AppTextField(
                        hint: l10n.doctorSpecialtyHint,
                        height: AppTextField.compactFieldHeight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 38),
              Center(
                child: SizedBox(
                  width: PrimaryButton.mediumWidth,
                  child: PrimaryButton(
                    label: l10n.nextButtonLabel,
                    trailingIcon: Icons.arrow_forward,
                    onPressed: onNext,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
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
