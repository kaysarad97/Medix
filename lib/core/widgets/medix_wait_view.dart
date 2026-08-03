import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_scaffold.dart';

/// Экран ожидания с логотипом: заставка при запуске и любые паузы, когда
/// приложение чего-то ждёт.
///
/// Свёрстан по `design/Загрузка.png` (только логотип) и
/// `design/Подождите....png` (логотип с подписями).
class MedixWaitView extends StatelessWidget {
  const MedixWaitView({
    super.key,
    this.title,
    this.subtitle,
    this.animated = true,
  });

  /// Крутить анимацию логотипа вместо статичного знака.
  ///
  /// По умолчанию да: это экран ожидания, движение и означает, что
  /// приложение занято. Статичный знак нужен голден-тестам — GIF на каждом
  /// кадре разный, и попиксельная сверка на нём невозможна.
  final bool animated;

  /// Крупная строка под логотипом. Без неё получается заставка запуска.
  final String? title;

  /// Пояснение под [title].
  final String? subtitle;

  /// Высота логотипа. Ширину задаёт сам знак: в макете глиф был 48×69, но
  /// присланный вектор шире по пропорции, и растягивать его нельзя.
  static const double logoHeight = 69;

  /// Анимация квадратная, 625×625.
  static const double animationSize = 96;

  /// Верх логотипа при безопасной зоне 62.
  static const double _logoTop = 388;

  /// Логотип 450…518 → строка «подождите...» 649.
  static const double _logoToTitle = 126;

  /// Между строками подписи.
  static const double _titleToSubtitle = 16;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // ПРИБЛИЖЕНИЕ. У «Загрузка.png» и «Подождите....png» свои градиенты,
      // не совпадающие ни с фон.png, ни с BG.png, ни друг с другом, а
      // отдельными файлами их в design/ нет — они вплавлены в макеты.
      // TODO(design): попросить экспорт обоих фонов, как сделали с иконками.
      background: AppBackgroundStyle.auth,
      child: SafeArea(
        // Ширину задаём явно: Scaffold отдаёт телу нежёсткие ограничения по
        // ширине, и Column с выравниванием по центру ужался бы до самого
        // широкого потомка — содержимое встало бы у левого края.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: _logoTop),
              // В макете центр логотипа стоит на x 238 при центре экрана 220.
              // Ставим по центру: смещение в 4 % ширины на телефоне читается
              // как промах вёрстки, а не как замысел.
              if (animated)
                // Гифка идёт как прислал дизайнер: знак в ней синий, а на
                // макетах белый. Перекрасить покадровую анимацию нельзя —
                // либо дизайнер отдаёт белый вариант, либо остаётся синий.
                Image.asset(
                  'assets/images/logo_animated.gif',
                  width: animationSize,
                  height: animationSize,
                  fit: BoxFit.contain,
                )
              else
                SvgPicture.asset(
                  'assets/images/logo_medix.svg',
                  height: logoHeight,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textOnPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              if (title != null) ...[
                const SizedBox(height: _logoToTitle),
                Text(title!, style: AppTypography.waitTitle),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: _titleToSubtitle),
                Text(subtitle!, style: AppTypography.waitSubtitle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
