import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/admin_request.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/admin_topic_chip.dart';
import '../widgets/doctor_admin_metrics.dart';

/// «Заявка в администрацию» — кабинет врача.
///
/// Свёрстан по трём макетам одного экрана:
/// `Запросы к админу.png` — тема ещё не выбрана, показан список частых
/// вопросов; `Набор текста запроса.png` — тема выбрана, поле пустое, стоит
/// курсор; `Запросы к админу (1).png` — текст набран, под ним дата, строка
/// вложения и кнопка отправки. Это одно состояние, разложенное на три
/// картинки, поэтому и экран один.
///
/// Врач от клиники не отменяет и не переносит записи сам — он пишет сюда;
/// у фрилансера этого экрана нет вовсе.
class DoctorAdminRequestScreen extends ConsumerStatefulWidget {
  const DoctorAdminRequestScreen({super.key});

  @override
  ConsumerState<DoctorAdminRequestScreen> createState() =>
      _DoctorAdminRequestScreenState();
}

class _DoctorAdminRequestScreenState
    extends ConsumerState<DoctorAdminRequestScreen> {
  final _text = TextEditingController();
  AdminRequestTopic? _topic;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final topic = _topic;
    if (topic == null || _text.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    await ref
        .read(doctorCabinetRepositoryProvider)
        .sendAdminRequest(topic: topic, text: _text.text.trim());
    // Список заявок перечитается сам: он autoDispose и собирается заново
    // при открытии.
    ref.invalidate(doctorAdminRequestsProvider);

    if (!mounted) return;
    setState(() => _isSending = false);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topic = _topic;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        // Кнопка в макете прижата к низу экрана, а не идёт сразу за
        // строкой вложения. Обычная колонка со `Spacer` этого не даст —
        // с поднятой клавиатурой она переполнится; поэтому колонка растёт
        // до высоты экрана, а если не помещается, страница прокручивается.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorAdminMetrics.screenH,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
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
                    const SizedBox(height: DoctorAdminMetrics.topBarToHeading),
                    Text(
                      topic == null
                          ? l10n.doctorAdminFaqTitle
                          : l10n.doctorAdminTopicTitle,
                      style: AppTypography.calendarDaySubtitle.copyWith(
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: DoctorAdminMetrics.headingToChips),
                    if (topic == null)
                      _TopicList(
                        onSelected: (value) => setState(() => _topic = value),
                      )
                    else
                      _Compose(topic: topic, text: _text),
                    if (topic != null) ...[
                      const Spacer(),
                      SizedBox(
                        height: DoctorAdminMetrics.buttonHeight,
                        child: Material(
                          color: AppColors.accentSofter,
                          borderRadius: AppRadius.allMd,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            // Пока текст пуст, отправлять нечего: кнопка в макете
                            // всегда светлая, поэтому состояние видно только по
                            // тому, нажимается она или нет.
                            onTap: _text.text.trim().isEmpty || _isSending
                                ? null
                                : _send,
                            child: Center(
                              child: Text(
                                l10n.doctorAdminSend,
                                style: AppTypography.cardItemTitle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24 + MediaQuery.paddingOf(context).bottom,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Список частых вопросов — пять пилюль по ширине текста.
class _TopicList extends StatelessWidget {
  const _TopicList({required this.onSelected});

  final ValueChanged<AdminRequestTopic> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, topic) in AdminRequestTopic.values.indexed) ...[
          if (index > 0) const SizedBox(height: DoctorAdminMetrics.chipGap),
          AdminTopicChip(topic: topic, onTap: () => onSelected(topic)),
        ],
      ],
    );
  }
}

/// Выбранная тема, поле текста и строка вложения.
class _Compose extends StatelessWidget {
  const _Compose({required this.topic, required this.text});

  final AdminRequestTopic topic;
  final TextEditingController text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AdminTopicChip(topic: topic, isSelected: true),
        ),
        const SizedBox(height: DoctorAdminMetrics.chipToCard),
        SizedBox(
          height: DoctorAdminMetrics.composeCardHeight,
          child: AppCard(
            color: AppColors.surfaceWhite,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    autofocus: true,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: AppTypography.conclusionBody.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: l10n.doctorAdminComposeHint,
                      hintStyle: AppTypography.conclusionBody,
                    ),
                  ),
                ),
                // Дата стоит под текстом и появляется вместе с ним: в
                // макете пустого поля её нет.
                if (text.text.trim().isNotEmpty)
                  Text(
                    l10n.doctorAdminDate(
                      RuDates.dayMonthShortYear(DateTime.now()),
                    ),
                    style: AppTypography.cardItemMeta,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DoctorAdminMetrics.cardToAttach),
        SizedBox(
          height: DoctorAdminMetrics.attachRowHeight,
          child: Material(
            color: AppColors.surfaceWhite,
            borderRadius: AppRadius.allMd,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // Прикладывать пока некуда: файлового хранилища у кабинета
              // врача нет, как и самого бэкенда под заявки.
              onTap: null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  children: [
                    const AppIconChip(
                      icon: MedixIcon.attachment,
                      size: 44,
                      background: AppColors.accentSofter,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.doctorAdminAttachFile,
                        style: AppTypography.cardItemTitle,
                      ),
                    ),
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
        const SizedBox(height: DoctorAdminMetrics.cardToAttach),
      ],
    );
  }
}
