/// Показатели работы врача за период — «Аналитика Работы.png».
///
/// Одни и те же четыре числа считаются и за неделю, и за месяц: в макете
/// это две одинаковые по составу карточки, отличаются только заголовком,
/// диапазоном и раскраской (неделя — светлая, месяц — синяя).
class DoctorWorkStats {
  const DoctorWorkStats({
    required this.appointments,
    required this.deltaVsUsual,
    required this.averageMinutes,
    required this.ratingDelta,
    required this.earningsPercent,
  });

  /// «7 записей».
  final int appointments;

  /// «на 2 больше чем обычно». Отрицательное — «меньше».
  final int deltaVsUsual;

  /// «49 минут» — средняя длина записи.
  final int averageMinutes;

  /// «+0.5» к рейтингу.
  final double ratingDelta;

  /// «+20%» к заработку.
  final int earningsPercent;

  /// «+0.5»/«-0.5» — знак рисуется всегда, как в макете.
  String get ratingDeltaLabel {
    final sign = ratingDelta < 0 ? '-' : '+';
    return '$sign${ratingDelta.abs().toStringAsFixed(1)}';
  }

  String get earningsPercentLabel =>
      '${earningsPercent < 0 ? '-' : '+'}${earningsPercent.abs()}%';
}

/// Неделя: столбик на каждый день плюс общие показатели.
class DoctorWeekAnalytics {
  const DoctorWeekAnalytics({
    required this.from,
    required this.to,
    required this.perDay,
    required this.stats,
  });

  /// Начало и конец недели — подпись пейджера «13.07-20.07».
  final DateTime from;
  final DateTime to;

  /// Семь значений, с понедельника. Выходные в макете погашены, но своё
  /// значение у них тоже есть — врач мог принять и в субботу.
  final List<int> perDay;

  final DoctorWorkStats stats;
}

/// Месяц: ломаная по дням плюс те же показатели.
class DoctorMonthAnalytics {
  const DoctorMonthAnalytics({
    required this.month,
    required this.perDay,
    required this.stats,
  });

  /// Любой день месяца — для подписи «Июль 2026».
  final DateTime month;

  /// Значение на каждый день месяца, с первого. Подписи оси в макете
  /// стоят только у 1, 5, 10, 15, 20, 25 и 30 — рисует их сам график.
  final List<int> perDay;

  final DoctorWorkStats stats;
}

/// Обе карточки экрана разом: сервера под кабинет врача нет, а два
/// отдельных запроса на один экран заводить незачем.
class DoctorWorkAnalytics {
  const DoctorWorkAnalytics({required this.week, required this.month});

  final DoctorWeekAnalytics week;
  final DoctorMonthAnalytics month;
}
