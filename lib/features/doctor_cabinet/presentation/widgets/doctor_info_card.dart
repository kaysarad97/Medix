import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_own_profile.dart';
import 'doctor_profile_metrics.dart';

/// «Ваша Информация»: специализация, опыт, категория, адрес — поля пустые
/// в макете, врач их ещё не заполнил, показываем плейсхолдером, как и
/// макет — и переключатель «Онлайн-прием» / «Оффлайн-прием».
class DoctorInfoCard extends StatelessWidget {
  const DoctorInfoCard({super.key, required this.profile});

  final DoctorOwnProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(DoctorProfileMetrics.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            icon: MedixIcon.medicalCard,
            title: l10n.doctorInfoTitle,
          ),
          const SizedBox(height: DoctorProfileMetrics.headerToFields),
          _Field(
            hint: l10n.doctorSpecializationHint,
            value: profile.specialization,
          ),
          const SizedBox(height: DoctorProfileMetrics.fieldGap),
          _Field(hint: l10n.doctorExperienceHint, value: profile.experience),
          const SizedBox(height: DoctorProfileMetrics.fieldGap),
          _Field(hint: l10n.doctorCategoryHint, value: profile.category),
          const SizedBox(height: DoctorProfileMetrics.fieldGap),
          _Field(hint: l10n.doctorAddressHint, value: profile.address),
          const SizedBox(height: DoctorProfileMetrics.fieldsToToggle),
          Text(
            l10n.doctorConsultationTypesLabel,
            style: AppTypography.cardItemMeta,
          ),
          const SizedBox(height: 8),
          _ConsultationToggle(online: profile.onlineConsultations),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.hint, required this.value});

  final String hint;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorProfileMetrics.fieldHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allMd,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value.isEmpty ? hint : value,
              style: AppTypography.placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsultationToggle extends StatelessWidget {
  const _ConsultationToggle({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: DoctorProfileMetrics.toggleHeight,
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: l10n.doctorOnlineConsultationLabel,
              selected: online,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToggleSegment(
              label: l10n.doctorOfflineConsultationLabel,
              selected: !online,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryBright : AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        border: selected ? null : Border.all(color: AppColors.divider),
      ),
      child: SizedBox(
        height: DoctorProfileMetrics.toggleHeight,
        child: Center(
          child: Text(
            label,
            style: AppTypography.buttonMd.copyWith(
              color: selected ? AppColors.textOnPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
