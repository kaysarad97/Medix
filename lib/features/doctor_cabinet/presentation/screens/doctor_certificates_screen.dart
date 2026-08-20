import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
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
class DoctorCertificatesScreen extends ConsumerWidget {
  const DoctorCertificatesScreen({super.key, this.showUploadRow = false});

  final bool showUploadRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              if (showUploadRow) ...[
                _Section(
                  child: DoctorProfileLinkRow(
                    icon: MedixIcon.medicalCard,
                    title: l10n.doctorUploadCertificateTitle,
                  ),
                ),
                const SizedBox(height: DoctorProfileMetrics.cardGap),
              ],
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
