import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/icon_chip.dart';

/// Оценка звёздами: закрашенные, одна половинная, остальные контуром.
///
/// На макете рейтинг 4.5 нарисован как четыре звезды и половина пятой —
/// поэтому округления до целого недостаточно.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.gap = 2,
    this.color = AppColors.primaryBright,
    this.count = starCount,
  });

  /// Оценка 0…5.
  final double rating;

  final double size;
  final double gap;
  final Color color;

  /// Сколько звёзд рисовать. Меньше пяти нужно там, где каждая звезда
  /// нажимается отдельно: на `design/Оставьте отзыв.png` оценку ставят
  /// пальцем, и звёзды приходится разносить по своим кнопкам.
  final int count;

  static const int starCount = 5;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(width: gap),
          AppIcon(icon: _iconFor(i), size: size, color: color),
        ],
      ],
    );
  }

  /// Половинная звезда ставится, когда до целой не хватает от четверти до
  /// трёх четвертей: 4.5 → четыре целых и половина, 4.9 → пять целых.
  MedixIcon _iconFor(int index) {
    final remainder = rating - index;
    if (remainder >= 0.75) return MedixIcon.star;
    if (remainder >= 0.25) return MedixIcon.starHalf;
    return MedixIcon.starOutline;
  }
}
