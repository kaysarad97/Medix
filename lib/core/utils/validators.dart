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
    if (parts.any((p) => !word.hasMatch(p)))
      return 'Только буквы, дефис и апостроф';

    return null;
  }

  /// Повтор пароля должен совпадать с исходным.
  static String? passwordConfirmation(String? value, String? original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Повторите пароль';
    if (v != (original ?? '')) return 'Пароли не совпадают';
    return null;
  }

  /// Код подтверждения из СМС: [length] цифр.
  static String? smsCode(String? value, {int length = 5}) {
    final v = value?.trim() ?? '';
    if (v.length != length || !_digitsOnly.hasMatch(v)) {
      return 'Код состоит из $length цифр';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < 8) return 'Минимум 8 символов';
    return null;
  }

  /// Поле «Ваш E-mail или ИИН»: если введены одни цифры — проверяем как ИИН,
  /// иначе как e-mail.
  static String? emailOrIin(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите e-mail или ИИН';
    if (_digitsOnly.hasMatch(v)) return iin(v);
    return email(v);
  }

  /// ИИН РК: 12 цифр с контрольной суммой.
  ///
  /// Алгоритм: контрольный разряд — остаток от деления на 11 суммы
  /// произведений первых 11 цифр на веса 1…11. Если остаток равен 10,
  /// расчёт повторяется со вторым набором весов; если и он даёт 10 —
  /// такой ИИН не существует.
  static String? iin(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите ИИН';
    if (v.length != AppConstants.iinLength || !_digitsOnly.hasMatch(v)) {
      return 'ИИН состоит из ${AppConstants.iinLength} цифр';
    }

    final digits = v.split('').map(int.parse).toList(growable: false);

    const weights1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const weights2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];

    int checksum(List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += digits[i] * weights[i];
      }
      return sum % 11;
    }

    var control = checksum(weights1);
    if (control == 10) control = checksum(weights2);
    if (control == 10 || control != digits.last) return 'Некорректный ИИН';

    return null;
  }
}
