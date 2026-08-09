import 'package:flutter/widgets.dart';

/// Размеры экранов профиля, снятые с `design/Профиль.png` (440×1511),
/// `design/Настройки Клиента.png`, `design/Настройки Профиля.png` и
/// `design/Свяжитесь с нами.png` (все 440×956).
abstract final class ProfileMetrics {
  /// Поля экрана: карточки идут x 21…418.
  static const double screenH = 21;

  /// Радиус карточек — как на экранах врача, между `sm` и `md` из
  /// `AppRadius`. См. пояснение в `DoctorMetrics.radius`.
  static const double radius = 14;

  static const BorderRadius allRadius = BorderRadius.all(Radius.circular(14));

  /// Верхняя строка живёт в общем `ScreenTopBar`; до шапки профиля 38
  /// (низ строки 132 → верх аватара 170).
  static const double topBarToHeader = 38;

  // ─── Шапка профиля ─────────────────────────────────────────────────────

  /// Аватар: скруглённый квадрат 136×134 на x 24, y 181.
  static const double avatarLeft = 24;
  static const Size avatarSize = Size(136, 134);
  static const double avatarRadius = 24;

  /// Текстовая колонка справа от аватара начинается на x 160.
  static const double avatarToInfo = 16;

  /// Имя набрано в две строки с шагом 37 (краска 181…203 и 218…242).
  static const double nameLineHeight = 37;

  /// Имя → строка «мужчина / 6/12/1996».
  static const double nameToMeta = 16;

  /// Значение → подпись под ним (259…267 и 277…285).
  static const double metaValueToLabel = 4;

  /// Вторая колонка подписей начинается на x 300, то есть 140 от первой.
  static const double metaColumnGap = 140;

  /// Значок Gold: ромб 21 и подпись под ним.
  static const double goldIconSize = 21;
  static const double goldIconToLabel = 12;

  /// Шапка → первая карточка (низ аватара 315 → карточка 308).
  static const double headerToCards = 0;

  // ─── Карточки ──────────────────────────────────────────────────────────

  /// Внутренние поля карточек: содержимое начинается на 34 при карточке
  /// с 21.
  static const double cardPadding = 13;

  /// Между карточками верхнего уровня (629 → 660, 814 → 845).
  static const double cardGap = 31;

  /// Строка-заголовок карточки: кружок иконки 48 и шеврон справа.
  static const double sectionIconSize = 48;
  static const double sectionIconToTitle = 11;
  static const double sectionHeaderHeight = 50;

  /// Шеврон-ссылка в правом углу.
  static const double chevronSize = 14;

  // ─── Карточка «Мед-карта» ──────────────────────────────────────────────

  /// Поле ИИН: x 34…409, y 385…432.
  static const double fieldHeight = 48;

  /// Заголовок карточки → поле ИИН.
  static const double headerToField = 27;

  /// Поле ИИН → ряд плиток.
  static const double fieldToTiles = 21;

  /// Плитки «Рост», «Вес», «Возраст»: y 453…548.
  static const double tileHeight = 96;
  static const double tileGap = 22;

  /// Ряд плиток → поле «Место прописки».
  static const double tilesToField = 21;

  // ─── Карточка «Мои Врачи» ──────────────────────────────────────────────

  /// Карточка врача: y 712…799.
  static const double doctorCardHeight = 88;
  static const double doctorCardWidth = 205;
  static const double doctorCardGap = 13;

  /// Заголовок → карусель врачей.
  static const double doctorsTitleToList = 16;

  /// Фото врача внутри карточки.
  static const double doctorPhotoSize = 56;

  // ─── Карточка «Моя Семья» ──────────────────────────────────────────────

  /// Замеры по `design/Профиль - GOLD.png`: карточка идёт после «Мои Врачи»,
  /// плашка участника белая, на сером теле карточки.
  ///
  /// Строка: y 994…1056.
  static const double familyRowHeight = 62;

  /// Аватар — кружок 44 (краска x 44…88) при плашке, начинающейся с 34.
  static const double familyAvatarSize = 44;
  static const double familyAvatarLeft = 10;

  /// Аватар → текст: кружок кончается на 88, краска имени с 106.
  static const double familyAvatarToText = 18;

  /// Имя → подпись роли (краска 1011…1021 и 1034…1040).
  static const double familyNameToRole = 4;

  /// Между строками участников. ЗАМЕРИТЬ НЕЧЕМ: в макете это место закрыто
  /// наложенным таб-баром — файл собран коллажем. Взят шаг карточек врачей
  /// (13), он же равен внутренним полям карточки.
  static const double familyRowGap = 13;

  // ─── Карточка «Ваши анализы» ───────────────────────────────────────────

  /// Переключатель вкладок: подложка x 38…402, высота 60.
  static const double toggleHeight = 60;
  static const double togglePadding = 7;

  /// Заголовок → переключатель.
  static const double titleToToggle = 14;

  /// Переключатель → первая строка анализа.
  static const double toggleToList = 16;

  /// Строка анализа: y 1070…1159.
  static const double analysisRowHeight = 90;
  static const double analysisRowGap = 12;

  /// Шкала справа: три отрезка по 39 и белая точка 8.
  static const double scaleWidth = 118;
  static const double scaleThickness = 6;
  static const double scaleDotSize = 12;

  // ─── Настройки ─────────────────────────────────────────────────────────

  /// Строка настроек с шевроном.
  static const double settingsRowHeight = 74;

  /// Между карточками настроек.
  static const double settingsGap = 24;

  /// Аватар в строке «Настройки профиля».
  static const double settingsAvatarSize = 48;

  /// Переключатель уведомлений.
  static const Size switchSize = Size(64, 36);

  /// Пилюли выбора языка.
  static const double languagePillHeight = 48;
  static const double languagePillGap = 12;

  // ─── Настройки профиля ─────────────────────────────────────────────────

  /// Крупный аватар: 130×140 по центру.
  static const Size profileAvatarSize = Size(130, 140);
  static const double profileAvatarToCaption = 12;
  static const double captionToForm = 46;

  /// Поле формы и зазор между полями.
  static const double formFieldHeight = 46;
  static const double formFieldGap = 12;

  // ─── Свяжитесь с нами ──────────────────────────────────────────────────

  /// Синяя карточка с телефонами.
  static const double contactPhonesHeight = 216;

  /// Голубая карточка с почтой и соцсетями.
  static const double contactMailHeight = 208;

  /// Кружки соцсетей.
  static const double socialSize = 32;
  static const double socialGap = 12;
}
