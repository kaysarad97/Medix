import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/medix_wait_view.dart';
import '../providers/session_providers.dart';

/// Заставка запуска по `design/Загрузка.png`.
///
/// Пока показывается, проверяем хранилище: есть сохранённая сессия — сразу
/// на главную, нет — на логин.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Заставка держится не меньше этого времени.
  ///
  /// Проверка хранилища занимает миллисекунды, и без задержки логотип
  /// мигнул бы одним кадром — выглядит как сбой отрисовки.
  ///
  /// Значение — полный цикл анимации логотипа: в `logo_animated.gif`
  /// 96 кадров с задержками 3–4 сотых, в сумме 3210 мс. Раньше стояло
  /// 900 мс, и анимация обрывалась на первой трети.
  static const Duration minimumVisible = Duration(milliseconds: 3210);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final started = DateTime.now();
    final hasSession = await ref.read(hasStoredSessionProvider.future);

    final elapsed = DateTime.now().difference(started);
    final left = SplashScreen.minimumVisible - elapsed;
    if (left > Duration.zero) await Future<void>.delayed(left);

    if (!mounted) return;
    context.go(hasSession ? Routes.home : Routes.login);
  }

  @override
  Widget build(BuildContext context) => const MedixWaitView();
}
