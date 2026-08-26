import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Подключает Onest в тестовом окружении.
///
/// Без этого Flutter подставляет заглушку с квадратами фиксированной
/// ширины: текст оказывается заметно шире настоящего, заголовки переносятся
/// на вторую строку и вся вертикальная раскладка едет. Любой тест, который
/// проверяет геометрию или рендер, обязан вызвать это в `setUpAll`.
Future<void> loadAppFonts() async {
  await (FontLoader(
    'GolosText',
  )..addFont(rootBundle.load('assets/fonts/GolosText-Variable.ttf'))).load();

  // Иначе стрелка «Далее →» и «глаз» в поле пароля рисуются пустыми
  // квадратами и golden-сверка по ним ничего не показывает.
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}
