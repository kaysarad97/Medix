import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/network/api_endpoints.dart';
import 'package:medix/core/network/dio_client.dart';
import 'package:medix/shared/services/secure_storage_service.dart';

/// Отвечает вместо сети: на старый токен — 401, на новый — 200. Считает,
/// сколько раз запрашивали обновление.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.refreshSucceeds = true});

  final bool refreshSucceeds;

  int refreshCalls = 0;
  int protectedCalls = 0;

  /// Задержка обновления. Нужна, чтобы в тесте на параллельные запросы
  /// второй успел упереться в 401, пока первый ещё обновляет токен.
  Duration refreshDelay = const Duration(milliseconds: 50);

  static const oldAccess = 'access-old';
  static const newAccess = 'access-new';

  ResponseBody _json(Map<String, dynamic> body, int status) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == ApiEndpoints.refresh) {
      refreshCalls++;
      await Future<void>.delayed(refreshDelay);
      if (!refreshSucceeds) return _json({'detail': 'отозван'}, 401);
      return _json({
        'access_token': newAccess,
        'refresh_token': 'refresh-new',
        'token_type': 'bearer',
      }, 200);
    }

    protectedCalls++;
    final auth = options.headers['Authorization'];
    if (auth == 'Bearer $newAccess') return _json({'id': 'u1'}, 200);
    return _json({'detail': 'Невалидный токен'}, 401);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> stored;

  setUp(() {
    stored = {
      'medix.access_token': _FakeAdapter.oldAccess,
      'medix.refresh_token': 'refresh-old',
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          switch (call.method) {
            case 'read':
              return stored[args['key'] as String];
            case 'write':
              stored[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              stored.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              stored.clear();
              return null;
            case 'readAll':
              return stored;
            case 'containsKey':
              return stored.containsKey(args['key'] as String);
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Собирает клиент так же, как `dioClientProvider`, но с подставным
  /// транспортом вместо сети.
  Dio buildDio(_FakeAdapter adapter) {
    final options = BaseOptions(
      baseUrl: 'http://test.local',
      headers: {'Content-Type': 'application/json'},
    );
    final dio = Dio(options)..httpClientAdapter = adapter;
    final refreshDio = Dio(options)..httpClientAdapter = adapter;

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        storage: SecureStorageService(const FlutterSecureStorage()),
      ),
    );
    return dio;
  }

  test('запрос уходит с токеном из хранилища', () async {
    final adapter = _FakeAdapter();
    final dio = buildDio(adapter);

    await dio.get<dynamic>(ApiEndpoints.me);

    // Первая попытка со старым токеном, вторая — после обновления.
    expect(adapter.protectedCalls, 2);
  });

  test('401 приводит к обновлению токена и повтору запроса', () async {
    final adapter = _FakeAdapter();
    final dio = buildDio(adapter);

    final response = await dio.get<dynamic>(ApiEndpoints.me);

    expect(response.statusCode, 200);
    expect(adapter.refreshCalls, 1);
    expect(stored['medix.access_token'], _FakeAdapter.newAccess);
    expect(stored['medix.refresh_token'], 'refresh-new');
  });

  test('параллельные 401 обновляют токен ровно один раз', () async {
    final adapter = _FakeAdapter();
    final dio = buildDio(adapter);

    final responses = await Future.wait([
      dio.get<dynamic>(ApiEndpoints.me),
      dio.get<dynamic>('/users/me/family'),
      dio.get<dynamic>('/users/me/medical-records'),
    ]);

    for (final response in responses) {
      expect(response.statusCode, 200);
    }
    // Главное в интерцепторе: бэкенд гасит прежний refresh при каждом
    // обновлении, поэтому второе обновление разлогинило бы пользователя.
    expect(adapter.refreshCalls, 1);
  });

  test('провал обновления чистит хранилище и отдаёт исходную ошибку', () async {
    final adapter = _FakeAdapter(refreshSucceeds: false);
    final dio = buildDio(adapter);

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.me),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(stored, isEmpty);
  });

  test('запросы к /auth/ не носят токен и не уходят на обновление', () async {
    final adapter = _FakeAdapter();
    final dio = buildDio(adapter);

    await expectLater(
      dio.post<dynamic>(ApiEndpoints.loginStart, data: {'identifier': 'a@b.c'}),
      throwsA(isA<DioException>()),
    );

    // Ни одной попытки обновиться: иначе 401 на самом входе уводил бы в
    // рекурсию.
    expect(adapter.refreshCalls, 0);
  });
}
