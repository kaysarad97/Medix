import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_review.dart';
import 'doctor_metrics.dart';
import 'rating_stars.dart';

/// «Топ отзывов»: голубая карточка с каруселью белых карточек отзывов
/// и точками-индикатором под ними.
class ReviewsCard extends StatefulWidget {
  const ReviewsCard({super.key, required this.reviews});

  final List<DoctorReview> reviews;

  @override
  State<ReviewsCard> createState() => _ReviewsCardState();
}

class _ReviewsCardState extends State<ReviewsCard> {
  late final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.accentSofter,
      borderRadius: DoctorMetrics.allRadius,
      // Снизу поля меньше: в макете точки почти прижаты к нижней кромке.
      padding: const EdgeInsets.fromLTRB(
        DoctorMetrics.reviewInset,
        DoctorMetrics.reviewInset,
        DoctorMetrics.reviewInset,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Заголовок вдвинут глубже белой карточки: 42 против 33.
            padding: const EdgeInsets.only(left: 9),
            child: Text(
              AppLocalizations.of(context)!.topReviewsTitle,
              style: AppTypography.cardTitleDark,
            ),
          ),
          const SizedBox(height: DoctorMetrics.reviewsTitleToCard),
          SizedBox(
            height: _ReviewCard.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.reviews.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) =>
                  _ReviewCard(review: widget.reviews[index]),
            ),
          ),
          const SizedBox(height: DoctorMetrics.reviewsToDots),
          _Dots(count: widget.reviews.length, active: _page),
        ],
      ),
    );
  }
}

/// Белая карточка одного отзыва.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final DoctorReview review;

  /// Высота по макету: y 722…877.
  static const double height = 156;

  /// Аватар автора: кружок 23.
  static const double avatarSize = 23;
  static const double avatarToName = 14;
  static const double nameToStars = 22;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceWhite,
      borderRadius: DoctorMetrics.allRadius,
      padding: const EdgeInsets.all(DoctorMetrics.reviewPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AppIcon(
                icon: MedixIcon.userAvatar,
                size: avatarSize,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: avatarToName),
              Flexible(
                child: Text(
                  review.authorName,
                  style: AppTypography.chipLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: nameToStars),
              RatingStars(rating: review.rating, size: 15, gap: 2.5),
            ],
          ),
          const SizedBox(height: 11),
          Expanded(
            child: Text(
              review.text,
              style: AppTypography.reviewBody,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: DoctorMetrics.dotGap),
          SizedBox(
            width: DoctorMetrics.dotSize,
            height: DoctorMetrics.dotSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == active
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Поле «Оставьте свой отзыв…» под карточкой отзывов.
///
/// Заливка в макете — не белая: замер даёт ровно чёрный с прозрачностью 4 %
/// поверх градиента (204→196, 211→203, 230→221 по трём каналам).
class ReviewComposer extends StatelessWidget {
  const ReviewComposer({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.composerHeight,
      child: Material(
        color: AppColors.textPrimary.withValues(alpha: 0.04),
        borderRadius: DoctorMetrics.allRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              const SizedBox(width: 14),
              const AppIcon(
                icon: MedixIcon.reviewCompose,
                size: 28,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.writeReviewPlaceholder,
                  style: AppTypography.placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}
