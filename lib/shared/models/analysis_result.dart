/// Результат анализа в списке «Ваши анализы».
///
/// В макете строка показывает название, значение с единицами, референсный
/// интервал под названием и полоску-шкалу справа с точкой на текущем
/// значении.
///
/// Нужен и профилю пользователя, и карточкам членов семьи («Моя Семья») —
/// поэтому в `shared/`, а не в одной из фич.
class AnalysisResult {
  const AnalysisResult({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    required this.referenceLow,
    required this.referenceHigh,
    required this.takenAt,
  });

  final String id;

  /// «Железо в сыворотке».
  final String name;

  final double value;

  /// «мкмоль/л».
  final String unit;

  final double referenceLow;
  final double referenceHigh;

  final DateTime takenAt;

  /// «24.8 мкмоль/л».
  String get valueLabel => '${_trim(value)} $unit';

  /// «10.7 - 32.2 мкмоль/л» — подпись под названием.
  String get referenceLabel =>
      '${_trim(referenceLow)} - ${_trim(referenceHigh)} $unit';

  bool get isWithinReference => value >= referenceLow && value <= referenceHigh;

  /// Положение точки на шкале, 0…1.
  ///
  /// Шкала в макете шире референсного интервала: по краям красные зоны,
  /// в середине зелёная. Интервал занимает среднюю треть, поэтому значение
  /// на нижней границе даёт 0.33, на верхней — 0.67, а выходящие за
  /// пределы прижимаются к краям.
  double get position {
    const lowEdge = 1 / 3;
    const highEdge = 2 / 3;
    if (referenceHigh <= referenceLow) return 0.5;
    final t = (value - referenceLow) / (referenceHigh - referenceLow);
    final scaled = lowEdge + t * (highEdge - lowEdge);
    return scaled.clamp(0.0, 1.0);
  }

  /// Дробную часть показываем только когда она есть: «25», а не «25.0».
  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

// Подписи вкладок — в виджете, не здесь: у enum нет доступа к BuildContext,
// нужного `AppLocalizations.of(context)`.
/// Вкладки над списком анализов.
enum AnalysesFilter { changed, all }
