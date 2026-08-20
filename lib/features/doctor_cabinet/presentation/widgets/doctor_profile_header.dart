import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_own_profile.dart';
import 'doctor_profile_metrics.dart';

/// Шапка «Ваш Профиль»: фото, имя, ID и статус, рейтинг справа.
///
/// Форма — как у пациентской `ProfileHeader` (фото/аватар + два столбца
/// значение-подпись + бейдж справа), но не импортируется: та лежит в
/// `features/profile`, чужой фиче.
class DoctorProfileHeader extends StatelessWidget {
  const DoctorProfileHeader({super.key, required this.profile});

  final DoctorOwnProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorProfileMetrics.screenH,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Photo(),
          const SizedBox(width: DoctorProfileMetrics.photoToInfo),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(profile.fullName, style: AppTypography.profileName),
                const SizedBox(height: DoctorProfileMetrics.nameToMeta),
                Row(
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        value: profile.doctorId,
                        label: l10n.doctorIdLabel,
                      ),
                    ),
                    Expanded(
                      child: _MetaColumn(
                        value: profile.status,
                        label: l10n.doctorStatusLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RatingBadge(label: profile.ratingLabel),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.5),
        borderRadius: AppRadius.allLg,
      ),
      child: const SizedBox(
        width: DoctorProfileMetrics.photoWidth,
        height: DoctorProfileMetrics.photoHeight,
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTypography.profileMetaValue),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.profileMetaLabel),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.accentSofter,
            borderRadius: AppRadius.allPill,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(icon: MedixIcon.star, size: 14),
                const SizedBox(width: 4),
                Text(label, style: AppTypography.chipLabel),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.doctorRatingLabel, style: AppTypography.profileMetaLabel),
      ],
    );
  }
}
