import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../domain/entities/doctor_own_review.dart';

/// Белая карточка одного отзыва — «Отзывы о Вас».
///
/// Форма — как у пациентской `_ReviewCard` в `reviews_card.dart`, не
/// импортируется: тот класс приватный и лежит в чужой фиче.
class DoctorOwnReviewCard extends StatelessWidget {
  const DoctorOwnReviewCard({super.key, required this.review});

  final DoctorOwnReview review;

  // 5 строк текста (высота строки 1.45×13 ≈ 18.85) + шапка 23 + отступ 11 +
  // паддинг 16×2 ≈ 160 — с запасом, чтобы «хорошим рейтингом.» не резалось.
  static const double height = 182;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AppCard(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const AppIcon(
                  icon: MedixIcon.userAvatar,
                  size: 23,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    review.authorName,
                    style: AppTypography.chipLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 22),
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
      ),
    );
  }
}
