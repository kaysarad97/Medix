/// Отдельный анализ или комплекс анализов в «Перечне услуг».
class LabService {
  const LabService({
    required this.id,
    required this.name,
    required this.price,
    this.kind = LabServiceKind.individual,
  });

  final String id;

  /// «Аланинаминотрансфераза (АЛТ)».
  final String name;

  /// Цена в тенге. Одна и та же у всех услуг — мок для проверки вёрстки,
  /// настоящая цена придёт с бэкенда.
  final int price;

  final LabServiceKind kind;

  /// «1000 ₸».
  String get priceLabel => '$price ₸';

  /// Буква для группировки списка — первая буква [name] в верхнем регистре.
  String get letter => name.isEmpty ? '' : name[0].toUpperCase();
}

enum LabServiceKind {
  /// Вкладка «отдельные анализы».
  individual,

  /// Вкладка «комплексы анализов».
  bundle,
}
