/// Тема заявки в администрацию — «Запросы к админу.png»: пять чипов
/// частых вопросов.
///
/// Подписи собираются на экране, а не здесь: у `enum` нет доступа к
/// `BuildContext`, и это общее правило проекта.
enum AdminRequestTopic { reschedule, cancel, vacation, resignation, other }

/// Заявка врача в администрацию клиники и ответ на неё.
///
/// Врач от клиники не отменяет и не переносит записи сам — он пишет сюда.
/// Своего эндпоинта у заявок на сервере нет (проверено по контракту
/// 21 августа 2026), поэтому пока живёт только в заглушке.
class AdminRequest {
  const AdminRequest({
    required this.id,
    required this.topic,
    required this.text,
    required this.createdAt,
    this.answer,
    this.answeredAt,
  });

  final String id;
  final AdminRequestTopic topic;

  /// Что написал врач.
  final String text;

  final DateTime createdAt;

  /// Ответ администрации. `null` — ещё не ответили.
  final String? answer;

  final DateTime? answeredAt;

  bool get isAnswered => answer != null;
}
