import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/widgets/medix_wait_view.dart';
import 'shared/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Фон экранов светлый — иконки статус-бара тёмные, как в макетах.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  // Настройки читаются до первого кадра: язык нужен уже в MaterialApp,
  // иначе интерфейс мигнёт русским и переключится на глазах пользователя.
  final preferences = await SharedPreferences.getInstance();

  // Логотип заставки греем здесь же. Пока идёт нативный экран запуска,
  // декодирование ничего не задерживает; если тянуть его до показа
  // заставки, оно съедает начало анимации — та успевает проиграться
  // не с первого кадра, хотя выдержка равна её полному циклу.
  await _warmUpSplashAnimation();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(
          SharedPreferencesService(preferences),
        ),
      ],
      child: const MedixApp(),
    ),
  );
}

/// Дожидается первого кадра анимации логотипа.
///
/// Без `BuildContext`: до `runApp` его нет, а `precacheImage` требует.
/// Ошибку глотаем — из-за неготовой картинки приложение не должно
/// отказываться запускаться.
Future<void> _warmUpSplashAnimation() {
  final completer = Completer<void>();
  final stream = const AssetImage(
    MedixWaitView.animationAsset,
  ).resolve(ImageConfiguration.empty);

  late final ImageStreamListener listener;
  void finish() {
    if (!completer.isCompleted) completer.complete();
    stream.removeListener(listener);
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return completer.future;
}
