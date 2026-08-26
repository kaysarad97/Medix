import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/patient_chat.dart';
import '../providers/doctor_cabinet_providers.dart';

/// «Чаты с пациентами» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Чаты с пациентами.png`
/// (440×956). Устроен так же, как пациентский `ChatsListScreen`: та же
/// строка поиска, тот же закреплённый чат-бот первой строкой и те же
/// размеры. Отличия — в собеседнике: аватар пациента вместо портрета врача
/// и своя строка поиска, чтобы ввод на одном экране не фильтровал другой.
class DoctorChatsScreen extends ConsumerWidget {
  const DoctorChatsScreen({super.key});

  static const double _screenH = 21;
  static const double _topBarTop = 37;
  static const double _topBarToCard = 17;
  static const double _searchHeight = 58;
  static const double _rowHeight = 74;
  static const double _rowGap = 12;

  /// Под поиском и списком в макете лежит чуть более светлая подложка —
  /// та же, что держит переписку на «Чате с пациентом», только слабее.
  /// Замер по пустой полосе между поиском и первой строкой: белый на 20 %
  /// поверх градиента (почти как 0x2E у переписки), края совпадают с краями
  /// карточек (21…418), сверху и снизу по 9.
  static const Color _panelFill = Color(0x33FFFFFF);
  static const double _panelPaddingV = 9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(visibleDoctorChatsProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topBarTop),
              ScreenTopBar(
                title: l10n.allChatsTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: _topBarToCard),
              Flexible(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: _panelFill,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: _panelPaddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _SearchField(height: _searchHeight),
                        const SizedBox(height: 16),
                        // shrinkWrap внутри Flexible, а не Expanded:
                        // подложка в макете кончается сразу за последней
                        // строкой, а не растягивается до низа экрана.
                        Flexible(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: threads.length + 1,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: _rowGap),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Бот у врача тот же, что у пациента:
                                // своего экрана для него в кабинете нет.
                                return _BotRow(
                                  height: _rowHeight,
                                  onTap: () => context.push(Routes.chatbot),
                                );
                              }
                              final thread = threads[index - 1];
                              return _ThreadRow(
                                thread: thread,
                                height: _rowHeight,
                                onTap: () => context.push(
                                  Routes.doctorPatientChatOf(thread.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.allPill,
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            const AppIcon(icon: MedixIcon.search, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: TextField(
                  onChanged: (value) => ref
                      .read(doctorChatSearchQueryProvider.notifier)
                      .update(value),
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l10n.chatSearchHint,
                    hintStyle: AppTypography.placeholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

/// Закреплённая строка чат-бота.
class _BotRow extends StatelessWidget {
  const _BotRow({required this.height, required this.onTap});

  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                const AppIconChip(icon: MedixIcon.botAvatar, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.botThreadTitle,
                        style: AppTypography.cardItemTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.doctorBotThreadPreview,
                        // У бота подпись серая, у переписок — синяя: так в
                        // макете, и это единственное их различие.
                        style: AppTypography.tileSubtitle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('21.07, 13:44', style: AppTypography.cardItemMeta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.height,
    required this.onTap,
  });

  final PatientChatThread thread;
  final double height;
  final VoidCallback onTap;

  static const double _avatarSize = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: height,
      child: Material(
        // Непрочитанная строка в макете подсвечена голубым.
        color: thread.isRead ? AppColors.surface : AppColors.accentSofter,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                UserAvatar(
                  asset: thread.patientAvatarAsset,
                  size: const Size.square(_avatarSize),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.patientName,
                        style: AppTypography.cardItemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessageIsMine
                            ? l10n.myMessagePrefix(thread.lastMessage)
                            : thread.lastMessage,
                        style: AppTypography.tileSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(thread.timeLabel, style: AppTypography.cardItemMeta),
                    const SizedBox(height: 6),
                    Text(
                      thread.isRead
                          ? l10n.messageReadLabel
                          : l10n.messageUnreadLabel,
                      style: AppTypography.cardItemMeta,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
