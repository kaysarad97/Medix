import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/regular_patient.dart';
import 'doctor_home_metrics.dart';

/// «Постоянные пациенты» на главной кабинета врача: заголовок со ссылкой
/// «Все» (форма — та же, что у пациентской `DoctorsCard`) и грид 2×2 из
/// карточек-заглушек с именем.
class RegularPatientsCard extends StatelessWidget {
  const RegularPatientsCard({super.key, required this.patients, this.onSeeAll});

  final List<RegularPatient> patients;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(DoctorHomeMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.doctorRegularPatientsTitle,
                style: AppTypography.sectionTitle,
              ),
              GestureDetector(
                onTap: onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: Text(l10n.viewAllLabel, style: AppTypography.linkSmall),
              ),
            ],
          ),
          const SizedBox(height: DoctorHomeMetrics.patientsTitleToGrid),
          for (var row = 0; row * 2 < patients.length; row++) ...[
            if (row > 0)
              const SizedBox(height: DoctorHomeMetrics.patientRowGap),
            Row(
              children: [
                Expanded(child: _PatientChip(patient: patients[row * 2])),
                const SizedBox(width: DoctorHomeMetrics.patientChipGap),
                Expanded(
                  child: row * 2 + 1 < patients.length
                      ? _PatientChip(patient: patients[row * 2 + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientChip extends StatelessWidget {
  const _PatientChip({required this.patient});

  final RegularPatient patient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorHomeMetrics.patientChipHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allMd,
        ),
        child: Center(
          child: Text(
            patient.fullName,
            style: AppTypography.tileSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
