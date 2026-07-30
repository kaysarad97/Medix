import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/utils/validators.dart';

void main() {
  group('Validators.iin', () {
    test('принимает ИИН с верной контрольной суммой', () {
      // 950815 350 12 + контрольный разряд 3 (веса 1…11, остаток от 11).
      expect(Validators.iin('950815350123'), isNull);
    });

    test('отклоняет ИИН с неверным контрольным разрядом', () {
      expect(Validators.iin('950815350124'), isNotNull);
    });

    test('отклоняет неверную длину и нецифровые символы', () {
      expect(Validators.iin('95081535012'), isNotNull);
      expect(Validators.iin('9508153501２3'), isNotNull);
      expect(Validators.iin(''), isNotNull);
    });
  });

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

  group('Validators.emailOrIin', () {
    test('одни цифры проверяются как ИИН', () {
      expect(Validators.emailOrIin('950815350123'), isNull);
      expect(Validators.emailOrIin('123'), isNotNull);
    });

    test('всё остальное проверяется как e-mail', () {
      expect(Validators.emailOrIin('abcedfg@gmail.com'), isNull);
      expect(Validators.emailOrIin('не-почта'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('требует минимум 8 символов', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
  });
}
