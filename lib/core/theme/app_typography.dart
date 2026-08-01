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

  /// Приветствие на главной. «Как Ваше здоровье сегодня?».
  ///
  /// Кегль восстановлен по ширине строки, а не по высоте прописных: на
  /// синем фоне у белого текста широкий ореол сглаживания, и замер высоты
  /// завышает результат. «Как Ваше здоровье» занимает в макете 338 —
  /// это 37, а не 44.
  static TextStyle get homeGreeting =>
      _style(size: 37, weight: 400, color: AppColors.textOnPrimary);

  /// Заголовок карточки на главной. «Врачи», «Предстоящие записи».
  static TextStyle get sectionTitle =>
      _style(size: 20, weight: 400, color: AppColors.textPrimary);

  /// Заголовок плитки. «Сдать анализы», «Загрузить анализы».
  static TextStyle get tileTitle =>
      _style(size: 18, weight: 400, color: AppColors.textPrimary, height: 1.25);

  /// Синяя подпись под заголовком плитки. «в партнерских лабораториях».
  static TextStyle get tileSubtitle =>
      _style(size: 12, weight: 500, color: AppColors.primary);

  /// Заголовок элемента списка. «Терапевт», «Кардиолог».
  static TextStyle get cardItemTitle =>
      _style(size: 14, weight: 400, color: AppColors.textPrimary);

  /// Приписка к элементу списка. «100 врачей».
  static TextStyle get cardItemMeta =>
      _style(size: 12, weight: 400, color: AppColors.textMuted);

  /// Мелкая ссылка в углу карточки. «Все».
  static TextStyle get linkSmall =>
      _style(size: 12, weight: 500, color: AppColors.primary);

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

  // ─── Экраны врача ────────────────────────────────────────────────────────
  // Кегли подобраны по ширине краски строк, а не по высоте прописных: у
  // белого текста на синем фоне широкий ореол сглаживания, и замер высоты
  // завышает кегль на 10-15 %. Строка из макета меряется по крайним
  // непрозрачным столбцам, тем же порогом рисуется в offscreen-картинку, и
  // берётся кегль с наименьшим расхождением. Опорные ширины из
  // `design/Профиль врача + запись.png`: «Имя Фамилия» — 152,
  // «Гастроэнтеролог» — 135, «Расписание» — 107, «Июль, 2026» — 132.

  /// Заголовок экрана в верхней строке. «О враче», «Ваша запись».
  static TextStyle get screenTitle =>
      _style(size: 19, weight: 400, color: AppColors.textOnPrimary);

  /// Имя врача в шапке.
  static TextStyle get doctorName =>
      _style(size: 23, weight: 400, color: AppColors.textOnPrimary);

  /// Специальность врача под именем.
  static TextStyle get doctorSpecialty =>
      _style(size: 16, weight: 500, color: AppColors.primary);

  /// Строка клиники — самая мелкая в шапке.
  static TextStyle get doctorClinic =>
      _style(size: 11, weight: 500, color: AppColors.primary);

  /// Текст чипа в шапке. «4.5», «Стаж 10 лет», «Алматы».
  static TextStyle get chipLabel =>
      _style(size: 14, weight: 400, color: AppColors.textPrimary);

  /// Заголовок карточки расписания. «Расписание», «Перенести запись».
  static TextStyle get cardTitleAccent =>
      _style(size: 19, weight: 400, color: AppColors.primaryBright);

  /// Заголовок карточки отзывов — мельче, чем у карточки расписания.
  static TextStyle get cardTitleDark =>
      _style(size: 17, weight: 400, color: AppColors.textPrimary);

  /// Месяц над лентой дней. «Июль, 2026».
  static TextStyle get monthTitle =>
      _style(size: 24, weight: 400, color: AppColors.textPrimary);

  /// Календарь: подпись дня недели, число в пилюле, время в слоте — один
  /// кегль на все три, так и в макете (краска «18» и «12:30» одной высоты).
  static TextStyle get calendarLabel =>
      _style(size: 15, weight: 400, color: AppColors.textPrimary);

  /// Надпись на парных кнопках. «Создать запись», «Сообщение».
  static TextStyle get actionTitle =>
      _style(size: 16, weight: 400, color: AppColors.textPrimary);

  /// Тело отзыва — мельче основного текста и в несколько строк.
  static TextStyle get reviewBody => _style(
    size: 13,
    weight: 400,
    color: AppColors.textSecondary,
    height: 1.45,
  );
}
