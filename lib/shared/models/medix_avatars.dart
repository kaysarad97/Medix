/// Набор аватарок, зашитых в сборку.
///
/// Пользователь выбирает одну из них на экране «Настройки профиля» —
/// в макете это подпись «изменить аватара». Собственное фото загружается
/// отдельным presigned-сценарием и не смешивается с локальным выбором.
///
/// Дизайнер отдал их растром: в исходных SVG вектора не было, внутри
/// лежала та же картинка, и весил такой файл 1,5 МБ против 40 КБ у PNG.
abstract final class MedixAvatars {
  static const List<String> all = [
    'assets/images/avatars/avatar_01.png',
    'assets/images/avatars/avatar_02.png',
    'assets/images/avatars/avatar_03.png',
    'assets/images/avatars/avatar_04.png',
    'assets/images/avatars/avatar_05.png',
    'assets/images/avatars/avatar_06.png',
    'assets/images/avatars/avatar_07.png',
    'assets/images/avatars/avatar_08.png',
    'assets/images/avatars/avatar_09.png',
    'assets/images/avatars/avatar_10.png',
    'assets/images/avatars/avatar_11.png',
    'assets/images/avatars/avatar_12.png',
  ];

  /// Та, что стоит у пользователя, пока он не выбрал другую.
  static const String fallback = 'assets/images/avatars/avatar_01.png';
}
