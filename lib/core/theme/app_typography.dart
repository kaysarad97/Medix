import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Типографические токены MedIx.
///
/// Размеры восстановлены по высоте прописных и по размаху
/// «выносной элемент вверх → вниз» в макетах `design/` (масштаб 1:1).
abstract final class AppTypography {
  /// Golos Text. Обязательное требование к любой замене — полный набор
  /// казахских букв (ӘәҒғҚқҢңӨөҰұҮүҺһІі): интерфейс переключается на
  /// казахский. На Onest, выбранном изначально по начертаниям, «Қазақша»
  /// рисовалось квадратами.
  static const String fontFamily = 'GolosText';

  /// Шрифт подключён вариативным файлом с осью `wght`. Flutter не выводит
  /// начертание из [TextStyle.fontWeight] для вариативных шрифтов — ось
  /// нужно задавать явно, поэтому все стили собираются через [_style],
  /// которая проставляет и `fontWeight` (для переносов/fallback), и
  /// `fontVariations` (для реального начертания).
  static TextStyle _style({
    required double size,
    required int weight,
    required Color color,
    double height = 1.2,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
    );
  }

  /// Заголовок экрана. «Логин», «Создайте профиль», «Введите код».
  static TextStyle get h1 =>
      _style(size: 36, weight: 400, color: AppColors.textPrimary);

  /// Заголовок секции. «Врачи», «Предстоящие записи».
  static TextStyle get h2 =>
      _style(size: 24, weight: 500, color: AppColors.textPrimary);

  /// Крупная надпись на кнопке. «Войти».
  static TextStyle get buttonLg =>
      _style(size: 20, weight: 400, color: AppColors.textOnPrimary);

  /// Обычная надпись на кнопке. «Далее →».
  static TextStyle get buttonMd =>
      _style(size: 17, weight: 500, color: AppColors.textOnPrimary);

  /// Заголовок карточки.
  static TextStyle get titleMd =>
      _style(size: 18, weight: 500, color: AppColors.textPrimary);

  /// Текст, введённый пользователем в поле ввода.
  static TextStyle get bodyLg =>
      _style(size: 16, weight: 400, color: AppColors.accent);

  /// Основной текст.
  static TextStyle get bodyMd =>
      _style(size: 15, weight: 400, color: AppColors.textPrimary);

  /// Подзаголовок под заголовком экрана. «Подтвердите личность».
  static TextStyle get subtitle =>
      _style(size: 17, weight: 400, color: AppColors.textMuted);

  /// Заголовок экрана политики — он мельче обычного [h1] и в две строки
  /// по центру.
  static TextStyle get policyTitle =>
      _style(size: 18, weight: 400, color: AppColors.textPrimary);

  /// Текст рядом с кружком согласия. «Я согласен(-на) на получение…».
  static TextStyle get consent =>
      _style(size: 13, weight: 400, color: AppColors.textPrimary, height: 1.25);

  /// Тело юридического документа на экране политики.
  static TextStyle get legalBody =>
      _style(size: 14, weight: 400, color: AppColors.textPrimary, height: 1.45);

  /// Цифра в боксе кода из СМС.
  static TextStyle get otpDigit =>
      _style(size: 28, weight: 500, color: AppColors.accent);

  /// Плейсхолдер в поле ввода.
  static TextStyle get placeholder =>
      _style(size: 16, weight: 400, color: AppColors.textSecondary);

  /// Подпись над полем ввода. «Ваш E-mail или ИИН:».
  static TextStyle get label =>
      _style(size: 14, weight: 500, color: AppColors.textPrimary);

  /// Текстовая ссылка. «или создать профиль».
  static TextStyle get link =>
      _style(size: 14, weight: 600, color: AppColors.brandIndigo);

  /// Мелкая поясняющая надпись. «или авторизоваться через».
  static TextStyle get caption =>
      _style(size: 13, weight: 500, color: AppColors.brandIndigo);

  /// Мелкая надпись поверх фона. «выслать СМС-сообщение ещё раз через 00:59».
  static TextStyle get captionMuted =>
      _style(size: 13, weight: 400, color: AppColors.textMuted);
}
