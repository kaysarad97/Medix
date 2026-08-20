/// Пути навигации.
abstract final class Routes {
  /// Заставка запуска. Решает, куда вести дальше, по сохранённой сессии.
  static const String splash = '/splash';

  /// Шаг 1 входа — почта. Пароля нет: сервер присылает одноразовый код.
  static const String login = '/login';

  /// Шаг 2 входа — код из письма.
  static const String loginVerify = '/login/verify';

  /// Шаг 1 мастера регистрации — почта.
  static const String register = '/register';

  /// Шаг 2 — ФИО и дата рождения. На этом шаге уходит письмо с кодом.
  static const String personalData = '/register/personal';

  /// Шаг 3 — код из письма.
  static const String verifyCode = '/register/verify';

  /// Шаг 4 — язык интерфейса и согласие на рассылки.
  static const String appSettings = '/register/settings';

  /// Шаг 5 — политика конфиденциальности.
  static const String policy = '/register/policy';

  static const String home = '/';

  /// Уведомления — колокольчик в шапке главной.
  static const String notifications = '/notifications';

  /// Лабораторный чат-бот.
  static const String chatbot = '/chatbot';

  /// Список переписок с врачами.
  static const String chats = '/chats';

  /// Переписка с одним врачом.
  static const String chat = '/chats/:id';

  static String chatOf(String id) => '/chats/$id';

  /// Профиль врача с записью на приём.
  static const String doctor = '/doctor/:id';

  /// «Оставьте отзыв» — оценка и текст отзыва о враче.
  static const String doctorReview = '/doctor/:id/review';

  /// Поиск врача: «Мои Врачи» и грид специальностей.
  static const String doctorSearch = '/doctor-search';

  /// Результаты поиска. Параметр `q` — специальность или свободный запрос.
  static const String doctorSearchResults = '/doctor-search/results';

  static String doctorSearchResultsOf(String query) =>
      '$doctorSearchResults?q=${Uri.encodeQueryComponent(query)}';

  /// Главная кабинета врача. Не связана с флоу входа/ролей — прямой
  /// маршрут для первого слайса, пока роль и авторизация врача не
  /// реализованы (см. HANDOFF.md, «Кабинет врача»).
  static const String doctorHome = '/doctor-home';

  /// Календарь на день — вход по шеврону «Предстоящие записи» с главной
  /// кабинета врача.
  static const String doctorCalendar = '/doctor-calendar';

  /// «Ваш Профиль» — кабинет врача.
  static const String doctorProfile = '/doctor-profile';

  /// «Ваши сертификаты» — кабинет врача.
  static const String doctorCertificates = '/doctor-certificates';

  /// «Отзывы о Вас» — кабинет врача. Не путать с [doctorReview] —
  /// пациентским «Оставьте отзыв» на профиле врача, это другой экран.
  static const String doctorOwnReviews = '/doctor-reviews';

  /// «История записей» — плитка на главной кабинета врача.
  static const String doctorHistory = '/doctor-history';

  /// «О прошлой записи» — строка истории.
  static const String doctorPastAppointment = '/doctor-history/:id';

  static String doctorPastAppointmentOf(String id) => '/doctor-history/$id';

  /// «Профиль пациента» — вход из «Постоянных пациентов» и из строки
  /// пациента на «О прошлой записи».
  static const String doctorPatient = '/doctor-patient/:id';

  static String doctorPatientOf(String id) => '/doctor-patient/$id';

  /// «Запись с пациентом» — вход из строки календаря врача.
  static const String doctorPatientAppointment = '/doctor-appointment/:id';

  static String doctorPatientAppointmentOf(String id) =>
      '/doctor-appointment/$id';

  /// «Чаты с пациентами» — плитка «Мои сообщения» на главной кабинета.
  static const String doctorChats = '/doctor-chats';

  /// «Чат с пациентом».
  static const String doctorPatientChat = '/doctor-chats/:id';

  static String doctorPatientChatOf(String id) => '/doctor-chats/$id';

  /// «Мои заявки» — плитка «Администрация» на главной кабинета врача.
  static const String doctorAdminRequests = '/doctor-admin-requests';

  /// Новая заявка в администрацию. Отдельным путём, а не сегментом `new`
  /// внутри списка: литерал и параметр в одном месте — источник путаницы.
  static const String doctorAdminNewRequest = '/doctor-admin-request';

  /// Заявка с ответом администрации.
  static const String doctorAdminRequest = '/doctor-admin-requests/:id';

  static String doctorAdminRequestOf(String id) => '/doctor-admin-requests/$id';

  /// «Аналитика Работы» — третья плитка на главной кабинета врача.
  static const String doctorAnalytics = '/doctor-analytics';

  /// Оформленная запись к врачу.
  static const String appointment = '/appointment/:id';

  /// Экран звонка по записи: видео или аудио, в зависимости от
  /// `Appointment.kind`.
  static const String call = '/appointment/:id/call';

  static String callOf(String id) => '/appointment/$id/call';

  /// Больницы и лаборатории на карте.
  static const String mapSearch = '/map';

  /// Перечень услуг: каталог анализов и комплексов.
  static const String labServices = '/lab-services';

  /// «Партнерские лаборатории» — сколько та же корзина стоит у других.
  static const String labOffers = '/lab-services/offers';

  /// Профиль пользователя — «Ваша Мед-Карта».
  static const String profile = '/profile';

  /// Форма мед-карты: группа крови, аллергии, операции.
  static const String medicalCardForm = '/profile/medical-card';

  /// История консультаций: «Предыдущие процедуры».
  static const String procedures = '/profile/procedures';

  /// Список близких — «Моя Семья».
  static const String family = '/profile/family';

  /// Форма нового члена семьи.
  ///
  /// Объявляется в роутере раньше [familyMember]: go_router разбирает пути
  /// по порядку, и `:id` иначе поймал бы «new» как идентификатор.
  static const String familyMemberNew = '/profile/family/new';

  /// Карточка члена семьи — «Моя Семья».
  static const String familyMember = '/profile/family/:id';

  /// Правка члена семьи: та же форма, что и добавление.
  static const String familyMemberEdit = '/profile/family/:id/edit';

  static String familyMemberOf(String id) => '/profile/family/$id';

  static String familyMemberEditOf(String id) => '/profile/family/$id/edit';

  /// Настройки приложения.
  static const String settings = '/profile/settings';

  /// Настройки профиля: имя, почта, пароль.
  static const String profileSettings = '/profile/settings/account';

  /// «Выбор аватарки» — сетка картинок из сборки.
  static const String avatarPicker = '/profile/settings/account/avatar';

  /// «Свяжитесь с нами».
  static const String contacts = '/profile/settings/contacts';

  /// Варианты подписки.
  static const String subscription = '/subscription';

  /// Выбор способа оплаты.
  static const String payment = '/subscription/payment';

  /// Ввод данных карты.
  static const String cardForm = '/subscription/payment/card';

  /// Итог оплаты. Параметр `outcome` — `success` или `failure`.
  static const String paymentResult = '/subscription/payment/result/:outcome';

  static String paymentResultOf(String outcome) =>
      '/subscription/payment/result/$outcome';

  static String doctorOf(String id) => '/doctor/$id';

  static String doctorReviewOf(String id) => '/doctor/$id/review';

  static String appointmentOf(String id) => '/appointment/$id';
}
