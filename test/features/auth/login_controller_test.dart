import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/auth/presentation/providers/login_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    // authRepositoryProvider по умолчанию отдаёт MockAuthRepository,
    // см. MEDIX_USE_MOCKS в auth_providers.dart.
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  LoginController controller() =>
      container.read(loginControllerProvider.notifier);
  LoginState state() => container.read(loginControllerProvider);

  test(
    'submit с пустой формой ставит ошибки полей и не ходит в сеть',
    () async {
      await controller().submit();

      expect(state().identifierError, isNotNull);
      expect(state().passwordError, isNotNull);
      expect(state().isSubmitting, isFalse);
      expect(state().isAuthenticated, isFalse);
    },
  );

  test('короткий пароль отбивается до запроса', () async {
    controller().identifierChanged('abcedfg@gmail.com');
    controller().passwordChanged('123');

    await controller().submit();

    expect(state().identifierError, isNull);
    expect(state().passwordError, isNotNull);
    expect(state().isAuthenticated, isFalse);
  });

  test('правка поля гасит его ошибку, не трогая соседнюю', () async {
    await controller().submit();
    expect(state().identifierError, isNotNull);
    expect(state().passwordError, isNotNull);

    controller().identifierChanged('abcedfg@gmail.com');

    expect(state().identifierError, isNull);
    expect(state().passwordError, isNotNull);
  });

  test('валидные данные приводят к авторизации', () async {
    controller().identifierChanged('abcedfg@gmail.com');
    controller().passwordChanged('supersecret');

    await controller().submit();

    expect(state().isAuthenticated, isTrue);
    expect(state().isSubmitting, isFalse);
    expect(state().formError, isNull);
  });

  test('отказ сервера попадает в formError, а не в поля', () async {
    controller().identifierChanged('abcedfg@gmail.com');
    controller().passwordChanged('wrongpass');

    await controller().submit();

    expect(state().isAuthenticated, isFalse);
    expect(state().formError, isNotNull);
    expect(state().identifierError, isNull);
  });
}
