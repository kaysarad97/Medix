import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_input_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/chats_providers.dart';

/// Переписка с врачом по `design/Чат с врачом.png`.
///
/// Устроена так же, как чат с ботом, поэтому пузыри и строка ввода общие —
/// они лежат в `core/widgets`.
class DoctorChatScreen extends ConsumerStatefulWidget {
  const DoctorChatScreen({super.key, required this.threadId});

  final String threadId;

  static const double _screenH = 21;
  static const double _topBarTop = 37;
  static const double _topBarToCard = 17;
  static const double _cardToInput = 20;
  static const double _messageGap = 18;

  /// Замер: белый примерно на 18 % поверх фонового градиента.
  static const Color _cardFill = Color(0x2EFFFFFF);

  @override
  ConsumerState<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends ConsumerState<DoctorChatScreen> {
  @override
  void initState() {
    super.initState();
    // Загрузку истории запускаем после первого кадра: build ещё не прошёл,
    // а провайдер уже начал бы менять состояние.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorChatControllerProvider.notifier).open(widget.threadId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(doctorChatControllerProvider.notifier);
    final state = ref.watch(doctorChatControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DoctorChatScreen._screenH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorChatScreen._topBarTop),
              ScreenTopBar(
                title: l10n.doctorChatTitle,
                onBack: () => context.pop(),
              ),
              const SizedBox(height: DoctorChatScreen._topBarToCard),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: DoctorChatScreen._cardFill,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 24, 13, 16),
                    child: ListView.separated(
                      reverse: true,
                      itemCount: state.messages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: DoctorChatScreen._messageGap),
                      itemBuilder: (context, index) {
                        final message =
                            state.messages[state.messages.length - 1 - index];
                        return ChatBubble(
                          text: message.text,
                          isOutgoing: message.isMine,
                          // У врача входящие голубые, а не белые как у бота.
                          incomingColor: AppColors.surfaceInfo,
                          avatar: ChatAvatarIcon(
                            icon: message.isMine
                                ? MedixIcon.userAvatar
                                : MedixIcon.doctorCall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DoctorChatScreen._cardToInput),
              ChatInputBar(
                onSend: controller.send,
                enabled: !state.isSending,
                onAttach: () {
                  // TODO(chats): вложения в переписке с врачом, когда
                  // появится загрузка файлов.
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
