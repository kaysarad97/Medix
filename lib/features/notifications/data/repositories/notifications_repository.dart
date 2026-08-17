import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/app_notification.dart';

/// Откуда берётся список уведомлений.
abstract interface class NotificationsRepository {
  Future<List<AppNotification>> notifications();
}

/// Лента уведомлений поверх FastAPI-бэкенда.
///
/// До 17 августа 2026 `GET /notifications/` отвечал
/// `{"module": "notifications", "status": "scaffolded"}` — заготовкой
/// модуля. Теперь это настоящая лента с текстом, временем и отметкой о
/// прочтении.
class RemoteNotificationsRepository implements NotificationsRepository {
  const RemoteNotificationsRepository(this._dio);

  final Dio _dio;

  /// Сколько уведомлений просить за раз. Постраничной подгрузки на экране
  /// нет — сервер по умолчанию отдаёт двадцать, берём вчетверо больше.
  static const int _limit = 80;

  @override
  Future<List<AppNotification>> notifications() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {'limit': _limit},
      );
      return [
        for (final item in response.data ?? const [])
          _notification(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static AppNotification _notification(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        kind: NotificationKind.fromApi(json['kind'] as String?),
        title: (json['title'] as String? ?? '').trim(),
        body: (json['body'] as String? ?? '').trim(),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        isRead: json['read_at'] != null,
      );
}

/// Заглушка под `MEDIX_USE_MOCKS`.
///
/// Содержимое повторяет `design/Нотификации.png`: пять строк, из них две о
/// сообщениях. Даты заданы жёстко, а не «сегодня минус час» — иначе подписи
/// в тестах менялись бы каждый день.
class MockNotificationsRepository implements NotificationsRepository {
  const MockNotificationsRepository();

  @override
  Future<List<AppNotification>> notifications() async => mockNotifications;

  static final List<AppNotification> mockNotifications = [
    _appointment('n1'),
    _message('n2'),
    _appointment('n3'),
    _appointment('n4'),
    _message('n5'),
  ];

  static AppNotification _appointment(String id) => AppNotification(
    id: id,
    kind: NotificationKind.schedule,
    title: 'Ваша запись подтверждена',
    body: 'Имя Фамилия подтвердил запись в 13:30, 27 июля',
    createdAt: DateTime(2026, 7, 21, 13, 44),
  );

  static AppNotification _message(String id) => AppNotification(
    id: id,
    kind: NotificationKind.message,
    title: 'Вам пришло сообщение',
    body: 'Имя Фамилия отправил Вам сообщение',
    createdAt: DateTime(2026, 7, 21, 13, 44),
  );
}
