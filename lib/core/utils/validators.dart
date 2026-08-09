import '../constants/app_constants.dart';

/// Валидаторы форм. Возвращают текст ошибки или `null`, если значение верно.
abstract final class Validators {
  static final RegExp _email = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите e-mail';
    if (!_email.hasMatch(v)) return 'Некорректный e-mail';
    return null;
  }

  /// Номер телефона РК: 11 цифр, начинается с 7.
  ///
  /// Разделители, скобки и ведущий «+» игнорируются; «8» в начале
  /// приводится к «7» — так набирают внутри страны.
  static String? phone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Введите номер телефона';

    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8')) digits = '7${digits.substring(1)}';

    if (digits.length != 11 || !digits.startsWith('7')) {
      return 'Номер в формате +7 XXX XXX XX XX';
    }
    return null;
  }

  /// ФИО: минимум два слова из букв (кириллица или латиница).
  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите ФИО';

    final parts = v.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return 'Укажите фамилию и имя';

    final word = RegExp(r"^[А-Яа-яЁёA-Za-z][А-Яа-яЁёA-Za-z'-]*$");
    if (parts.any((p) => !word.hasMatch(p))) {
      return 'Только буквы, дефис и апостроф';
    }

    return null;
  }

  /// Одноразовый код из письма: [length] цифр.
  static String? otpCode(
    String? value, {
    int length = AppConstants.otpCodeLength,
  }) {
    final v = value?.trim() ?? '';
    if (v.length != length || !_digitsOnly.hasMatch(v)) {
      return 'Код состоит из $length цифр';
    }
    return null;
  }

  /// Дата рождения в формате `ГГГГ-ММ-ДД` — так её ждёт бэкенд.
  ///
  /// Значение приходит с выбора даты, поэтому разбор здесь — страховка от
  /// пустого поля, а не разбор произвольного ввода. Дата в будущем и
  /// невозможный год отсекаются отдельно: и то и другое означает промах по
  /// колесу выбора, а не реальную дату.
  static String? birthDate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Укажите дату рождения';

    final parsed = DateTime.tryParse(v);
    if (parsed == null) return 'Некорректная дата';

    final now = DateTime.now();
    if (parsed.isAfter(now)) return 'Дата рождения не может быть в будущем';
    if (parsed.year < now.year - 120) return 'Проверьте год рождения';

    return null;
  }
}
