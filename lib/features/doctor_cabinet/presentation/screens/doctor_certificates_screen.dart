import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/certificate_grid.dart';
import '../widgets/doctor_profile_link_row.dart';
import '../widgets/doctor_profile_metrics.dart';

/// «Ваши сертификаты» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Сертификаты -  в.ф.png`. У
/// фрилансера сверху ещё строка «Загрузить Сертификат» — своих файлов
/// врач от клиники не грузит, это делает клиника-администратор
/// (см. [showUploadRow], решение подтверждено в HANDOFF.md).
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

  Future<void> _uploadCertificate() async {
    if (_isUploading) return;

    final file = await ref.read(doctorFilePickerProvider).pickCertificate();
    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
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
              if (widget.showUploadRow) ...[
                _Section(
                  child: Column(
                    children: [
                      DoctorProfileLinkRow(
                        icon: MedixIcon.medicalCard,
                        title: l10n.doctorUploadCertificateTitle,
                        onTap: _isUploading ? null : _uploadCertificate,
                      ),
                      if (_isUploading)
                        const LinearProgressIndicator(
                          key: ValueKey('doctor-certificate-upload-progress'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: DoctorProfileMetrics.cardGap),
              ],
              _Section(child: CertificateGrid(certificates: certificates)),
              if (widget.showUploadRow) ...[
                const SizedBox(height: DoctorProfileMetrics.cardGap),
                _Section(
                  child: PrimaryButton(
                    label: l10n.nextButtonLabel,
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _isUploading
                        ? null
                        : () => context.push(Routes.doctorRegisterCard),
                  ),
                ),
              ],
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
