import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/widgets/icon_chip.dart';

/// Иконки подключаются по одной карте в [MedixIcons], и промах там ничем не
/// проявляется: на месте иконки просто пустота нужного размера. Поэтому
/// карта проверяется тестом.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('каждая иконка либо подключена, либо честно числится ожидаемой', () {
    final missing = MedixIcon.values
        .where(
          (icon) =>
              MedixIcons.assetOf(icon) == null &&
              !MedixIcons.pending.contains(icon),
        )
        .toList();
    expect(
      missing,
      isEmpty,
      reason:
          'нет экспорта и нет в MedixIcons.pending: $missing. '
          'Либо подключить файл, либо внести в список ожидаемых.',
    );
  });

  test('ожидаемые иконки не подключены — иначе список протух', () {
    final stale = MedixIcons.pending
        .where((icon) => MedixIcons.assetOf(icon) != null)
        .toList();
    expect(
      stale,
      isEmpty,
      reason: 'файлы уже есть, вычеркнуть из MedixIcons.pending: $stale',
    );
  });

  test('пути ведут только в assets/icons и не содержат кириллицы', () {
    for (final icon in MedixIcon.values) {
      final asset = MedixIcons.assetOf(icon);
      if (asset == null) continue;
      expect(asset, startsWith('assets/icons/'));
      expect(asset, endsWith('.svg'));
      // Путь с не-ASCII символами роняет сборку Android ещё до компиляции.
      expect(
        asset.codeUnits.every((c) => c < 128),
        isTrue,
        reason: '$icon: путь с не-ASCII символами — $asset',
      );
    }
  });

  test('все подключённые файлы лежат в сборке', () async {
    for (final icon in MedixIcon.values) {
      final asset = MedixIcons.assetOf(icon);
      if (asset == null) continue;
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: '$icon: $asset пуст');
    }
  });

  test('разным иконкам соответствуют разные файлы', () {
    final assets = MedixIcon.values
        .map(MedixIcons.assetOf)
        .whereType<String>()
        .toList();
    expect(assets.toSet().length, assets.length);
  });
}
