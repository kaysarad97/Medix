import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bottom_nav_bar.dart';

/// Обёртка над четырьмя ветками нижней навигации (Домой/Карта/Чаты/Профиль).
///
/// Каждый экран ветки — свой [AppScaffold] со своим фоном; здесь только
/// плавающий таб-бар в `bottomNavigationBar`. Вложенный `Scaffold` — обычная
/// практика для `StatefulShellRoute`.
///
/// `extendBody` обязателен: таб-бар — плавающая таблетка с полями по 10 от
/// краёв, и вокруг неё должен просвечивать фон экрана. Без него внешний
/// `Scaffold` отрезает под бар отдельную полосу, куда фоновая картинка ветки
/// уже не достаёт, а закрасить её нечем — `scaffoldBackgroundColor` в теме
/// прозрачный, и полоса выходит чёрной.
///
/// Взамен `Scaffold` прибавляет высоту бара к нижнему отступу в `MediaQuery`
/// тела. Экраны веток с `SafeArea` разбирают его сами; те, что отключили
/// нижнюю границу ради фона под самый край, дотягивают отступ в конце
/// прокрутки — иначе последняя карточка уедет под таблетку.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: BottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
