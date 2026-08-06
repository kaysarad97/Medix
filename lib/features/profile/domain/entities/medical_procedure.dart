/// К какому члену семьи относится процедура — вкладки на экране «Предыдущие
/// процедуры». Семейный доступ (`lib/features/family_access/`) ещё не
/// построен: здесь только фильтр по мок-данным, без реальных профилей детей
/// и старших.
enum FamilyScope {
  self,
  child,
  senior;

  /// Подпись вкладки.
  String get label => switch (this) {
    FamilyScope.self => 'Мои процедуры',
    FamilyScope.child => 'Процедуры ребёнка',
    FamilyScope.senior => 'Процедуры старших',
  };
}

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
