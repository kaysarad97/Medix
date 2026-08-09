import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('принимает корректные адреса', () {
      expect(Validators.email('abcedfg@gmail.com'), isNull);
      expect(Validators.email('user.name+tag@medix.kz'), isNull);
    });

    test('отклоняет некорректные адреса', () {
      expect(Validators.email('abcedfg@'), isNotNull);
      expect(Validators.email('abcedfg.gmail.com'), isNotNull);
      expect(Validators.email('  '), isNotNull);
    });
  });

  group('Validators.otpCode', () {
    test('принимает шесть цифр — столько присылает бэкенд', () {
      expect(Validators.otpCode('123456'), isNull);
    });

    test('отклоняет другую длину и нецифровые символы', () {
      expect(Validators.otpCode('12345'), isNotNull);
      expect(Validators.otpCode('1234567'), isNotNull);
      expect(Validators.otpCode('12345a'), isNotNull);
      expect(Validators.otpCode(''), isNotNull);
    });
  });

  group('Validators.birthDate', () {
    test('принимает дату в формате бэкенда', () {
      expect(Validators.birthDate('1995-06-15'), isNull);
    });

    test('отклоняет пустое значение и мусор', () {
      expect(Validators.birthDate(''), isNotNull);
      expect(Validators.birthDate('15.06.1995'), isNotNull);
    });

    test('отклоняет дату в будущем', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final month = tomorrow.month.toString().padLeft(2, '0');
      final day = tomorrow.day.toString().padLeft(2, '0');

      expect(Validators.birthDate('${tomorrow.year}-$month-$day'), isNotNull);
    });

    test('отклоняет заведомо невозможный год', () {
      expect(Validators.birthDate('1850-01-01'), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('требует минимум два слова', () {
      expect(Validators.fullName('Дархан'), isNotNull);
      expect(Validators.fullName('Аркалыков Дархан'), isNull);
    });
  });
}
