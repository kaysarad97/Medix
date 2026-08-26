import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_request.dart';
import 'doctor_admin_metrics.dart';

/// Чип темы заявки — белая пилюля по ширине текста.
///
/// В списке тем текст чёрный, а у выбранной темы — синий: единственное
/// различие между «Часто задаваемыми вопросами» и «Темой заявки» в макетах.
class AdminTopicChip extends StatelessWidget {
  const AdminTopicChip({
    super.key,
    required this.topic,
    this.isSelected = false,
    this.onTap,
  });

  final AdminRequestTopic topic;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Подпись темы. Собирается здесь, а не в `enum`: у него нет доступа к
  /// `BuildContext` — общее правило проекта.
  static String label(AdminRequestTopic topic, AppLocalizations l10n) =>
      switch (topic) {
        AdminRequestTopic.reschedule => l10n.doctorAdminTopicReschedule,
        AdminRequestTopic.cancel => l10n.doctorAdminTopicCancel,
        AdminRequestTopic.vacation => l10n.doctorAdminTopicVacation,
        AdminRequestTopic.resignation => l10n.doctorAdminTopicResignation,
        AdminRequestTopic.other => l10n.doctorAdminTopicOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: DoctorAdminMetrics.chipHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorAdminMetrics.chipPaddingH,
            ),
            // widthFactor: 1 — иначе Center растягивает пилюлю на всю
            // ширину, а в макете она обжата по тексту.
            child: Center(
              widthFactor: 1,
              child: Text(
                label(topic, l10n),
                // Кегль по ширине краски: «Нужно перенести запись»
                // занимает в макете 146 px. Golos шире шрифта макета, и
                // точное совпадение дало бы 11 — мелко для нажимаемой
                // подписи; на 12 чип шире макетного на 8 px.
                style:
                    (isSelected
                            ? AppTypography.cardTitleAccent
                            : AppTypography.cardItemTitle)
                        .copyWith(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
