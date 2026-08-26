import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/auth/data/repositories/auth_repository.dart';
import 'package:medix/features/auth/presentation/providers/registration_controller.dart';

import '../../helpers/auth_overrides.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer(overrides: authOverrides));
  tearDown(() => container.dispose());

  RegistrationController controller() =>
      container.read(registrationControllerProvider.notifier);
  RegistrationState state() => container.read(registrationControllerProvider);

  void fillEmail({String email = 'user@medix.kz'}) {
    controller().setField(RegField.email, email);
  }

  void fillPersonalData({
    String fullName = 'Аркалыков Дархан',
    String birthDate = '1995-06-15',
  }) {
    controller()
      ..setField(RegField.fullName, fullName)
      ..setField(RegField.birthDate, birthDate);
  }

  group('шаг 1 — почта', () {
    test('пустая форма даёт ошибку поля', () {
      expect(controller().submitEmail(), isFalse);
      expect(state().errorOf(RegField.email), isNotNull);
    });

    test('некорректный адрес не проходит', () {
      fillEmail(email: 'не-почта');

      expect(controller().submitEmail(), isFalse);
      expect(state().errorOf(RegField.email), isNotNull);
    });

    test('корректный адрес проходит без запроса к серверу', () {
      fillEmail();
      expect(controller().submitEmail(), isTrue);
      // Письмо уходит только на шаге 2 — здесь серверу нечего отправлять.
      expect(state().codeTtlSeconds, 0);
    });

    test('правка поля гасит его ошибку', () {
      controller().submitEmail();
      fillEmail();

      expect(state().errorOf(RegField.email), isNull);
    });
  });

  group('шаг 2 — ФИО и дата рождения', () {
    test('ФИО из одного слова не пропускается', () async {
      fillEmail();
      fillPersonalData(fullName: 'Дархан');

      expect(await controller().submitPersonalData(), isFalse);
      expect(state().errorOf(RegField.fullName), 'Укажите фамилию и имя');
    });

    test('пустая дата рождения не пропускается', () async {
      fillEmail();
      fillPersonalData(birthDate: '');

      expect(await controller().submitPersonalData(), isFalse);
      expect(state().errorOf(RegField.birthDate), isNotNull);
    });

    test(
      'корректные данные отправляют письмо и дают время жизни кода',
      () async {
        fillEmail();
        fillPersonalData();

        expect(await controller().submitPersonalData(), isTrue);
        expect(state().codeTtlSeconds, MockAuthRepository.codeTtlSeconds);
        expect(state().isSubmitting, isFalse);
      },
    );

    test('занятая почта возвращается как ошибка формы, а не поля', () async {
      fillEmail(email: 'taken@medix.kz');
      fillPersonalData();

      expect(await controller().submitPersonalData(), isFalse);
      expect(state().formError, isNotNull);
      expect(state().errorOf(RegField.fullName), isNull);
      expect(state().isSubmitting, isFalse);
    });
  });

  group('шаг 3 — код из письма', () {
    test('код неверной длины отбивается до запроса', () async {
      controller().setField(RegField.code, '123');

      expect(await controller().submitCode(), isFalse);
      expect(state().errorOf(RegField.code), isNotNull);
    });

    test('неверный код возвращается как ошибка формы', () async {
      controller().setField(RegField.code, '000000');

      expect(await controller().submitCode(), isFalse);
      expect(state().formError, isNotNull);
      expect(state().errorOf(RegField.code), isNull);
    });

    test('верный код завершает регистрацию', () async {
      fillEmail();
      fillPersonalData();
      controller().setField(RegField.code, MockAuthRepository.validCode);

      expect(await controller().submitCode(), isTrue);
      expect(state().formError, isNull);
    });

    test('повторная отправка переиспользует данные шагов 1 и 2', () async {
      fillEmail();
      fillPersonalData();

      expect(await controller().resendCode(), isTrue);
      expect(state().value(RegField.email), 'user@medix.kz');
    });
  });

  test('данные шага 1 доживают до шага 3', () async {
    fillEmail(email: 'keep@medix.kz');
    fillPersonalData();
    controller().setField(RegField.code, MockAuthRepository.validCode);
    await controller().submitCode();

    expect(state().value(RegField.email), 'keep@medix.kz');
    expect(state().value(RegField.birthDate), '1995-06-15');
  });
}
