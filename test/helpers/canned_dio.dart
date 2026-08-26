import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Ответ, заготовленный на конкретный путь.
typedef CannedResponse = ({int statusCode, Object body});

/// [Dio], который никуда не ходит и отдаёт заранее заготовленное.
///
/// Нужен разбору ответов бэкенда: проверять его на живом сервере — значит
/// поднимать Postgres с Redis ради пяти строк маппинга, а на моках он не
/// проверяется вовсе, потому что мок и есть уже разобранные данные.
class CannedAdapter implements HttpClientAdapter {
  CannedAdapter(this.responses);

  /// Ключ — путь запроса (`/doctors/d1`) либо метод с путём
  /// (`POST /users/me/medical-records`). По одному пути ходят и чтением, и
  /// записью, и ответы у них разные: список против одной записи.
  final Map<String, CannedResponse> responses;

  /// Запросы, которые дошли до адаптера: путь, параметры и тело.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final canned =
        responses['${options.method} ${options.path}'] ??
        responses[options.path];
    if (canned == null) {
      return ResponseBody.fromString(
        '{"detail": "нет заготовки"}',
        404,
        headers: _jsonHeaders,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(canned.body),
      canned.statusCode,
      headers: _jsonHeaders,
    );
  }

  static const Map<String, List<String>> _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

/// [Dio] с подменённым транспортом.
({Dio dio, CannedAdapter adapter}) cannedDio(
  Map<String, CannedResponse> responses,
) {
  final adapter = CannedAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'))
    ..httpClientAdapter = adapter;
  return (dio: dio, adapter: adapter);
}
