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
  static const String doctorRegisterStart = '/auth/doctor/register/start';
  static const String doctorRegisterVerify = '/auth/doctor/register/verify';

  /// Вход тоже в два шага — пароля нет, сервер присылает одноразовый код.
  static const String loginStart = '/auth/login/start';
  static const String loginVerify = '/auth/login/verify';

  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  /// Профиль текущего пользователя.
  static const String me = '/users/me';
  static const String myAvatar = '$me/avatar';
  static const String myAvatarUploadUrl = '$myAvatar/upload-url';

  /// Мед-карта: записи о здоровье. Хранятся дописыванием — правка заводит
  /// новую версию и помечает старую `superseded_by`.
  static const String medicalRecords = '$me/medical-records';

  static const String medicalRecordHistory = '$medicalRecords/history';

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

  /// Push-устройства текущего пользователя.
  static const String devices = '/devices';

  static String device(String id) => '$devices/$id';

  static const String labReferrals = '/lab/referrals';
  static const String labReferralUploadUrl = '$labReferrals/upload-url';
  static String labReferral(String id) => '$labReferrals/$id';
  static const String labOffers = '/lab/offers';
  static const String labOrders = '/lab/orders';
  static const String labResults = '/lab/results';
  static String labResultDownloadUrl(String id) =>
      '$labResults/$id/download-url';

  static const String consultations = '/consultations';
  static String consultationJoin(String id) => '$consultations/$id/join';
  static String consultationComplete(String id) =>
      '$consultations/$id/complete';
  static String consultationMessages(String id) =>
      '$consultations/$id/messages';
  static String consultationFiles(String id) => '$consultations/$id/files';
  static String consultationFileUploadUrl(String id) =>
      '${consultationFiles(id)}/upload-url';
  static String consultationFileDownloadUrl(String id, String fileId) =>
      '${consultationFiles(id)}/$fileId/download-url';
  static String consultationDispute(String id) => '$consultations/$id/dispute';
  static String consultationReview(String id) => '$consultations/$id/review';

  /// Члены семьи: список и добавление.
  static const String family = '/users/me/family';

  /// Один член семьи: чтение, правка, удаление.
  static String familyMember(String id) => '$family/$id';

  /// Мед-карта члена семьи. Чужой идентификатор отдаёт 404 и попадает в
  /// журнал доступа на сервере.
  static String familyMedicalRecords(String id) =>
      '${familyMember(id)}/medical-records';

  static String familyMedicalRecordHistory(String id) =>
      '${familyMedicalRecords(id)}/history';

  /// Каталог врачей. Токен не обязателен, но с ним сервер считает цену с
  /// учётом подписки — см. `price_for_user` в ответе.
  static const String doctors = '/doctors';

  static const String myDoctor = '$doctors/me';

  static const String myDoctorAppointments = '$myDoctor/appointments';

  static String myDoctorAppointment(String id) => '$myDoctorAppointments/$id';

  static String myDoctorPatientMedicalRecords(String patientId) =>
      '$myDoctor/patients/$patientId/medical-records';

  static String myDoctorAppointmentNoShow(String id) =>
      '${myDoctorAppointment(id)}/no-show';

  static const String doctorSpecialties = '$doctors/specialties';

  static String doctor(String id) => '$doctors/$id';

  /// Свободные слоты врача. Обязательные `from` и `to` — в ISO.
  static String doctorSlots(String id) => '${doctor(id)}/slots';

  /// Отзывы о враче. Единственный эндпоинт каталога без токена.
  static String doctorReviews(String id) => '${doctor(id)}/reviews';

  /// Рабочие слоты текущего врача.
  static const String myDoctorSchedule = '$doctors/me/schedule';
  static const String myDoctorSlots = '$doctors/me/slots';
  static String myDoctorSlot(String id) => '$myDoctorSlots/$id';
  static const String myDoctorCredentials = '$doctors/me/credentials';
  static const String myDoctorCredentialsUploadUrl =
      '$myDoctorCredentials/upload-url';
  static const String myDoctorPhoto = '$doctors/me/photo';
  static const String myDoctorPhotoUploadUrl = '$myDoctorPhoto/upload-url';

  /// Записи на приём: создание, свои записи, перенос и отмена.
  static const String appointments = '/appointments';

  static String appointment(String id) => '$appointments/$id';

  static const String waitlist = '/waitlist';

  static String waitlistEntry(String id) => '$waitlist/$id';

  static String claimSlot(String id) => '/slots/$id/claim';

  /// Запросы к этой ветке уходят без токена доступа и не перезапрашиваются
  /// после 401: часть из них анонимна, а `/auth/refresh` и `/auth/logout`
  /// носят refresh-токен в теле. Единое правило избавляет от рекурсии в
  /// [AuthInterceptor].
  static const String authPrefix = '/auth/';
}
