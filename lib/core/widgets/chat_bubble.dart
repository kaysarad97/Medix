import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'icon_chip.dart';

/// Реплика в переписке.
///
/// Принимает примитивы, а не сущность из фичи: пузыри одинаковы и в чате
/// с ботом, и в чате с врачом, а модели у них разные.
///
/// Замеры по `design/Чат-бот.png`: пузырь не шире 287, исходящий прижат
/// вправо, входящий влево, рядом кружок автора 26.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isOutgoing,
    this.avatar,
    this.incomingColor = AppColors.surfaceWhite,
  });

  final String text;

  /// Своё сообщение — синее и справа; чужое — светлое и слева.
  final bool isOutgoing;

  /// Кружок автора рядом с пузырём. У врача это фото, у бота — иконка.
  final Widget? avatar;

  /// У бота входящие белые, у врача — голубые.
  final Color incomingColor;

  static const double maxWidth = 287;
  static const double avatarSize = 26;
  static const double avatarGap = 8;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isOutgoing ? AppColors.primaryBright : incomingColor,
          borderRadius: _radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            text,
            style: isOutgoing
                ? AppTypography.bodyMd.copyWith(color: AppColors.textOnPrimary)
                : AppTypography.bodyMd,
          ),
        ),
      ),
    );

    final slot = avatar ?? const SizedBox(width: avatarSize);

    return Row(
      mainAxisAlignment: isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isOutgoing
          ? [Flexible(child: bubble), const SizedBox(width: avatarGap), slot]
          : [slot, const SizedBox(width: avatarGap), Flexible(child: bubble)],
    );
  }
}

/// Многоточие «собеседник печатает».
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, this.avatar});

  final Widget? avatar;

  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        avatar ?? const SizedBox(width: ChatBubble.avatarSize),
        const SizedBox(width: ChatBubble.avatarGap),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.accentSofter,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  const SizedBox(
                    width: _dotSize,
                    height: _dotSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Кружок-иконка автора для [ChatBubble].
class ChatAvatarIcon extends StatelessWidget {
  const ChatAvatarIcon({super.key, required this.icon});

  final MedixIcon icon;

  @override
  Widget build(BuildContext context) {
    return AppIconChip(
      icon: icon,
      size: ChatBubble.avatarSize,
      background: AppColors.accentSofter,
    );
  }
}
