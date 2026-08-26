import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/auth/data/repositories/auth_repository.dart';
import 'package:medix/features/auth/presentation/providers/login_controller.dart';
import 'package:medix/features/auth/domain/entities/app_user.dart';

import '../../helpers/auth_overrides.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer(overrides: authOverrides));
  tearDown(() => container.dispose());

  LoginController controller() =>
      container.read(loginControllerProvider.notifier);
  LoginState state() => container.read(loginControllerProvider);

  group('шаг 1 — почта', () {
    test('пустая форма ставит ошибку поля и не ходит в сеть', () async {
      expect(await controller().submitEmail(), isFalse);

      expect(state().emailError, isNotNull);
      expect(state().isCodeSent, isFalse);
      expect(state().isSubmitting, isFalse);
    });

    test('некорректный адрес отбивается до запроса', () async {
      controller().emailChanged('не-почта');

      expect(await controller().submitEmail(), isFalse);
      expect(state().emailError, isNotNull);
      expect(state().isCodeSent, isFalse);
    });

    test('корректный адрес переводит на шаг с кодом', () async {
      controller().emailChanged('abcedfg@gmail.com');

      expect(await controller().submitEmail(), isTrue);
      expect(state().emailError, isNull);
      expect(state().isCodeSent, isTrue);
      expect(state().isAuthenticated, isFalse);
    });

    test('правка поля гасит его ошибку', () async {
      await controller().submitEmail();
      expect(state().emailError, isNotNull);

      controller().emailChanged('abcedfg@gmail.com');
      expect(state().emailError, isNull);
    });
  });

  group('шаг 2 — код', () {
    Future<void> reachCodeStep() async {
      controller().emailChanged('abcedfg@gmail.com');
      await controller().submitEmail();
    }

    test('код неверной длины отбивается до запроса', () async {
      await reachCodeStep();
      controller().codeChanged('123');

      await controller().submitCode();

      expect(state().codeError, isNotNull);
      expect(state().isAuthenticated, isFalse);
    });

    test('неверный код возвращается как ошибка формы, а не поля', () async {
      await reachCodeStep();
      controller().codeChanged('000000');

      await controller().submitCode();

      expect(state().isAuthenticated, isFalse);
      expect(state().formError, isNotNull);
      expect(state().codeError, isNull);
    });

    test('верный код открывает сессию', () async {
      await reachCodeStep();
      controller().codeChanged(MockAuthRepository.validCode);

      await controller().submitCode();

      expect(state().isAuthenticated, isTrue);
      expect(state().userRole, AppUserRole.patient);
      expect(state().isSubmitting, isFalse);
      expect(state().formError, isNull);
    });

    test('тестовая почта врача открывает врачебную сессию', () async {
      controller().emailChanged(MockAuthRepository.doctorEmail);
      await controller().submitEmail();
      controller().codeChanged(MockAuthRepository.validCode);

      await controller().submitCode();

      expect(state().isAuthenticated, isTrue);
      expect(state().userRole, AppUserRole.doctor);
    });

    test('повторная отправка не сбрасывает введённую почту', () async {
      await reachCodeStep();

      expect(await controller().resendCode(), isTrue);
      expect(state().email, 'abcedfg@gmail.com');
    });
  });
}
