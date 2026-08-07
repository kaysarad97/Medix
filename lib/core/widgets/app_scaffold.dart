import 'package:flutter/material.dart';

/// Какой фон подложить под экран.
enum AppBackgroundStyle {
  /// Mesh-градиент экранов авторизации (`design/фон.png`), осветлённый белым.
  auth,

  /// Вертикальный градиент основных экранов (`design/BG.png`).
  main,

  /// Тёмно-синий вертикальный градиент экранов звонка (`design/BG (1).png`).
  call,
}

/// Экран MedIx: фоновая картинка из макетов + прозрачный [Scaffold].
///
/// Фоны вынесены в ассеты, а не воспроизведены градиентами в коде: в макетах
/// это многоцентровые mesh-градиенты, которые кодом точно не повторить.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.background = AppBackgroundStyle.auth,
    this.resizeToAvoidBottomInset = true,
    this.appBar,
  });

  final Widget child;
  final AppBackgroundStyle background;
  final bool resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBar;

  static const Map<AppBackgroundStyle, String> _assets = {
    AppBackgroundStyle.auth: 'assets/images/auth_bg.png',
    AppBackgroundStyle.main: 'assets/images/app_bg.png',
    AppBackgroundStyle.call: 'assets/images/call_bg.png',
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Никаких фильтров поверх картинки: фоны в `design/` несут чанки
          // gAMA/sRGB, Flutter применяет их сам и попадает в макет с
          // точностью 1–2 уровня яркости (проверено golden-сверкой).
          Image.asset(_assets[background]!, fit: BoxFit.cover),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            appBar: appBar,
            body: child,
          ),
        ],
      ),
    );
  }
}
