import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/auth/data/repositories/auth_repository.dart';
import 'package:medix/features/auth/presentation/providers/registration_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  RegistrationController controller() =>
      container.read(registrationControllerProvider.notifier);
  RegistrationState state() => container.read(registrationControllerProvider);

  void fillCredentials({
    String email = 'user@medix.kz',
    String password = 'supersecret',
    String? confirm,
  }) {
    controller()
      ..setField(RegField.email, email)
      ..setField(RegField.password, password)
      ..setField(RegField.passwordConfirm, confirm ?? password);
  }

  void fillPersonalData({
    String iin = '950815350123',
    String fullName = 'Аркалыков Дархан',
    String phone = '+7 701 234 56 78',
  }) {
    controller()
      ..setField(RegField.iin, iin)
      ..setField(RegField.fullName, fullName)
      ..setField(RegField.phone, phone);
  }

  group('шаг 1 — почта и пароль', () {
    test('пустая форма даёт ошибки на всех трёх полях', () {
      expect(controller().submitCredentials(), isFalse);
      expect(state().errorOf(RegField.email), isNotNull);
      expect(state().errorOf(RegField.password), isNotNull);
      expect(state().errorOf(RegField.passwordConfirm), isNotNull);
    });

    test('несовпадающий повтор пароля отбивается', () {
      fillCredentials(confirm: 'othersecret');

      expect(controller().submitCredentials(), isFalse);
      expect(state().errorOf(RegField.password), isNull);
      expect(state().errorOf(RegField.passwordConfirm), 'Пароли не совпадают');
    });

    test('корректные данные проходят', () {
      fillCredentials();
      expect(controller().submitCredentials(), isTrue);
    });

    test('правка поля гасит его ошибку, не трогая соседние', () {
      controller().submitCredentials();
      controller().setField(RegField.email, 'user@medix.kz');

      expect(state().errorOf(RegField.email), isNull);
      expect(state().errorOf(RegField.password), isNotNull);
    });
  });

  group('шаг 2 — ИИН, ФИО, телефон', () {
    test('ИИН с битой контрольной суммой не пропускается', () async {
      fillCredentials();
      fillPersonalData(iin: '950815350124');

      expect(await controller().submitPersonalData(), isFalse);
      expect(state().errorOf(RegField.iin), isNotNull);
    });

    test('ФИО из одного слова не пропускается', () async {
      fillCredentials();
      fillPersonalData(fullName: 'Дархан');

      expect(await controller().submitPersonalData(), isFalse);
      expect(state().errorOf(RegField.fullName), 'Укажите фамилию и имя');
    });

    test('номер в формате 8XXX приводится и проходит', () async {
      fillCredentials();
      fillPersonalData(phone: '8 (701) 234-56-78');

      expect(await controller().submitPersonalData(), isTrue);
      expect(state().errorOf(RegField.phone), isNull);
    });

    test('занятая почта возвращается как ошибка формы, а не поля', () async {
      fillCredentials(email: 'taken@medix.kz');
      fillPersonalData();

      expect(await controller().submitPersonalData(), isFalse);
      expect(state().formError, isNotNull);
      expect(state().errorOf(RegField.iin), isNull);
      expect(state().isSubmitting, isFalse);
    });
  });

  group('шаг 3 — код из СМС', () {
    test('код неверной длины отбивается до запроса', () async {
      controller().setField(RegField.code, '123');

      expect(await controller().submitCode(), isFalse);
      expect(state().errorOf(RegField.code), isNotNull);
    });

    test('неверный код возвращается как ошибка формы', () async {
      controller().setField(RegField.code, '54321');

      expect(await controller().submitCode(), isFalse);
      expect(state().formError, 'Неверный код подтверждения');
    });

    test('верный код завершает регистрацию', () async {
      fillCredentials();
      fillPersonalData();
      controller().setField(RegField.code, MockAuthRepository.validCode);

      expect(await controller().submitCode(), isTrue);
      expect(state().formError, isNull);
    });
  });

  test('данные шага 1 доживают до шага 3', () async {
    fillCredentials(email: 'keep@medix.kz');
    fillPersonalData();
    controller().setField(RegField.code, MockAuthRepository.validCode);
    await controller().submitCode();

    expect(state().value(RegField.email), 'keep@medix.kz');
    expect(state().value(RegField.iin), '950815350123');
  });
}
