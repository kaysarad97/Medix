import 'dart:async';

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

  /// Верхняя граница ожидания, если сигнал «след сошёл на нет» так и не
  /// пришёл.
  ///
  /// Раньше заставка держалась фиксированные 2838 мс по таймеру
  /// (`MedixWaitView.inkGone`). На реальном телефоне живой замер —
  /// `debugPrint` на каждый декодированный кадр — показал: декодирование
  /// идёт ~42 мс/кадр вместо расчётных 33, и к 2838 мс декодер успевал
  /// дойти только до ~68-го кадра из 87 — след обрывался, не дойдя до
  /// конца. Теперь ждём сам кадр `MedixWaitView.inkGoneFrame` через
  /// `MedixWaitView.onInkGone`, а не время до него — уход с экрана не
  /// зависит от скорости декодирования на конкретном устройстве. Этот
  /// таймаут — только страховка на случай, если сигнал не придёт вовсе:
  /// например, в виджет-тестах картинка не декодируется совсем.
  static const Duration maxWait = Duration(milliseconds: 4500);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _inkGoneCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  void _handleInkGone() {
    if (!_inkGoneCompleter.isCompleted) _inkGoneCompleter.complete();
  }

  Future<void> _decide() async {
    // Оба запущены сразу — ждём того, кто закончит позже.
    final sessionFuture = ref.read(hasStoredSessionProvider.future);
    final inkGoneFuture = _inkGoneCompleter.future.timeout(
      SplashScreen.maxWait,
      onTimeout: () {},
    );

    final hasSession = await sessionFuture;
    await inkGoneFuture;

    if (!mounted) return;
    context.go(hasSession ? Routes.home : Routes.login);
  }

  @override
  Widget build(BuildContext context) =>
      MedixWaitView(onInkGone: _handleInkGone);
}
