import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/external_url_opener.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';

class DoctorAppointmentFilesCard extends ConsumerWidget {
  const DoctorAppointmentFilesCard({super.key, required this.files});

  final List<DoctorAppointmentFile> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.doctorAppointmentFilesTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 10),
          for (final (index, file) in files.indexed) ...[
            if (index > 0) const Divider(height: 1),
            Material(
              color: AppColors.surfaceWhite,
              child: InkWell(
                key: ValueKey('doctor-appointment-file-${file.id}'),
                borderRadius: AppRadius.allMd,
                onTap: () => _open(context, ref, file),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const AppIcon(
                        icon: MedixIcon.attachment,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.consultationAttachmentLabel(index + 1),
                          style: AppTypography.bodyMd,
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: AppColors.primaryBright,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    DoctorAppointmentFile file,
  ) async {
    try {
      final uri = Uri.tryParse(file.downloadUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        throw const FormatException('Invalid appointment file URL');
      }
      final opened = await ref.read(externalUrlOpenerProvider)(uri);
      if (!opened) throw const FormatException('Could not open file');
    } catch (_) {
      if (context.mounted) {
        showFormErrorSnackBar(
          context,
          AppLocalizations.of(context)!.doctorAppointmentFileOpenError,
        );
      }
    }
  }
}
