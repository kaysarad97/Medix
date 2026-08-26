import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/consultation.dart';

class ConsultationFileStrip extends StatelessWidget {
  const ConsultationFileStrip({
    super.key,
    required this.files,
    required this.labelBuilder,
    required this.onOpen,
    this.openingFileId,
  });

  final List<ConsultationFile> files;
  final String Function(int index) labelBuilder;
  final ValueChanged<ConsultationFile> onOpen;
  final String? openingFileId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = files[index];
          final busy = openingFileId == file.id;
          return Material(
            color: AppColors.surface,
            borderRadius: AppRadius.allMd,
            child: InkWell(
              key: ValueKey('consultation-file-${file.id}'),
              onTap: openingFileId == null ? () => onOpen(file) : null,
              borderRadius: AppRadius.allMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const AppIcon(
                        icon: MedixIcon.attachment,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      labelBuilder(index + 1),
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
