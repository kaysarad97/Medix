import 'package:dio/dio.dart';

/// Ошибка обращения к API, пригодная для показа пользователю.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Приводит [DioException] к сообщению на русском.
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException('Сервер не отвечает. Попробуйте ещё раз.');
      case DioExceptionType.connectionError:
        return const ApiException('Нет подключения к интернету.');
      case DioExceptionType.cancel:
        return const ApiException('Запрос отменён.');
      case DioExceptionType.badCertificate:
        return const ApiException(
          'Не удалось установить защищённое соединение.',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final code = e.response?.statusCode;
        final detail = e.response?.data;
        final message = detail is Map && detail['detail'] is String
            ? detail['detail'] as String
            : 'Не удалось выполнить запрос.';
        return ApiException(message, statusCode: code);
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
