import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_patient.dart';
import 'doctor_patient_metrics.dart';

/// Шапка пациента: аватар, имя и три показателя — рост, вес, возраст.
///
/// Одна и та же на «Профиле пациента» и на «Записи с пациентом», замеры в
/// обоих макетах совпадают. Похожа на пациентскую `ProfileHeader`, но это
/// другой набор данных: там пол и дата рождения плюс значок подписки, здесь
/// — рост, вес и возраст, а подписки у пациента врач не видит.
class DoctorPatientHeader extends StatelessWidget {
  const DoctorPatientHeader({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          asset: patient.avatarAsset,
          size: const Size(
            DoctorPatientMetrics.avatarWidth,
            DoctorPatientMetrics.avatarHeight,
          ),
          borderRadius: AppRadius.allLg,
        ),
        const SizedBox(width: DoctorPatientMetrics.avatarToInfo),
        Expanded(
          // Колонка начинается ниже верхней кромки аватара: аватар с 150,
          // а имя в макете — с 194.
          child: Padding(
            padding: const EdgeInsets.only(
              top: DoctorPatientMetrics.avatarToName,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.fullName, style: AppTypography.patientName),
                const SizedBox(height: DoctorPatientMetrics.nameToMeta),
                Row(
                  children: [
                    Expanded(
                      child: _Meta(
                        value: patient.heightLabel,
                        label: l10n.patientHeightMetaLabel,
                      ),
                    ),
                    Expanded(
                      child: _Meta(
                        value: patient.weightLabel,
                        label: l10n.patientWeightMetaLabel,
                      ),
                    ),
                    Expanded(
                      child: _Meta(
                        value: patient.ageLabel,
                        label: l10n.patientAgeMetaLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Значение сверху, подпись под ним — так же, как в пациентском профиле.
class _Meta extends StatelessWidget {
  const _Meta({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.profileMetaValue),
        const SizedBox(height: DoctorPatientMetrics.metaValueToLabel),
        Text(label, style: AppTypography.profileMetaLabel),
      ],
    );
  }
}
