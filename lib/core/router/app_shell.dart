import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bottom_nav_bar.dart';

/// Обёртка над четырьмя ветками нижней навигации (Домой/Карта/Чаты/Профиль).
///
/// Каждый экран ветки — свой [AppScaffold] со своим фоном; здесь только
/// плавающий таб-бар в `bottomNavigationBar`. Вложенный `Scaffold` — обычная
/// практика для `StatefulShellRoute`: внешний резервирует место под бар,
/// внутренний экрана просто рисуется в оставшейся высоте.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
