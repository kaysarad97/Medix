import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Иконки, которые встречаются в макетах.
///
/// В `design/` они лежат только внутри PNG-скриншотов глифами по ~24 px —
/// вытащить оттуда пригодный вектор нельзя. Дизайнер экспортирует SVG
/// отдельно; до тех пор [MedixIcons.assetOf] возвращает `null`, и на месте
/// иконки рисуется пустой кружок нужного размера и цвета.
enum MedixIcon {
  /// Пробирка. «Сдать анализы».
  labTest,

  /// Телефонная трубка. «Запись к врачу».
  doctorCall,

  /// Планшет с зажимом. «Найти лабораторию или больницу».
  mapSearch,

  /// Таблетки. «Загрузить анализы».
  uploadAnalyses,

  /// Календарь. «Предстоящие записи».
  calendar,

  /// Пульс в сердце. Строка записи к врачу.
  appointment,

  /// Колокольчик. Чип уведомлений в шапке.
  notifications,

  /// Реплика чата. Поле «Опишите Ваши симптомы».
  symptomSearch,

  /// Закрашенная звезда. Чип рейтинга врача и оценка в отзыве.
  star,

  /// Наполовину закрашенная звезда. Рейтинг 4.5 в макете.
  starHalf,

  /// Контур звезды. Незаполненная часть оценки.
  starOutline,

  /// Метка на карте. Чип города в шапке врача.
  locationPin,

  /// Видеокамера. Экран видео-звонка.
  ///
  /// НЕ кнопка «Создать запись»: там в макете трубка, хотя подпись
  /// «Видео-звонок» — см. [audioCall].
  videoCall,

  /// Телефонная трубка со звуковыми волнами. Обе кнопки звонка на экранах
  /// врача: «Создать запись / Видео-звонок» и «Начать звонок / Аудио-звонок».
  audioCall,

  /// Конверт. Кнопка «Сообщение» в карточке расписания и строка записи.
  mail,

  /// Облачко чата. Кнопка «Сообщение» на экране записи.
  chat,

  /// Лист с карандашом. Поле «Оставьте свой отзыв».
  reviewCompose,

  /// Человечек в кружке. Автор отзыва.
  userAvatar,

  /// Шеврон вправо. Строки-ссылки на экранах профиля.
  chevronRight,

  /// Шестерёнка. Переход в настройки из шапки профиля.
  settings,

  /// Папка. Заголовок карточки «Мед-карта».
  medicalCard,

  /// Линейка. Плитка «Рост».
  height,

  /// Весы. Плитка «Вес».
  weight,

  /// Улыбка. Плитка «Возраст».
  age,

  /// Лист с бланком. «Предыдущие процедуры».
  procedures,

  /// Карандаш. «Ваши анализы».
  analyses,

  /// Ромб. Значок подписки Gold в шапке профиля.
  subscriptionGold,

  /// Instagram. Блок соцсетей на экране «Свяжитесь с нами».
  instagram,

  /// WhatsApp. Там же.
  whatsapp,

  /// Логотип Kaspi.kz. Экран выбора способа оплаты.
  paymentKaspi,

  /// Логотип Halyk Bank. Там же.
  paymentHalyk,

  /// Кнопка Apple Pay. Там же.
  paymentApplePay,

  /// Банковская карта: «другие банки» и «Сохранённые карты».
  paymentCard,

  /// Скрепка. Прикрепить файл в переписке с ботом.
  attachment,

  /// Медицинский чемоданчик. Аватар бота в переписке.
  botAvatar,

  /// Лупа. Поиск по списку чатов.
  search,

  /// Здание с крестом. Метка больницы на карте и вкладка «Больницы».
  hospital,

  /// Домик. Таб «Домой» в нижней навигации.
  navHome,

  /// Карта-книжка. Таб «Карта» в нижней навигации.
  navMap,

  /// Квадратные пузыри чата. Таб «Чаты» в нижней навигации.
  navChats,

  /// Человечек в кружке. Таб «Профиль» в нижней навигации.
  navProfile,
}

