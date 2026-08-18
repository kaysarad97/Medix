import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Прогрев картинок, которые уже на экране, — перед снимком эталона.
///
/// Без него `Image.asset` не успевает декодироваться к моменту `expectLater`,
/// и в эталоне на месте картинки остаётся дырка. Перебором по дереву, а не
/// списком ассетов: список приходится дописывать при каждой новой картинке, и
/// ровно это забыли, когда у врачей появились портреты — эталоны «Мои Врачи»,
/// «Ваша Запись» и звонков пересняли с пустыми аватарками.
Future<void> precacheScreenImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
  await tester.pump();
}
