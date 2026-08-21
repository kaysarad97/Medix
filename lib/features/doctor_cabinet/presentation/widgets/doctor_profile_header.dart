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
  const DoctorProfileHeader({
    super.key,
    required this.profile,
    this.onChangePhoto,
    this.isUploadingPhoto = false,
  });

  final DoctorOwnProfile profile;

  /// `null` — фото не тапается: пока такое есть только у экрана профиля
  /// врача, а не у карточек, где он показывается пациенту или другому
  /// врачу в списке.
  final VoidCallback? onChangePhoto;
  final bool isUploadingPhoto;

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
          if (onChangePhoto != null)
            _TappablePhoto(
              onTap: isUploadingPhoto ? null : onChangePhoto!,
              isUploading: isUploadingPhoto,
              caption: l10n.doctorChangePhotoAction,
            )
          else
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

/// Та же плашка, что [_Photo], плюс подпись-ссылка под ней — тот же жест,
/// что у пациентской «изменить аватара» на «Настройках профиля», только
/// там аватар большой и по центру экрана, а тут маленький и в шапке.
class _TappablePhoto extends StatelessWidget {
  const _TappablePhoto({
    required this.onTap,
    required this.isUploading,
    required this.caption,
  });

  final VoidCallback? onTap;
  final bool isUploading;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.5),
              borderRadius: AppRadius.allLg,
            ),
            child: SizedBox(
              width: DoctorProfileMetrics.photoWidth,
              height: DoctorProfileMetrics.photoHeight,
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Text(
            caption,
            textAlign: TextAlign.center,
            style: AppTypography.captionMuted,
          ),
        ),
      ],
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
