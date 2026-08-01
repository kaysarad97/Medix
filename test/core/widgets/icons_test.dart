import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/widgets/icon_chip.dart';

/// Иконки подключаются по одной карте в [MedixIcons], и промах там ничем не
/// проявляется: на месте иконки просто пустота нужного размера. Поэтому
/// карта проверяется тестом.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('у каждой иконки есть файл', () {
    final missing = MedixIcon.values
        .where((icon) => MedixIcons.assetOf(icon) == null)
        .toList();
    expect(missing, isEmpty, reason: 'нет экспорта для: $missing');
    expect(MedixIcons.allResolved, isTrue);
  });

  test('пути ведут только в assets/icons и не содержат кириллицы', () {
    for (final icon in MedixIcon.values) {
      final asset = MedixIcons.assetOf(icon)!;
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

  test('все файлы лежат в сборке', () async {
    for (final icon in MedixIcon.values) {
      final asset = MedixIcons.assetOf(icon)!;
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: '$icon: $asset пуст');
    }
  });

  test('разным иконкам соответствуют разные файлы', () {
    final assets = MedixIcon.values.map(MedixIcons.assetOf).toList();
    expect(assets.toSet().length, assets.length);
  });
}
