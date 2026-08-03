import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/chat_message.dart';

/// Реплика в переписке с ботом.
///
/// Замеры по `design/Чат-бот.png`: пузырь не шире 287, синий прижат вправо,
/// белый влево, рядом кружок автора 26.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  static const double maxWidth = 287;
  static const double _avatarSize = 26;
  static const double _avatarGap = 8;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: message.isBot
              ? AppColors.surfaceWhite
              : AppColors.primaryBright,
          borderRadius: _radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            message.text,
            style: message.isBot
                ? AppTypography.bodyMd
                : AppTypography.bodyMd.copyWith(color: AppColors.textOnPrimary),
            textAlign: message.isBot ? TextAlign.start : TextAlign.end,
          ),
        ),
      ),
    );

    final avatar = AppIconChip(
      icon: message.isBot ? MedixIcon.medicalCard : MedixIcon.userAvatar,
      size: _avatarSize,
      background: AppColors.accentSofter,
    );

    return Row(
      mainAxisAlignment: message.isBot
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: message.isBot
          ? [avatar, const SizedBox(width: _avatarGap), Flexible(child: bubble)]
          : [
              Flexible(child: bubble),
              const SizedBox(width: _avatarGap),
              avatar,
            ],
    );
  }
}

/// Многоточие «бот печатает».
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  static const double _dotSize = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppIconChip(
          icon: MedixIcon.medicalCard,
          size: ChatBubble._avatarSize,
          background: AppColors.accentSofter,
        ),
        const SizedBox(width: ChatBubble._avatarGap),
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
