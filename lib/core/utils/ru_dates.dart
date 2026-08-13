/// Русские названия дат.
///
/// Без `intl`: пакета в зависимостях нет, а нужны ровно три формата —
/// «Июль, 2026», «Пн» и «10.07». Когда появится казахская локализация,
/// это место переедет в ARB-словари.
abstract final class RuDates {
  /// Именительный падеж — заголовок календаря «Июль, 2026».
  static const List<String> monthsNominative = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  /// Сокращения дней недели в порядке [DateTime.weekday] (1 — понедельник).
  static const List<String> weekdaysShort = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  /// «Июль, 2026».
  static String monthAndYear(DateTime date) =>
      '${monthsNominative[date.month - 1]}, ${date.year}';

  /// «Пн».
  static String weekdayShort(DateTime date) => weekdaysShort[date.weekday - 1];

  /// «10.07».
  static String dayMonth(DateTime date) =>
      '${_two(date.day)}.${_two(date.month)}';

  /// «10.08.26» — дата отзыва. Год двумя цифрами: так в макете
  /// `design/Оставьте отзыв.png`.
  static String dayMonthShortYear(DateTime date) =>
      '${dayMonth(date)}.${_two(date.year % 100)}';

  /// «13:30», «9:30».
  ///
  /// Час без ведущего нуля — так в макете расписания: слот «9:30» уже
  /// соседних, и по ширине это видно.
  static String time(DateTime date) => '${date.hour}:${_two(date.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
