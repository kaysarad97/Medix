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

  /// Подпись на пилюле плитки семьи. «Имя Фамилия», «Добавить профиль».
  ///
  /// Кегль выведен по длине подписи, а не взят из общих: «Добавить профиль»
  /// занимает 99 из 138 пикселей пилюли в `design/Профили семьи.png`. При
  /// 14, как у [cardItemTitle], подпись обрезается многоточием уже на
  /// макетной ширине, при 12 влезает целиком с запасом.
  static TextStyle get familyTileLabel =>
      _style(size: 12, weight: 400, color: AppColors.textPrimary);

  /// Готовый вопрос в чат-боте. «Хочу загрузить анализы».
  ///
  /// Кегль выведен по двум пилюлям разной длины: при отбивке p и кегле f
  /// ширины 167 и 197 дают f ≈ 13.
  static TextStyle get chatQuickReply =>
      _style(size: 13, weight: 400, color: AppColors.textPrimary);

  /// Мелкая ссылка в углу карточки. «Все».
  static TextStyle get linkSmall =>
      _style(size: 12, weight: 500, color: AppColors.primary);

  /// Крупная надпись на кнопке. «Войти».
  static TextStyle get buttonLg =>
      _style(size: 20, weight: 400, color: AppColors.textOnPrimary);

  /// Обычная надпись на кнопке. «Далее →».
  static TextStyle get buttonMd =>
      _style(size: 17, weight: 500, color: AppColors.textOnPrimary);

  /// Надпись на кнопке со значком слева. «Удалить профиль» внизу карточки
  /// члена семьи: там надпись мельче обычной кнопочной — размах краски по
  /// макету 13 против 16 у «Далее».
  static TextStyle get buttonSm =>
      _style(size: 14, weight: 400, color: AppColors.textOnPrimary);

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

  /// Крупная строка на экране ожидания. «подождите...».
  ///
  /// Кегль по ширине краски: в макете строка занимает 144.
  static TextStyle get waitTitle =>
      _style(size: 22, weight: 600, color: AppColors.primary);

  /// Пояснение под ней. «проверяем данные карты...» — 248 в макете.
  static TextStyle get waitSubtitle =>
      _style(size: 18, weight: 400, color: AppColors.primary);

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

  /// Заголовок карточки расписания. «Расписание», «Перенести запись»,
  /// «Предоплата записи».
  static TextStyle get cardTitleAccent =>
      _style(size: 19, weight: 400, color: AppColors.primaryBright);

  /// Крупная цена в блоке предоплаты. «15 000 ₸», «10 000 ₸» — замер по
  /// ширине краски «10.000 ₸» в `design/Предоплата - GOLD.png` (193 px).
  static TextStyle get priceHero =>
      _style(size: 34, weight: 600, color: AppColors.textPrimary);

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

  /// Таймер и статус на экране звонка. «0:36», «Вызов завершен».
  static TextStyle get callStatus =>
      _style(size: 15, weight: 400, color: AppColors.textOnPrimary);

  // ─── Экраны профиля ──────────────────────────────────────────────────────

  /// Имя в шапке профиля. В макете курсив, но в Golos Text курсивного
  /// начертания нет — см. пояснение в ProfileHeader.
  static TextStyle get profileName =>
      _style(size: 34, weight: 400, color: AppColors.textOnPrimary);

  /// Значение под именем: «мужчина», «6/12/1996».
  static TextStyle get profileMetaValue =>
      _style(size: 13, weight: 400, color: AppColors.textOnPrimary);

  /// Подпись под значением: «пол», «дата рождения».
  static TextStyle get profileMetaLabel =>
      _style(size: 13, weight: 400, color: AppColors.surfaceChip);

  /// Подпись уровня подписки под ромбом.
  static TextStyle get goldLabel =>
      _style(size: 15, weight: 400, color: AppColors.gold);

  /// Название анализа в списке. В макете переносится на две строки.
  static TextStyle get analysisName =>
      _style(size: 15, weight: 400, color: AppColors.textPrimary, height: 1.3);

  /// Значение анализа: «24.8 мкмоль/л».
  static TextStyle get analysisValue =>
      _style(size: 16, weight: 400, color: AppColors.textPrimary);

  /// Референсный интервал под названием. Мельче остальных подписей:
  /// «10.7 - 32.2 мкмоль/л» должно уместиться в колонку названия.
  static TextStyle get analysisReference =>
      _style(size: 11, weight: 500, color: AppColors.primaryBright);

  /// Тело отзыва — мельче основного текста и в несколько строк.
  /// «Итого» под корзиной — синяя и крупная.
  ///
  /// Кегль не снят попиксельно: `design/Моя корзина.png` выгружен
  /// шириной 450 вместо 440, а текст в нём мелкий — по стойкам глифов
  /// высота не читается. Взят на глаз по соседним заголовкам.
  static TextStyle get cartTotal =>
      _style(size: 22, weight: 400, color: AppColors.primaryBright);

  /// Сумма справа от «Итого» — того же кегля, приглушённая.
  static TextStyle get cartTotalValue =>
      _style(size: 22, weight: 400, color: AppColors.textMuted);

  /// Цена позиции в корзине.
  static TextStyle get cartRowPrice =>
      _style(size: 16, weight: 400, color: AppColors.textMuted);

  static TextStyle get reviewBody => _style(
    size: 13,
    weight: 400,
    color: AppColors.textSecondary,
    height: 1.45,
  );
}
