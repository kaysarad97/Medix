import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_input_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/chat_message.dart';
import '../providers/chatbot_controller.dart';

/// Лабораторный чат-бот.
///
/// Свёрстан по `design/Чат-бот Старт.png` и `design/Чат-бот.png`. Это не два
/// экрана, а два состояния одного: «Старт» — пустая переписка, вместо истории
/// показываются частые вопросы.
class ChatbotScreen extends ConsumerWidget {
  const ChatbotScreen({super.key});

  /// Поля экрана — та же сетка, что везде: x 21…419.
  static const double _screenH = 21;

  /// Безопасная зона 62 → верхняя строка 99.
  static const double _topBarTop = 37;

  /// Верхняя строка 99…133 → карточка 150.
  static const double _topBarToCard = 17;

  /// Карточка → строка ввода 565.
  static const double _cardToInput = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(chatbotControllerProvider.notifier);
    final state = ref.watch(chatbotControllerProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topBarTop),
              ScreenTopBar(title: 'Medi-bot', onBack: () => context.pop()),
              const SizedBox(height: _topBarToCard),
              Expanded(
                child: _ConversationCard(
                  state: state,
                  quickReplies: controller.quickReplies,
                  onQuickReply: (reply) => controller.send(reply.text),
                ),
              ),
              const SizedBox(height: _cardToInput),
              ChatInputBar(
                onSend: controller.send,
                enabled: !state.botIsTyping,
                onAttach: controller.attachFile,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Полупрозрачная карточка поверх фона: история или частые вопросы.
class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.state,
    required this.quickReplies,
    required this.onQuickReply,
  });

  final ChatbotState state;
  final List<QuickReply> quickReplies;
  final ValueChanged<QuickReply> onQuickReply;

  /// Замер: белый примерно на 18 % поверх фонового градиента.
  static const Color _fill = Color(0x2EFFFFFF);
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _fill, borderRadius: _radius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 24, 13, 16),
        child: state.isEmpty
            ? _QuickReplies(replies: quickReplies, onTap: onQuickReply)
            : _History(state: state),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.replies, required this.onTap});

  final List<QuickReply> replies;
  final ValueChanged<QuickReply> onTap;

  static const double _pillHeight = 46;
  static const double _pillGap = 13;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIconChip(icon: MedixIcon.botAvatar, size: 44),
        const SizedBox(height: 20),
        Text(l10n.chatbotFaqTitle, style: AppTypography.bodyMd),
        const SizedBox(height: 12),
        for (final reply in replies) ...[
          if (reply != replies.first) const SizedBox(height: _pillGap),
          _Pill(text: reply.text, onTap: () => onTap(reply)),
        ],
        const Spacer(),
        // ВНЕ МАКЕТА. Требование ТЗ: бот не ставит диагнозы, окончательное
        // решение за врачом. В макетах дисклеймера нет, но для медицинского
        // приложения он обязателен — как и кнопка вызова 103 на главной,
        // которой там тоже нет.
        Text(
          l10n.chatbotDisclaimer,
          style: AppTypography.captionMuted,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Без Align и Center: оба растягиваются на всю доступную ширину, а в
    // макете пилюля обхватывает текст — 167, 194 и 197 у трёх вопросов.
    return SizedBox(
      height: _QuickReplies._pillHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(_QuickReplies._pillHeight / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(text, style: AppTypography.chatQuickReply)],
            ),
          ),
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.state});

  final ChatbotState state;

  static const double _messageGap = 18;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Свежие реплики внизу — начинаем показ оттуда же.
      reverse: true,
      itemCount: state.messages.length + (state.botIsTyping ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: _messageGap),
      itemBuilder: (context, index) {
        if (state.botIsTyping && index == 0) {
          return const TypingIndicator(
            avatar: ChatAvatarIcon(icon: MedixIcon.botAvatar),
          );
        }

        final offset = state.botIsTyping ? 1 : 0;
        final message =
            state.messages[state.messages.length - 1 - index + offset];
        return ChatBubble(
          text: message.text,
          isOutgoing: !message.isBot,
          avatar: ChatAvatarIcon(
            icon: message.isBot ? MedixIcon.botAvatar : MedixIcon.userAvatar,
          ),
        );
      },
    );
  }
}
