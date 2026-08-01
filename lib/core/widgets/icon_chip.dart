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
}

abstract final class MedixIcons {
  /// TODO(design): дизайнер отдаёт SVG — сложить в assets/icons/
  /// и проставить пути здесь. Больше нигде править не нужно.
  static const Map<MedixIcon, String> _assets = {};

  static String? assetOf(MedixIcon icon) => _assets[icon];

  /// Все ли иконки на месте. Используется тестом, который напомнит убрать
  /// заглушки, когда экспорт приедет.
  static bool get allResolved => MedixIcon.values.every(_assets.containsKey);
}

/// Круглая подложка с иконкой внутри.
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
  final double size;
  final Color background;
  final Color foreground;

  static const double defaultSize = 48;

  /// Доля кружка, которую занимает глиф.
  static const double _glyphRatio = 0.5;

  @override
  Widget build(BuildContext context) {
    final asset = MedixIcons.assetOf(icon);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: asset == null
            ? const SizedBox.shrink()
            : Center(
                child: SvgPicture.asset(
                  asset,
                  width: size * _glyphRatio,
                  height: size * _glyphRatio,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                ),
              ),
      ),
    );
  }
}
