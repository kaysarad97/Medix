/// Константы приложения.
abstract final class AppConstants {
  static const String appName = 'MedIx';

  /// Ширина макетов в `design/` (440×956 — логические точки iPhone 16 Pro Max).
  /// Пригодится, если понадобится адаптивное масштабирование.
  static const double designWidth = 440;
  static const double designHeight = 956;

  /// Длина одноразового кода из письма — столько цифр генерирует бэкенд.
  static const int otpCodeLength = 6;

  /// Пауза, которую бэкенд выдерживает перед повторной отправкой кода.
  static const Duration otpResendCooldown = Duration(seconds: 60);

  static const Duration networkTimeout = Duration(seconds: 20);
}
