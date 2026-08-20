import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/admin_topic_chip.dart';
import '../widgets/doctor_admin_metrics.dart';

/// «Ответ от админа» — заявка и ответ на неё.
///
/// Свёрстан по `design/для врача от клиники/Ответ от админа.png`
/// (440×956). Заголовок экрана тот же, что у формы, — «Заявка в
/// администрацию», и так же в две строки.
class DoctorAdminAnswerScreen extends ConsumerWidget {
  const DoctorAdminAnswerScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final request = ref.watch(doctorAdminRequestProvider(requestId)).value;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: request == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DoctorAdminMetrics.screenH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: DoctorAdminMetrics.topBarTop),
                      ScreenTopBar(
                        title: l10n.doctorAdminRequestTitle,
                        height: DoctorAdminMetrics.topBarHeight,
                        titleMaxWidth: DoctorAdminMetrics.titleMaxWidth,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(
                        height: DoctorAdminMetrics.topBarToHeading,
                      ),
                      Text(
                        l10n.doctorAdminTopicTitle,
                        style: AppTypography.calendarDaySubtitle.copyWith(
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: DoctorAdminMetrics.headingToChips),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AdminTopicChip(
                          topic: request.topic,
                          isSelected: true,
                        ),
                      ),
                      const SizedBox(height: DoctorAdminMetrics.chipToCard),
                      _TextCard(text: request.text, date: request.createdAt),
                      const SizedBox(
                        height: DoctorAdminMetrics.answerHeadingTop,
                      ),
                      Text(
                        l10n.doctorAdminAnswerTitle,
                        style: AppTypography.cardTitleAccent.copyWith(
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: DoctorAdminMetrics.headingToChips),
                      if (request.answer case final answer?)
                        _TextCard(text: answer, date: request.answeredAt)
                      else
                        // Состояния «ответа ещё нет» в макете нет, но заявка
                        // без ответа — обычное дело, и пустое место под
                        // заголовком выглядело бы поломкой.
                        _TextCard(text: l10n.doctorAdminNoAnswerYet),
                      SizedBox(
                        height: 40 + MediaQuery.paddingOf(context).bottom,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Белая карточка с текстом и датой под ним.
class _TextCard extends StatelessWidget {
  const _TextCard({required this.text, this.date});

  final String text;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTypography.conclusionBody.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 28),
            Text(
              l10n.doctorAdminDate(RuDates.dayMonthShortYear(date!)),
              style: AppTypography.cardItemMeta,
            ),
          ],
        ],
      ),
    );
  }
}
