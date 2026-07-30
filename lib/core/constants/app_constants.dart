/// Константы приложения.
abstract final class AppConstants {
  static const String appName = 'MedIx';

  /// Ширина макетов в `design/` (440×956 — логические точки iPhone 16 Pro Max).
  /// Пригодится, если понадобится адаптивное масштабирование.
  static const double designWidth = 440;
  static const double designHeight = 956;

  /// Длина ИИН РК.
  static const int iinLength = 12;

  static const Duration networkTimeout = Duration(seconds: 20);
}
