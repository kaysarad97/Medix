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

  /// Родительный падеж — «27 июля» в подписи уведомления.
  static const List<String> monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
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

  /// Полные названия дней недели — заголовок календаря врача «Четверг».
  static const List<String> weekdaysFull = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  /// «Июль, 2026».
  static String monthAndYear(DateTime date) =>
      '${monthsNominative[date.month - 1]}, ${date.year}';

  /// «Пн».
  static String weekdayShort(DateTime date) => weekdaysShort[date.weekday - 1];

  /// «Четверг» — заголовок календаря врача.
  static String weekdayFull(DateTime date) => weekdaysFull[date.weekday - 1];

  /// «21-е июля, 2026 года» — подзаголовок календаря врача. Суффикс дня
  /// везде «-е»: это стандартное сокращение порядкового числительного в
  /// датах («1-е», «3-е», «21-е»), а не буквальное окончание слова
  /// («первое», «третье») — в макете `design/.../Календарь.png` дата
  /// подписана «21-ое», это тот случай, где число совпало с окончанием
  /// случайно, но сокращение всё равно унифицированное.
  static String dayOrdinalMonthYear(DateTime date) =>
      '${date.day}-е ${monthsGenitive[date.month - 1]}, ${date.year} года';

  /// «10.07».
  static String dayMonth(DateTime date) =>
      '${_two(date.day)}.${_two(date.month)}';

  /// «10.08.26» — дата отзыва. Год двумя цифрами: так в макете
  /// `design/Оставьте отзыв.png`.
  static String dayMonthShortYear(DateTime date) =>
      '${dayMonth(date)}.${_two(date.year % 100)}';

  /// «27 июля».
  static String dayAndMonth(DateTime date) =>
      '${date.day} ${monthsGenitive[date.month - 1]}';

  /// «21 Июля, Четверг» — строка записи на «Профиле пациента» у врача.
  /// Месяц с прописной: так в макете, хотя во всех остальных датах он
  /// строчный.
  static String dayMonthWeekday(DateTime date) {
    final month = monthsGenitive[date.month - 1];
    final capitalized = '${month[0].toUpperCase()}${month.substring(1)}';
    return '${date.day} $capitalized, ${weekdayFull(date)}';
  }

  /// «13:30», «9:30».
  ///
  /// Час без ведущего нуля — так в макете расписания: слот «9:30» уже
  /// соседних, и по ширине это видно.
  static String time(DateTime date) => '${date.hour}:${_two(date.minute)}';

  /// «13:44» — с ведущим нулём, в отличие от [time]: так подписано время
  /// прихода в списке чатов и в уведомлениях.
  static String hourMinute(DateTime date) =>
      '${_two(date.hour)}:${_two(date.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
