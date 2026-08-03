/// Пути навигации.
abstract final class Routes {
  /// Заставка запуска. Решает, куда вести дальше, по сохранённой сессии.
  static const String splash = '/splash';

  static const String login = '/login';

  /// Шаг 1 мастера регистрации — почта и пароль.
  static const String register = '/register';

  /// Шаг 2 — ИИН, ФИО, телефон.
  static const String personalData = '/register/personal';

  /// Шаг 3 — код из СМС.
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

  /// Оформленная запись к врачу.
  static const String appointment = '/appointment/:id';

  /// Профиль пользователя — «Ваша Мед-Карта».
  static const String profile = '/profile';

  /// Форма мед-карты: группа крови, аллергии, операции.
  static const String medicalCardForm = '/profile/medical-card';

  /// Настройки приложения.
  static const String settings = '/profile/settings';

  /// Настройки профиля: имя, почта, пароль.
  static const String profileSettings = '/profile/settings/account';

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
