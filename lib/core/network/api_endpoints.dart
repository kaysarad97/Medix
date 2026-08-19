/// Пути API MedIx.
///
/// Базовый адрес задаётся сборочным флагом:
/// `flutter run --dart-define=MEDIX_API_URL=http://192.168.1.65:8000`.
/// Значение по умолчанию рассчитано на бэкенд, поднятый на той же машине;
/// для эмулятора Android хост-машина видна как `10.0.2.2`, для реального
/// устройства нужен адрес машины в локальной сети.
///
/// Версионного префикса у бэкенда нет — пути идут от корня.
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'MEDIX_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Регистрация в два шага: заявка с данными профиля, затем код из письма.
  static const String registerStart = '/auth/register/start';
  static const String registerVerify = '/auth/register/verify';

  /// Вход тоже в два шага — пароля нет, сервер присылает одноразовый код.
  static const String loginStart = '/auth/login/start';
  static const String loginVerify = '/auth/login/verify';

  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  /// Профиль текущего пользователя.
  static const String me = '/users/me';

  /// Мед-карта: записи о здоровье. Хранятся дописыванием — правка заводит
  /// новую версию и помечает старую `superseded_by`.
  static const String medicalRecords = '$me/medical-records';

  static String medicalRecord(String id) => '$medicalRecords/$id';

  /// Тарифы с ценами. Единственный эндпоинт подписок без токена.
  static const String plans = '/plans';

  /// Оформление подписки. Шлюза у сервера нет: в ответе на `POST` платёж
  /// уже помечен `paid`.
  static const String subscriptions = '/subscriptions';

  /// Действующая подписка. Её нет — сервер отвечает 404, и это не ошибка.
  static const String mySubscription = '$subscriptions/me';

  /// Лента уведомлений.
  static const String notifications = '/notifications';

  /// Отметить уведомление прочитанным.
  static String notification(String id) => '$notifications/$id';

  /// Члены семьи: список и добавление.
  static const String family = '/users/me/family';

  /// Один член семьи: чтение, правка, удаление.
  static String familyMember(String id) => '$family/$id';

  /// Мед-карта члена семьи. Чужой идентификатор отдаёт 404 и попадает в
  /// журнал доступа на сервере.
  static String familyMedicalRecords(String id) =>
      '${familyMember(id)}/medical-records';

  /// Каталог врачей. Токен не обязателен, но с ним сервер считает цену с
  /// учётом подписки — см. `price_for_user` в ответе.
  static const String doctors = '/doctors';

  static String doctor(String id) => '$doctors/$id';

  /// Свободные слоты врача. Обязательные `from` и `to` — в ISO.
  static String doctorSlots(String id) => '${doctor(id)}/slots';

  /// Отзывы о враче. Единственный эндпоинт каталога без токена.
  static String doctorReviews(String id) => '${doctor(id)}/reviews';

  /// Записи на приём: создание, свои записи, перенос и отмена.
  static const String appointments = '/appointments';

  static String appointment(String id) => '$appointments/$id';

  /// Запросы к этой ветке уходят без токена доступа и не перезапрашиваются
  /// после 401: часть из них анонимна, а `/auth/refresh` и `/auth/logout`
  /// носят refresh-токен в теле. Единое правило избавляет от рекурсии в
  /// [AuthInterceptor].
  static const String authPrefix = '/auth/';
}
