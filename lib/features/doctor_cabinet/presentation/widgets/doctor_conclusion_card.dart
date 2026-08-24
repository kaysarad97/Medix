import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import 'doctor_history_metrics.dart';

/// Блок «Об Имя Фамилия» с заключением врача о пациенте.
///
/// Один и тот же на трёх экранах кабинета — «О прошлой записи», «Профиль
/// пациента» и «Запись с пациентом», — поэтому виджет общий. Отличие
/// единственное: на «О прошлой записи» у строки загрузки нет шеврона.
///
/// Пустое заключение — не ошибка, а состояние по умолчанию: в макете на
/// его месте стоит объяснение, почему поле пустое.
class DoctorConclusionCard extends StatelessWidget {
  const DoctorConclusionCard({
    super.key,
    required this.patientName,
    required this.date,
    this.conclusion,
    this.showUploadChevron = true,
    this.onUpload,
  });

  final String patientName;

  /// Дата в шапке блока: «Заключение от 21.07.26».
  final DateTime date;

  final String? conclusion;
  final bool showUploadChevron;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.accentSofter,
      padding: const EdgeInsets.all(DoctorHistoryMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height:
                DoctorHistoryMetrics.conclusionHeaderHeight -
                DoctorHistoryMetrics.cardPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.doctorPastConclusionTitle(patientName),
                    style: AppTypography.cardItemTitle,
                  ),
                ),
                Text(
                  l10n.doctorPastConclusionDate(
                    RuDates.dayMonthShortYear(date),
                  ),
                  style: AppTypography.cardItemMeta,
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                conclusion ?? l10n.doctorPastConclusionPlaceholder,
                style: conclusion == null
                    ? AppTypography.conclusionBody
                    : AppTypography.conclusionBody.copyWith(
                        color: AppColors.textPrimary,
                      ),
              ),
            ),
          ),
          const SizedBox(height: DoctorHistoryMetrics.conclusionBodyToUpload),
          SizedBox(
            height: DoctorHistoryMetrics.uploadRowHeight,
            child: Material(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                // На прошедшей записи callback открывает текстовую форму и
                // сохраняет заключение в doctor-facing API. На будущей
                // записи callback не передаётся, чтобы не завершить её рано.
                onTap: onUpload,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.doctorPastUploadConclusion,
                          style: AppTypography.linkSmall,
                        ),
                      ),
                      if (showUploadChevron)
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.primaryBright,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
