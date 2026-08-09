import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'shared/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Фон экранов светлый — иконки статус-бара тёмные, как в макетах.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  // Настройки читаются до первого кадра: язык нужен уже в MaterialApp,
  // иначе интерфейс мигнёт русским и переключится на глазах пользователя.
  final preferences = await SharedPreferences.getInstance();

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
