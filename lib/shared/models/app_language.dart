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

  /// Разбор сохранённого кода. `null` — код не наш или ничего не сохранено.
  static AppLanguage? byCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
