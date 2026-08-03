import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'icon_chip.dart';

/// Строка ввода в переписке — общая для бота и для чата с врачом.
///
/// Замеры по `design/Чат-бот Старт.png`: x 21…419, высота 58, полное
/// скругление; облачко слева, скрепка справа.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onAttach,
    this.enabled = true,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onAttach;
  final bool enabled;

  static const double height = 58;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ChatInputBar.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.allPill,
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            const AppIcon(icon: MedixIcon.symptomSearch, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Опишите Ваши симптомы...',
                    hintStyle: AppTypography.placeholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: widget.onAttach,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const AppIcon(
                icon: MedixIcon.attachment,
                size: 22,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Прикрепить файл',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
