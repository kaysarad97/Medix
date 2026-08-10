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

  /// Лабораторный чат-бот.
  static const String chatbot = '/chatbot';

  /// Список переписок с врачами.
  static const String chats = '/chats';

  /// Переписка с одним врачом.
  static const String chat = '/chats/:id';

  static String chatOf(String id) => '/chats/$id';

  /// Профиль врача с записью на приём.
  static const String doctor = '/doctor/:id';

  /// Поиск врача: «Мои Врачи» и грид специальностей.
  static const String doctorSearch = '/doctor-search';

  /// Результаты поиска. Параметр `q` — специальность или свободный запрос.
  static const String doctorSearchResults = '/doctor-search/results';

  static String doctorSearchResultsOf(String query) =>
      '$doctorSearchResults?q=${Uri.encodeQueryComponent(query)}';

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

  /// Карточка члена семьи — «Моя Семья».
  static const String familyMember = '/profile/family/:id';

  static String familyMemberOf(String id) => '/profile/family/$id';

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

  static String appointmentOf(String id) => '/appointment/$id';
}