abstract final class MedixIcons {
  /// Экспорт дизайнера. Имена файлов — по значению [MedixIcon], чтобы связь
  /// читалась без сверки со списком.
  ///
  /// Исходники лежат в `icons/` под своими именами из Figma; сюда они
  /// перекладываются с ASCII-именами: путь с кириллицей и пробелами ломает
  /// сборку Android (`non-ASCII characters` в Gradle).
  static const Map<MedixIcon, String> _assets = {
    MedixIcon.labTest: 'assets/icons/lab_test.svg',
    MedixIcon.doctorCall: 'assets/icons/doctor_call.svg',
    MedixIcon.mapSearch: 'assets/icons/map_search.svg',
    MedixIcon.uploadAnalyses: 'assets/icons/upload_analyses.svg',
    MedixIcon.calendar: 'assets/icons/calendar.svg',
    MedixIcon.appointment: 'assets/icons/appointment.svg',
    MedixIcon.notifications: 'assets/icons/notifications.svg',
    MedixIcon.symptomSearch: 'assets/icons/symptom_search.svg',
    MedixIcon.star: 'assets/icons/star.svg',
    MedixIcon.starHalf: 'assets/icons/star_half.svg',
    MedixIcon.starOutline: 'assets/icons/star_outline.svg',
    MedixIcon.locationPin: 'assets/icons/location_pin.svg',
    MedixIcon.videoCall: 'assets/icons/video_call.svg',
    MedixIcon.audioCall: 'assets/icons/audio_call.svg',
    MedixIcon.mail: 'assets/icons/mail.svg',
    MedixIcon.chat: 'assets/icons/chat.svg',
    MedixIcon.reviewCompose: 'assets/icons/review_compose.svg',
    MedixIcon.userAvatar: 'assets/icons/user_avatar.svg',
    MedixIcon.chevronRight: 'assets/icons/chevron_right.svg',
    MedixIcon.settings: 'assets/icons/settings.svg',
    MedixIcon.medicalCard: 'assets/icons/medical_card.svg',
    MedixIcon.height: 'assets/icons/height.svg',
    MedixIcon.weight: 'assets/icons/weight.svg',
    MedixIcon.age: 'assets/icons/age.svg',
    MedixIcon.procedures: 'assets/icons/procedures.svg',
    MedixIcon.analyses: 'assets/icons/analyses.svg',
    MedixIcon.subscriptionGold: 'assets/icons/subscription_gold.svg',
    MedixIcon.instagram: 'assets/icons/instagram.svg',
    MedixIcon.whatsapp: 'assets/icons/whatsapp.svg',
    MedixIcon.paymentKaspi: 'assets/icons/payment_kaspi.svg',
    MedixIcon.paymentHalyk: 'assets/icons/payment_halyk.svg',
    MedixIcon.paymentApplePay: 'assets/icons/payment_apple_pay.svg',
    MedixIcon.paymentCard: 'assets/icons/payment_card.svg',
    MedixIcon.attachment: 'assets/icons/attachment.svg',
    MedixIcon.search: 'assets/icons/search.svg',
    MedixIcon.hospital: 'assets/icons/hospital.svg',
    MedixIcon.navHome: 'assets/icons/nav_home.svg',
    MedixIcon.navMap: 'assets/icons/nav_map.svg',
    MedixIcon.navChats: 'assets/icons/nav_chats.svg',
    MedixIcon.navProfile: 'assets/icons/nav_profile.svg',
  };

  /// Иконки, экспорта которых ещё нет.
  ///
  /// Список ведётся руками и проверяется тестом: иначе недостающая иконка
  /// не проявится ничем — на её месте просто пустота нужного размера, и по
  /// готовому экрану пропажу не заметить. Пополнять при добавлении новых
  /// значений [MedixIcon] и вычёркивать, когда файл приехал.
  static const Set<MedixIcon> pending = {
    // Медицинский чемоданчик — аватар бота в переписке. На макете есть,
    // в экспорте дизайнера нет.
    MedixIcon.botAvatar,
  };

  static String? assetOf(MedixIcon icon) => _assets[icon];

  /// Все ли иконки на месте.
  static bool get allResolved => MedixIcon.values.every(_assets.containsKey);
}

/// Глиф без подложки.
///
/// [size] — размер самого глифа, в отличие от [AppIconChip], где это диаметр
/// кружка. Цвет перекрашивается целиком: экспорт приходит в разных цветах
/// (`#0E0777`, `#1719C3`, `#212528`), а на экранах иконка бывает и белой.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = AppColors.brandIndigo,
  });

  final MedixIcon icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = MedixIcons.assetOf(icon);
    if (asset == null) {
      // Экспорт ещё не приехал — держим место, чтобы вёрстка не прыгала.
      return SizedBox(width: size, height: size);
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Иконка в исходных цветах, без перекрашивания.
///
/// Нужна логотипам платёжных систем: Kaspi красный, Halyk зелёно-жёлтый,
/// Apple Pay чёрный. Заливать их одним цветом, как [AppIcon], нельзя —
/// это фирменная символика.
class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, required this.icon, this.size = 24});

  final MedixIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = MedixIcons.assetOf(icon);
    if (asset == null) return SizedBox(width: size, height: size);
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

/// Круглая подложка с глифом внутри.
///
/// Размеры из `design/Главная.png`: кружок 48, глиф внутри ~24.
class AppIconChip extends StatelessWidget {
  const AppIconChip({
    super.key,
    required this.icon,
    this.size = defaultSize,
    this.background = AppColors.accentSoft,
    this.foreground = AppColors.brandIndigo,
  });

  final MedixIcon icon;

  /// Диаметр кружка. Глиф внутри — половина от него.
  final double size;

  final Color background;
  final Color foreground;

  static const double defaultSize = 48;

  /// Доля кружка, которую занимает глиф.
  static const double _glyphRatio = 0.5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(
          child: AppIcon(
            icon: icon,
            size: size * _glyphRatio,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
