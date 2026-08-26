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
import '../providers/doctor_chatbot_controller.dart';

/// Medi-bot кабинета врача.
///
/// Свёрстан по `design/для врача от клиники/Чат-бот Старт - в.ф.png` и
/// `Чат-бот - в.ф.png` — то же деление на состояния «Старт»/переписка, что
/// у пациентского `ChatbotScreen`, но своя форма вопросов (дозировки,
/// совместимость препаратов) и без прикрепления файла: в макете кнопка
/// скрепки есть (она в общем `ChatInputBar`), а сценария вложений — нет.
///
/// Вход — поле «Напишите Medi-bot...» на главной кабинета врача
/// (`DoctorHomeScreen._MediBotField`).
class DoctorChatbotScreen extends ConsumerWidget {
  const DoctorChatbotScreen({super.key});

  static const double _screenH = 21;
  static const double _topBarTop = 37;
  static const double _topBarToCard = 17;
  static const double _cardToInput = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(doctorChatbotControllerProvider.notifier);
    final state = ref.watch(doctorChatbotControllerProvider);

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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Полупрозрачная карточка поверх фона: история или частые вопросы — та же
/// форма, что у пациентского бота.
class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.state,
    required this.quickReplies,
    required this.onQuickReply,
  });

  final DoctorChatbotState state;
  final List<QuickReply> quickReplies;
  final ValueChanged<QuickReply> onQuickReply;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIconChip(icon: MedixIcon.botAvatar, size: 44),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.chatbotFaqTitle,
          style: AppTypography.bodyMd,
        ),
        const SizedBox(height: 12),
        for (final reply in replies) ...[
          if (reply != replies.first) const SizedBox(height: _pillGap),
          _Pill(text: reply.text, onTap: () => onTap(reply)),
        ],
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
    // Без Row(mainAxisSize: min): такой Row отдаёт Text неограниченную
    // ширину и текст никогда не переносится — у коротких пациентских
    // вопросов это не всплывало, а «Оформить направление и список анализов
    // для пациента» вылезает за карточку на 23px. Text сам обхватывает
    // короткий текст и переносит длинный по ширине карточки.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _QuickReplies._pillHeight),
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(_QuickReplies._pillHeight / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(text, style: AppTypography.chatQuickReply),
          ),
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.state});

  final DoctorChatbotState state;

  static const double _messageGap = 18;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
