/// Портреты врачей из набора дизайнера.
///
/// Сервер фотографий врачей не отдаёт вовсе — в каталоге, чатах и звонках на
/// их месте стояли цветные заглушки из макетов. Восемь портретов лежат в
/// `assets/images/doctors/`; исходники дизайнера в `icons/` называются
/// латиницей с пробелами и скобками, поэтому в assets они переименованы —
/// кириллица и пробелы в пути ломают сборку Android.
///
/// Последний портрет — врач с младенцем на руках. В общей раздаче он может
/// достаться кому угодно, вплоть до кардиолога; если это мешает, его стоит
/// вычеркнуть из [all], а не подбирать по специальности — специальностей на
/// сервере открытый список.
abstract final class MedixDoctorPhotos {
  static const List<String> all = [
    'assets/images/doctors/doctor_01.png',
    'assets/images/doctors/doctor_02.png',
    'assets/images/doctors/doctor_03.png',
    'assets/images/doctors/doctor_04.png',
    'assets/images/doctors/doctor_05.png',
    'assets/images/doctors/doctor_06.png',
    'assets/images/doctors/doctor_07.png',
    'assets/images/doctors/doctor_08.png',
  ];

  /// Лицо по строке-ключу: идентификатор врача, а где его нет — имя или
  /// название специальности.
  ///
  /// Считается по кодам символов, а не через `hashCode`: один и тот же врач
  /// должен выглядеть одинаково и в каталоге, и в чате, и на звонке, и —
  /// главное — на эталонах golden, которые снимаются в другой сборке.
  static String forSeed(String seed) {
    var sum = 0;
    for (final unit in seed.codeUnits) {
      sum = (sum + unit) % all.length;
    }
    return all[sum];
  }
}
