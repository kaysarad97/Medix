import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import 'doctor_profile_metrics.dart';

/// «Ваши Контакты»: телефон и почта.
class DoctorContactsCard extends StatelessWidget {
  const DoctorContactsCard({
    super.key,
    required this.phone,
    required this.email,
  });

  final String phone;
  final String email;

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
            title: l10n.doctorContactsTitle,
          ),
          const SizedBox(height: DoctorProfileMetrics.headerToFields),
          _Field(value: phone),
          const SizedBox(height: DoctorProfileMetrics.fieldGap),
          _Field(value: email),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.value});

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
              value,
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
