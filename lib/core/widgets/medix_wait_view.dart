import 'dart:ui' as ui;

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
    this.onInkGone,
  });

  /// Крутить анимацию логотипа вместо статичного знака.
  ///
  /// По умолчанию да: это экран ожидания, движение и означает, что
  /// приложение занято. Статичный знак нужен голден-тестам — анимация на
  /// каждом кадре разная, и попиксельная сверка на ней невозможна.
  final bool animated;

  /// Крупная строка под логотипом. Без неё получается заставка запуска.
  final String? title;

  /// Пояснение под [title].
  final String? subtitle;

  /// Зовётся один раз, когда декодирован кадр [inkGoneFrame] — след кисти
  /// сошёл на нет. Нужен заставке запуска, чтобы уходить по факту, а не по
  /// расчётному времени — см. её же комментарий у `minimumVisible`.
  final VoidCallback? onInkGone;

  /// Высота логотипа. Ширину задаёт сам знак: в макете глиф был 48×69, но
  /// присланный вектор шире по пропорции, и растягивать его нельзя.
  static const double logoHeight = 69;

  /// Анимация квадратная и показывается ровно в этот размер: файл собран
  /// под него, 288 пикселей при трёхкратной плотности.
  static const double animationSize = 96;

  /// Анимация прорисовки знака: кадры дизайнера, 87 кадров, 3,4 с при
  /// расчётных 33 мс/кадр.
  ///
  /// Кадры, а не вектор, — сознательно. Движение пробовали повторить дважды:
  /// обводкой силуэта из `logo_medix.svg` и восстановлением траектории кисти
  /// по кадрам. Оба раза заказчик сказал, что движение не то, и это честно —
  /// вектор даёт приближение, а сверяют с оригиналом.
  ///
  /// Исходники как есть не годились: гифка на 378 КБ не проигрывалась, 96
  /// кадров 625×625 распаковывались медленнее собственных задержек и знак
  /// замирал на первых штрихах, а `icons/BlueLogo.json` от дизайнера ещё
  /// тяжелее — 1,25 МБ. Здесь те же кадры, но ужатые с 625 до 288, то есть
  /// впятеро меньше пикселей: причина торможения снята, движение исходное.
  ///
  /// Пересобирается скриптом `tools/build_logo_webp.py`.
  static const String animationAsset = 'assets/images/logo_animated.webp';

  /// Кадр (по счёту декодирования, с 1), на котором след кисти сходит на
  /// нет — последний содержательный кадр перед пустым хвостом-паузой.
  ///
  /// Считаем по кадрам, а не по времени: расчётные 33 мс/кадр — это темп
  /// исходника, а не гарантия декодера. На реальном телефоне живой замер
  /// (`debugPrint` на каждый кадр через `ImageStreamListener`) показал
  /// ~42 мс/кадр — на четверть медленнее; к расчётным 2838 мс декодер
  /// успевал дойти только до ~68-го кадра из 87, и след обрывался,
  /// не дойдя до конца. Ждать сам кадр, а не время до него, — единственный
  /// способ не зависеть от скорости декодирования на конкретном устройстве.
  static const int inkGoneFrame = 86;

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
                _AnimatedLogo(
                  asset: animationAsset,
                  size: animationSize,
                  onFrame: onInkGone == null
                      ? null
                      : (frame) {
                          if (frame >= inkGoneFrame) onInkGone!();
                        },
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

/// Проигрывает анимированный WebP кадр за кадром через `ImageStream`
/// напрямую, а не `Image.asset`: нужен сам факт прихода кадра — сколько их
/// уже показано, — а не только картинка.
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo({required this.asset, required this.size, this.onFrame});

  final String asset;
  final double size;

  /// Зовётся на каждый декодированный кадр, начиная с 1.
  final ValueChanged<int>? onFrame;

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  int _frameCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newStream = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (newStream.key != _stream?.key) {
      _stream?.removeListener(_listener!);
      _listener = ImageStreamListener(_handleFrame, onError: _handleError);
      _stream = newStream;
      _stream!.addListener(_listener!);
    }
  }

  void _handleFrame(ImageInfo info, bool sync) {
    _frameCount++;
    widget.onFrame?.call(_frameCount);
    setState(() => _image = info.image);
  }

  /// Без картинки анимация не показывается, но экран не должен падать
  /// из-за этого — молча остаёмся на пустом месте нужного размера.
  void _handleError(Object error, StackTrace? stack) {}

  @override
  void dispose() {
    _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    return RawImage(
      image: _image,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }
}
