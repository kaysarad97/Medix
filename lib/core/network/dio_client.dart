import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/secure_storage_service.dart';
import '../constants/app_constants.dart';
import 'api_endpoints.dart';

/// Настроенный [Dio] для обращений к API MedIx.
final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);

  final options = BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: AppConstants.networkTimeout,
    receiveTimeout: AppConstants.networkTimeout,
    sendTimeout: AppConstants.networkTimeout,
    headers: {'Content-Type': 'application/json'},
  );

  final dio = Dio(options);
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      // Отдельный клиент без интерцептора: обновление токена не должно
      // проходить через ту же цепочку, иначе 401 на самом обновлении
      // запустит обновление снова.
      refreshDio: Dio(options),
      storage: storage,
    ),
  );

  return dio;
});

/// Подставляет токен доступа и обновляет его, когда сервер ответил 401.
///
/// Токен доступа живёт 20 минут, поэтому без обновления сессия умирает
/// прямо во время работы. Бэкенд при обновлении выдаёт новый refresh-токен
/// и гасит предыдущий, так что обновление должно быть строго одно на все
/// запросы, упёршиеся в 401 одновременно, — иначе второе обновление придёт
/// с уже погашенным токеном и разлогинит пользователя. За это отвечает
/// [_refreshing]: первый пришедший запускает обновление, остальные ждут его
/// результат.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required SecureStorageService storage,
  }) : _dio = dio,
       _refreshDio = refreshDio,
       _storage = storage;

  final Dio _dio;
  final Dio _refreshDio;
  final SecureStorageService _storage;

  Future<String?>? _refreshing;

  static bool _isAuthCall(RequestOptions options) =>
      options.path.startsWith(ApiEndpoints.authPrefix);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthCall(options)) {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isExpired =
        err.response?.statusCode == 401 &&
        !_isAuthCall(options) &&
        options.extra[_retriedKey] != true;

    if (!isExpired) {
      handler.next(err);
      return;
    }

    final token = await _refreshOnce();
    if (token == null) {
      handler.next(err);
      return;
    }

    try {
      options.headers['Authorization'] = 'Bearer $token';
      // Повтор помечаем, чтобы 401 на самом повторе не увёл в новый круг.
      options.extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Возвращает новый токен доступа или `null`, если сессию восстановить
  /// не удалось. Параллельные вызовы получают результат одного обновления.
  Future<String?> _refreshOnce() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final access = data?['access_token'];
      final refresh = data?['refresh_token'];
      if (access is! String || refresh is! String) return null;

      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException {
      // Refresh отозван или просрочен — сессии больше нет. Чистим хранилище,
      // чтобы заставка при следующем запуске увела на экран входа.
      await _storage.clear();
      return null;
    }
  }

  static const String _retriedKey = 'medix.retried_after_refresh';
}
