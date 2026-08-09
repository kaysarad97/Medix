import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Проверка правила навигации, а не поведения экрана.
///
/// Домой, Карта, Чаты и Профиль — ветки `StatefulShellRoute`. Их переключают
/// через `go`. Если толкнуть ветку через `push`, go_router поднимает вторую
/// копию оболочки, у веток внутри те же глобальные ключи — и навигатор
/// падает на `!keyReservation.contains(key)`. Экран при этом выглядит
/// рабочим до самого нажатия, поэтому ошибку легко внести заново.
///
/// Настоящий тест навигации потребовал бы поднять роутер целиком и подменить
/// репозитории всех экранов сразу. Здесь дешевле прочитать исходники.
void main() {
  test('ветки нижней навигации нигде не открываются через push', () {
    const branches = [
      'Routes.home',
      'Routes.mapSearch',
      'Routes.chats',
      'Routes.profile',
    ];

    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final branch in branches) {
          // Скобка на конце обязательна: `Routes.profileSettings` — это
          // отдельный маршрут вне оболочки, его толкать можно.
          final pattern = RegExp('push\\(\\s*${RegExp.escape(branch)}\\s*\\)');
          if (pattern.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1} → $branch');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Ветку нижней навигации нельзя открывать через push — навигатор '
          'упадёт на повторных глобальных ключах. Нужен go:\n'
          '${offenders.join('\n')}',
    );
  });
}
