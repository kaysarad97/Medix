import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_request.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/admin_topic_chip.dart';
import '../widgets/doctor_admin_metrics.dart';

/// «Мои заявки» — список обращений врача в администрацию клиники.
///
/// Свёрстан по `design/для врача от клиники/Мои заявки.png` (440×956).
/// Вход — плитка «Администрация» на главной кабинета: список полезнее
/// пустой формы, а создать новую заявку можно кнопкой внизу.
class DoctorAdminRequestsScreen extends ConsumerWidget {
  const DoctorAdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final requests = ref.watch(doctorAdminRequestsProvider).value ?? const [];

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DoctorAdminMetrics.screenH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorAdminMetrics.topBarTop),
              ScreenTopBar(
                title: l10n.doctorMyRequestsTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: DoctorAdminMetrics.topBarToHeading),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: requests.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DoctorAdminMetrics.requestCardGap),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _RequestCard(
                      request: request,
                      onTap: () =>
                          context.push(Routes.doctorAdminRequestOf(request.id)),
                    );
                  },
                ),
              ),
              const SizedBox(height: DoctorAdminMetrics.requestCardGap),
              SizedBox(
                height: DoctorAdminMetrics.buttonHeight,
                child: Material(
                  color: AppColors.accentSofter,
                  borderRadius: AppRadius.allMd,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(Routes.doctorAdminNewRequest),
                    child: Center(
                      child: Text(
                        l10n.doctorAdminCreateNew,
                        style: AppTypography.cardItemTitle,
                      ),
                    ),
                  ),
                ),
              ),
              // Кнопка в макете кончается на 849 при высоте экрана 956 —
              // до низа остаётся около 90 плюс системная панель.
              SizedBox(height: 90 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка заявки: тема, дата и первые строки текста.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final AdminRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: DoctorAdminMetrics.requestCardHeight,
      child: AppCard(
        // Поля карточки заявки шире общих 13: краска темы в макете
        // начинается на x 44 при карточке с x 21.
        padding: const EdgeInsets.all(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AdminTopicChip.label(request.topic, l10n),
                        // Кегль по ширине краски: «Нужно перенести запись»
                        // занимает в макете 170 px.
                        style: AppTypography.cardTitleAccent.copyWith(
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.doctorAdminDate(
                        RuDates.dayMonthShortYear(request.createdAt),
                      ),
                      style: AppTypography.cardItemMeta,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: AppRadius.allMd,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              request.text,
                              style: AppTypography.conclusionBody,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.primaryBright,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
