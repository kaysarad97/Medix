// Шаблон: рендерит экран в PNG, чтобы замерить его теми же скриптами, что и
// макет. Копировать в test/ под своим именем, править секцию «настройка»,
// после замеров — удалять.
//
// Зачем отдельный файл, а не golden-тест: на macOS `--update-goldens`
// запускать нельзя (перезапишет эталоны, снятые на Windows). Здесь мы просто
// пишем PNG в скретчпад, эталонов не касаясь.
//
//   flutter test test/render_screen.dart
//
// Тег `golden` НЕ ставим — файл ничего не сверяет.
//
// Если фейки репозиториев не подставить, прогон упадёт на «timersPending»,
// но PNG к этому моменту уже записан и годится для замеров.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';

import 'helpers/test_fonts.dart';

/// Куда положить снимок. Скретчпад сессии, а не репозиторий.
const _out = '/tmp/render/screen.png';

/// Своя граница перерисовки: у `MaterialApp` её нет, снимать нечего.
final _boundary = GlobalKey();

void main() {
  setUpAll(loadAppFonts);

  testWidgets('снимок экрана для замеров', (tester) async {
    // ── настройка ────────────────────────────────────────────────────────
    // Размер — из макета: ширина всегда 440, высота либо 956 (экран
    // устройства), либо полная высота PNG, если страница прокручиваемая.
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    const screen = Placeholder(); // ← сюда экран
    // ─────────────────────────────────────────────────────────────────────

    await tester.pumpWidget(
      ProviderScope(
        // ← сюда фейки репозиториев из test/helpers/, синхронные
        overrides: const [],
        child: MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(key: _boundary, child: screen),
        ),
      ),
    );

    // Фон — картинка ассетом; без прогрева он не успевает отрисоваться.
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();

    await tester.runAsync(() async {
      final boundary =
          _boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose(); // иначе тест висит на неотпущенном ресурсе

      final file = File(_out);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      // ignore: avoid_print
      print('снимок: ${file.path}');
    });
  });
}
