import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Индикатор шага в мастере регистрации.
///
/// Геометрия из макетов регистрации: ширина 273, высота 10, полное
/// скругление; заполненная часть — [AppColors.brandIndigo], трек —
/// [AppColors.accent].
///
/// Заполнение задаётся долей, а не парой «шаг из N», потому что в макетах
/// значения проставлены вручную и на равные доли не ложатся — см.
/// [RegistrationProgress].
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.progress,
    this.width = defaultWidth,
  }) : assert(
         progress >= 0 && progress <= 1,
         'progress задаётся долей от 0 до 1',
       );

  final double progress;
  final double width;

  static const double defaultWidth = 273;
  static const double _height = 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _height,
      child: ClipRRect(
        borderRadius: AppRadius.allPill,
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.accent, child: SizedBox.expand()),
            FractionallySizedBox(
              widthFactor: progress,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandIndigo,
                  borderRadius: AppRadius.allPill,
                ),
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заполнение прогресс-бара на каждом шаге регистрации.
///
/// Значения замерены по макетам, а не вычислены: дизайнер расставил их
/// вручную (30 / 50 / 70 / 100), поэтому равномерного шага тут нет.
abstract final class RegistrationProgress {
  /// `design/Создайте профиль.png`.
  static const double credentials = 0.313;

  /// `design/Ваши Данные.png`.
  static const double personalData = 0.511;

  /// `design/Введите код (ПУСТОЙ).png`.
  static const double verifyCode = 0.713;

  /// `design/Язык и пуш увед.png`.
  static const double appSettings = 0.868;

  /// `design/Политика конф и обработка инф.png` — бар залит полностью.
  static const double policy = 1.0;
}
