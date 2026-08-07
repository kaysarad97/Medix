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
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/chat_thread.dart';
import '../providers/chats_providers.dart';

/// Список переписок по `design/Чаты.png`: чат-бот закреплён первой строкой
/// над перепиской с врачами — единая точка входа в чаты, вместо отдельной
/// от бота.
class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  static const double _screenH = 21;
  static const double _topBarTop = 37;
  static const double _topBarToCard = 17;
  static const double _searchHeight = 58;
  static const double _rowHeight = 74;
  static const double _rowGap = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(visibleChatThreadsProvider);
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
                onBack: () => context.pop(),
              ),
              const SizedBox(height: _topBarToCard),
              const _SearchField(height: _searchHeight),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: threads.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: _rowGap),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _BotThreadRow(
                        height: _rowHeight,
                        onTap: () => context.push(Routes.chatbot),
                      );
                    }
                    final thread = threads[index - 1];
                    return _ThreadRow(
                      thread: thread,
                      height: _rowHeight,
                      onTap: () => context.push(Routes.chatOf(thread.id)),
                    );
                  },
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
                  onChanged: (value) =>
                      ref.read(chatSearchQueryProvider.notifier).update(value),
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

/// Закреплённая первая строка — переход в чат-бота лабораторий.
///
/// Не [ChatThread]: это не переписка из репозитория, а статичная точка
/// входа, поэтому текст и время — как в макете, без привязки к реальной
/// истории сообщений бота.
class _BotThreadRow extends StatelessWidget {
  const _BotThreadRow({required this.height, required this.onTap});

  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.surface,
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
                        l10n.symptomSearchHint,
                        style: AppTypography.tileSubtitle,
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

  final ChatThread thread;
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
                _Avatar(url: thread.doctorPhotoUrl, size: _avatarSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.doctorName,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.accentSoft,
          shape: BoxShape.circle,
        ),
        // Фото врача приходит с бэкенда; пока подложка.
        child: url == null
            ? null
            : ClipOval(child: Image.network(url!, fit: BoxFit.cover)),
      ),
    );
  }
}
