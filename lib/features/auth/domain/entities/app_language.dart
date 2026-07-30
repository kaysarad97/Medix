/// Язык интерфейса.
///
/// Порядок совпадает с `design/Язык и пуш увед.png`.
enum AppLanguage {
  kk('kk', 'Қазақша'),
  ru('ru', 'Русский'),
  en('en', 'English');

  const AppLanguage(this.code, this.label);

  /// Код для `Locale` и для передачи на бэкенд.
  final String code;

  /// Подпись в списке — всегда на самом языке, не переводится.
  final String label;
}
