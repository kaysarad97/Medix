import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/certificate.dart';

/// Грид 2×N карточек-документов — «Ваши сертификаты».
class CertificateGrid extends StatelessWidget {
  const CertificateGrid({super.key, required this.certificates});

  final List<Certificate> certificates;

  static const double cellHeight = 192;
  static const double gap = 18;
  static const double rowGap = 25;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row * 2 < certificates.length; row++) ...[
          if (row > 0) const SizedBox(height: rowGap),
          Row(
            children: [
              Expanded(child: _Cell(certificate: certificates[row * 2])),
              const SizedBox(width: gap),
              Expanded(
                child: row * 2 + 1 < certificates.length
                    ? _Cell(certificate: certificates[row * 2 + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
              boxShadow: AppShadows.card,
            ),
            child: const Center(
              child: Icon(
                // Превью содержимого PDF дизайнер не экспортировал —
                // сырая заглушка вместо текста документа.
                Icons.description_outlined,
                size: 40,
                color: AppColors.textDisabled,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                certificate.fileName,
                style: AppTypography.cardItemTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const AppIcon(
              icon: MedixIcon.chevronRight,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
