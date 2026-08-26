import '../../../../core/utils/ru_dates.dart';

/// О чём уведомление — на это разбиты вкладки экрана.
///
/// На сервере `kind` — свободная строка, а не перечисление: сегодня он
/// присылает `appointment_reminder` и `general`, завтра заведёт что-то ещё.
/// Поэтому здесь не разбор один-в-один, а раскладка по двум вкладкам
/// макета: всё про приёмы — в «Расписание», всё про переписку — в
/// «Сообщения от врачей».
enum NotificationKind {
  /// «Ваша запись подтверждена», напоминание о приёме, освободившийся слот.
  schedule,

  /// «Вам пришло сообщение».
  message;

  /// Незнакомое значение уходит в «Расписание»: это вкладка по умолчанию,
  /// и потерять уведомление там нельзя — в отличие от третьей вкладки,
  /// которой в макете нет.
  static NotificationKind fromApi(String? kind) {
    final value = kind?.toLowerCase() ?? '';
    if (value.contains('message') || value.contains('chat')) return message;
    return schedule;
  }
}

/// Строка списка уведомлений.
///
/// Текст приходит с сервера готовым (`title` и `body`), а не собирается из
/// частей: сервер шлёт то же самое письмом и пушем, и расходиться экрану с
/// письмом незачем. ЦЕНА РЕШЕНИЯ: текст всегда русский, языка в API нет —
/// на казахском и английском список останется русским, пока сервер не
/// научится локализовать.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.apiKind,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// Исходный `kind` сервера нужен для действий, которые нельзя выразить
  /// двумя визуальными вкладками экрана уведомлений.
  final String? apiKind;

  /// Когда пришло: время в правом верхнем углу строки.
  final DateTime createdAt;

  /// В макете непрочитанные ничем не выделены — поле есть, но экран его
  /// пока не показывает.
  final bool isRead;

  bool get opensWaitlist => apiKind == 'waitlist_offer';

  /// «21.07, 13:44» — как в списке чатов.
  String get timeLabel =>
      '${RuDates.dayMonth(createdAt)}, ${RuDates.hourMinute(createdAt)}';
}
