import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chat_bubble.dart';
import '../../../../core/widgets/chat_input_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';

/// «Чат с пациентом» — кабинет врача.
///
/// Свёрстан по `design/врач прилансер/Чат с пациентом.png` (440×978).
/// Файл лежит в комплекте фрилансера, но экран общий: у врача от клиники
/// он же открывается из «Чатов с пациентами».
///
/// Зеркало пациентского `DoctorChatScreen`: пузыри, строка ввода и
/// подложка общие (`core/widgets`), меняются только стороны — своё здесь
/// то, что написал врач, а входящее приходит от пациента.
class DoctorPatientChatScreen extends ConsumerStatefulWidget {
  const DoctorPatientChatScreen({super.key, required this.threadId});

  final String threadId;

  static const double _screenH = 21;
  static const double _topBarTop = 37;
  static const double _topBarToCard = 17;
  static const double _cardToInput = 20;
  static const double _messageGap = 18;

  /// Замер тот же, что у пациентской переписки: белый примерно на 18 %
  /// поверх фонового градиента.
  static const Color _cardFill = Color(0x2EFFFFFF);

  @override
  ConsumerState<DoctorPatientChatScreen> createState() =>
      _DoctorPatientChatScreenState();
}

class _DoctorPatientChatScreenState
    extends ConsumerState<DoctorPatientChatScreen> {
  @override
  void initState() {
    super.initState();
    // Загрузку истории запускаем после первого кадра: build ещё не прошёл,
    // а провайдер уже начал бы менять состояние.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientChatControllerProvider.notifier).open(widget.threadId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(patientChatControllerProvider.notifier);
    final state = ref.watch(patientChatControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DoctorPatientChatScreen._screenH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorPatientChatScreen._topBarTop),
              ScreenTopBar(
                title: l10n.doctorPatientChatTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: DoctorPatientChatScreen._topBarToCard),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: DoctorPatientChatScreen._cardFill,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 24, 13, 16),
                    child: ListView.separated(
                      reverse: true,
                      itemCount: state.messages.length,
                      separatorBuilder: (_, _) => const SizedBox(
                        height: DoctorPatientChatScreen._messageGap,
                      ),
                      itemBuilder: (context, index) {
                        final message =
                            state.messages[state.messages.length - 1 - index];
                        return ChatBubble(
                          text: message.text,
                          isOutgoing: message.isMine,
                          incomingColor: AppColors.surfaceInfo,
                          // Стороны зеркальны пациентскому чату: свой
                          // кружок — врач, входящий — пациент.
                          avatar: ChatAvatarIcon(
                            icon: message.isMine
                                ? MedixIcon.doctorCall
                                : MedixIcon.userAvatar,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DoctorPatientChatScreen._cardToInput),
              ChatInputBar(
                onSend: controller.send,
                enabled: !state.isSending,
                onAttach: () {
                  // Вложения появятся вместе с консультационным API:
                  // файлы в переписке живут там же, где сама переписка.
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
