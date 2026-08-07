/// Форматирование сумм в тенге.
abstract final class RuMoney {
  /// «10 000» — разряды разделены пробелом.
  ///
  /// В части макетов (`design/Поиск врача результаты - Gold.png`,
  /// `design/Предоплата - GOLD.png`) разделитель — точка, но пробел это
  /// общий разделитель разрядов в остальном приложении, поэтому здесь и в
  /// вёрстке он один. Нужно и врачу (`Doctor.priceLabel`), и записи на
  /// приём (`Appointment.basePriceLabel`) — вынесено, чтобы не разъезжалось.
  static String? withThousands(int? value) {
    if (value == null) return null;
    final digits = value.toString();
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = end - 3 < 0 ? 0 : end - 3;
      groups.insert(0, digits.substring(start, end));
    }
    return groups.join(' ');
  }
}
