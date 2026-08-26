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
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';

/// «Уведомления» по `design/Нотификации.png` (440×956).
///
/// Замеры: заголовок с краской 108…122, вкладки 21…214 и 225…418 высотой 42
/// на y 170, строки 21…419 высотой 66 с шагом 84 начиная с 237, кружок значка
/// 44 на 13 от края строки, текстовая колонка с 85, краска заголовка строки
/// 255…267, подписи — 278…288.
///
/// РАСХОЖДЕНИЕ С МАКЕТОМ, МЕЛКОЕ. Время в правом углу строки кончается на 404
/// вместо 398: нашим шрифтом «21.07, 13:44» шире макетного, а поле справа
/// одинаковое с левым. Двигать его дальше от края значило бы отнимать ширину
/// у подписи, которой её и так впритык.
///
/// РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. В макете выбрана вкладка «Расписание»,
/// а в списке под ней вперемешку и записи, и сообщения — то есть вкладки
/// нарисованы, но ничего не отбирают. Здесь они отбирают: иначе вторая
/// вкладка не значит ничего, а первая дублирует список целиком. Если
/// задумано было «Расписание = всё», это правится одной строкой в
/// `visibleNotificationsProvider`.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const double _screenH = 21;
  static const double _topBarTop = 34;

  /// Низ строки со стрелкой (132) → вкладки 171.
  static const double _topBarToTabs = 40;

  static const double _tabsHeight = 42;
  static const double _tabsGap = 11;

  /// Вкладки 170…212 → первая строка 237.
  static const double _tabsToList = 25;

  static const double _rowHeight = 66;
  static const double _rowGap = 18;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(notificationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(visibleNotificationsProvider);
    final filter = ref.watch(notificationsFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topBarTop),
              ScreenTopBar(
                title: l10n.notificationsTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: _topBarToTabs),
              SizedBox(
                height: _tabsHeight,
                child: Row(
                  children: [
                    for (final option in NotificationsFilter.values) ...[
                      if (option != NotificationsFilter.values.first)
                        const SizedBox(width: _tabsGap),
                      Expanded(
                        child: _Tab(
                          option: option,
                          selected: option == filter,
                          onTap: () => ref
                              .read(notificationsFilterProvider.notifier)
                              .select(option),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: _tabsToList),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: _rowGap),
                  itemBuilder: (context, index) => _NotificationRow(
                    notification: notifications[index],
                    height: _rowHeight,
                    onTap:
                        notifications[index].isRead &&
                            !notifications[index].opensWaitlist
                        ? null
                        : () async {
                            final notification = notifications[index];
                            if (notification.opensWaitlist) {
                              context.push(Routes.waitlist);
                            }
                            if (!notification.isRead) {
                              await ref
                                  .read(notificationsRepositoryProvider)
                                  .setRead(notification.id, read: true);
                              ref.invalidate(notificationsProvider);
                            }
                          },
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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final NotificationsFilter option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (option) {
      NotificationsFilter.schedule => l10n.notificationsFilterSchedule,
      NotificationsFilter.messages => l10n.notificationsFilterMessages,
    };

    return Material(
      color: selected ? AppColors.accentSofter : AppColors.surface,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: AppTypography.chipLabel.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.height,
    required this.onTap,
  });

  final AppNotification notification;
  final double height;
  final VoidCallback? onTap;

  /// Кружок значка 34…77 при строке с 21.
  static const double _padding = 13;
  static const double _chipSize = 44;

  /// Кружок кончается на 78, текст начинается с 85.
  static const double _chipToText = 5;

  /// Подпись подходит к времени вплотную: 337 против 343.
  static const double _textToTime = 3;

  /// Краска заголовка 255…267, подписи 278…288 при строке 237…302: текст
  /// стоит почти по центру, на 2,5 выше — отсюда нижний отступ.
  static const double _textLift = 5;
  static const double _titleToSubtitle = 7;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppRadius.allSm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _padding),
            child: Row(
              children: [
                _KindIcon(kind: notification.kind, size: _chipSize),
                const SizedBox(width: _chipToText),
                Expanded(child: _NotificationText(notification: notification)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationText extends StatelessWidget {
  const _NotificationText({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: _NotificationRow._textLift),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: AppTypography.cardItemTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: _NotificationRow._textToTime),
            Text(notification.timeLabel, style: AppTypography.notificationTime),
          ],
        ),
        const SizedBox(height: _NotificationRow._titleToSubtitle),
        Text(
          notification.body,
          style: AppTypography.notificationBody,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

/// Кружок со значком: чемоданчик у записи, облачко у сообщения.
class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind, required this.size});

  final NotificationKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kind == NotificationKind.message) {
      return AppIconChip(
        icon: MedixIcon.chat,
        size: size,
        background: AppColors.accentSofter,
        foreground: AppColors.brandIndigo,
      );
    }

    // Чемоданчика в экспорте дизайнера нет: это та же иконка, что ждёт своей
    // очереди аватаром бота в переписке (`MedixIcons.pending`). Пустой кружок
    // на её месте выглядел бы поломкой, поэтому Material — как карандаш
    // правки в семье и корзина в кнопке удаления.
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.accentSofter,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.medical_services_outlined,
          size: size / 2,
          color: AppColors.brandIndigo,
        ),
      ),
    );
  }
}
