/// К какому члену семьи относится процедура — вкладки на экране «Предыдущие
/// процедуры». Семейный доступ (`lib/features/family_access/`) ещё не
/// построен: здесь только фильтр по мок-данным, без реальных профилей детей
/// и старших.
// Подписи вкладок — в виджете, не здесь: у enum нет доступа к BuildContext,
// нужного `AppLocalizations.of(context)`.
enum FamilyScope { self, child, senior }

/// Запись о прошлой консультации — карточка на экране «Предыдущие
/// процедуры» (`design/Предыдущие Процедуры.png`).
class MedicalProcedure {
  const MedicalProcedure({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    this.scope = FamilyScope.self,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final FamilyScope scope;

  /// «21.05.2026», как на макете.
  String get dateLabel => '${_two(date.day)}.${_two(date.month)}.${date.year}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
