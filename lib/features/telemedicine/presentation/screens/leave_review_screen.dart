import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/telemedicine_providers.dart';
import '../widgets/city_chip.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_metrics.dart';
import '../widgets/rating_stars.dart';

/// «Оставьте отзыв» — оценка звёздами и текст отзыва о враче.
///
/// Свёрстан по `design/Оставьте отзыв.png` (440×1010). Шапка та же, что на
/// профиле врача: заголовок «О враче», чип города и карточка врача — экран
/// продолжает профиль, а не начинает новую ветку.
///
/// Экран закрыл давний вопрос дизайнеру: у поля «Оставьте свой отзыв…» на
/// профиле врача не было ничего для оценки, и написанный отзыв уходил с
/// зашитыми пятью звёздами. Теперь оценку спрашивают здесь.
///
/// Отправлять по-прежнему некуда: эндпоинта отзывов у бэкенда нет, приходит
/// только рейтинг числом. Отзыв встаёт первым в карусели профиля и живёт до
/// перезапуска — см. [ComposedReviews].
class LeaveReviewScreen extends ConsumerStatefulWidget {
  const LeaveReviewScreen({super.key, required this.doctorId, this.now});

  final String doctorId;

  /// Подменяется в тестах: под отзывом стоит сегодняшняя дата.
  final DateTime? now;

  /// Шапка врача 305 → плашка оценки 320.
  static const double headerToRating = 15;

  /// Плашка оценки 320…373, высота 53.
  static const double ratingHeight = 53;

  /// Плашка 373 → карточка отзыва 394.
  static const double ratingToCard = 21;

  /// Карточка отзыва 394…558.
  static const double cardHeight = 164;

  /// Карточка 558 → кнопка 715. В макете между ними пусто: экран рассчитан
  /// на клавиатуру, которая закроет этот промежуток.
  static const double cardToButton = 157;

  /// Кнопка 715…772 шириной 372 по центру.
  static const double buttonHeight = 57;
  static const double buttonWidth = 372;

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  final _controller = TextEditingController();

  /// Оценка, которую поставил пользователь. В макете начинается с нуля —
  /// «Ваша оценка: 0.0» и пять контурных звёзд.
  double _rating = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(doctorProvider(widget.doctorId)).value;
    final profile = ref.watch(profileProvider).value;
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: doctor == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DoctorMetrics.topBarTop),
                    ScreenTopBar(
                      title: l10n.aboutDoctorTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: doctor.city == null
                          ? null
                          : CityChip(city: doctor.city!),
                    ),
                    const SizedBox(height: DoctorMetrics.topBarToHeader),
                    DoctorHeader(doctor: doctor),
                    const SizedBox(height: LeaveReviewScreen.headerToRating),
                    _Section(
                      child: _RatingPlate(
                        rating: _rating,
                        onRated: (value) => setState(() => _rating = value),
                      ),
                    ),
                    const SizedBox(height: LeaveReviewScreen.ratingToCard),
                    _Section(
                      child: _ReviewField(
                        controller: _controller,
                        date: RuDates.dayMonthShortYear(
                          widget.now ?? DateTime.now(),
                        ),
                      ),
                    ),
                    const SizedBox(height: LeaveReviewScreen.cardToButton),
                    Center(
                      child: SizedBox(
                        width: LeaveReviewScreen.buttonWidth,
                        child: _SubmitButton(
                          // Пока профиль не загрузился, отзыв нечем
                          // подписать; без оценки и текста отправлять нечего.
                          onTap: profile == null
                              ? null
                              : () => _submit(profile.fullName),
                        ),
                      ),
                    ),
                    const SizedBox(height: DoctorMetrics.screenH),
                  ],
                ),
              ),
      ),
    );
  }

  void _submit(String authorName) {
    ref
        .read(composedReviewsProvider.notifier)
        .add(text: _controller.text, authorName: authorName, rating: _rating);
    Navigator.of(context).maybePop();
  }
}

/// «Ваша оценка: 0.0» и пять звёзд, по которым её и ставят.
class _RatingPlate extends StatelessWidget {
  const _RatingPlate({required this.rating, required this.onRated});

  final double rating;
  final ValueChanged<double> onRated;

  /// Подпись 35…150 → звёзды с 160.
  static const double _labelToStars = 10;

  /// Звезда 28 с шагом 31 — по пяти звёздам 160…318.
  static const double _starSize = 28;
  static const double _starGap = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: LeaveReviewScreen.ratingHeight,
      child: AppCard(
        color: AppColors.accentSofter,
        borderRadius: DoctorMetrics.allRadius,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Text(
              l10n.yourRatingLabel(rating.toStringAsFixed(1)),
              style: AppTypography.cardTitleDark,
            ),
            const SizedBox(width: _labelToStars),
            // Оценка целыми звёздами: половинки бывают у среднего рейтинга
            // врача, а свою ставят целиком.
            for (var i = 1; i <= RatingStars.starCount; i++) ...[
              if (i > 1) const SizedBox(width: _starGap),
              GestureDetector(
                onTap: () => onRated(i.toDouble()),
                behavior: HitTestBehavior.opaque,
                child: RatingStars(
                  // Одна звезда из пяти: показываем ровно ту часть шкалы,
                  // которая приходится на неё.
                  rating: (rating - i + 1).clamp(0, 1).toDouble(),
                  size: _starSize,
                  count: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Белая карточка с текстом отзыва и датой под ним.
class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.controller, required this.date});

  final TextEditingController controller;
  final String date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: LeaveReviewScreen.cardHeight,
      child: AppCard(
        color: AppColors.surfaceWhite,
        borderRadius: DoctorMetrics.allRadius,
        padding: const EdgeInsets.all(DoctorMetrics.reviewPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTypography.reviewBody,
                cursorColor: AppColors.accent,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l10n.writeReviewPlaceholder,
                  hintStyle: AppTypography.placeholder,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.reviewDateLabel(date), style: AppTypography.captionMuted),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: LeaveReviewScreen.buttonHeight,
      child: Material(
        // Кнопка в макете светло-голубая, а не синяя, как «Далее» на
        // формах: отзыв — не обязательный шаг.
        color: AppColors.accentSofter,
        borderRadius: DoctorMetrics.allRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              l10n.leaveReviewButton,
              style: AppTypography.cardTitleDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Горизонтальные поля карточек — те же, что на профиле врача.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DoctorMetrics.screenH),
      child: child,
    );
  }
}
