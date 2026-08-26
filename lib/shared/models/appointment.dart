import '../../core/utils/ru_dates.dart';
import '../../core/utils/ru_money.dart';

// Подпись — в виджете, не здесь: у enum нет доступа к BuildContext, нужного
// `AppLocalizations.of(context)`.
/// Формат приёма.
enum AppointmentKind { videoCall, audioCall, chat, inPerson }

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow,
  unknown,
}

/// Запись к врачу.
///
/// Лежит в `shared/`, а не в фиче: её показывают и главная («Предстоящие
/// записи»), и телемедицина (экран «Ваша запись»).
class Appointment {
  const Appointment({
    required this.id,
    required this.specialty,
    required this.kind,
    required this.startsAt,
    this.doctorId,
    this.doctorName,
    this.consultationId,
    this.endsAt,
    this.status = AppointmentStatus.unknown,
    this.cancellationReason,
    this.familyMemberId,
    this.basePrice,
    this.subscriberPrice,
  });

  final String id;
  final String specialty;
  final AppointmentKind kind;
  final DateTime startsAt;

  /// Врач, к которому запись. У моков главной пусто.
  final String? doctorId;
  final String? doctorName;
  final String? consultationId;
  final DateTime? endsAt;
  final AppointmentStatus status;

  /// Причина отмены со стороны врача. При отмене пациентом сервер оставляет
  /// поле пустым, поэтому `null` — допустимое состояние отменённой записи.
  final String? cancellationReason;
  final String? familyMemberId;

  /// Цена предоплаты без подписки. `null` — блок предоплаты не рисуется
  /// (у моков главной, где карточка записи компактная, цены нет вообще).
  final int? basePrice;

  /// Цена со скидкой по подписке — ту, что сервер посчитал этому
  /// пользователю (`price_for_user`). `null`, если скидки на эту запись
  /// нет: тогда `basePrice` показывается как есть.
  ///
  /// В макете `design/Предоплата - GOLD.png` эта цена подписана «Gold», но
  /// Gold на сервере отключён с 17 августа 2026 — скидку даёт Silver.
  final int? subscriberPrice;

  /// Дата в пилюле справа на главной: «13.08».
  String get shortDate => RuDates.dayMonth(startsAt);

  /// Дата и время в карточке записи: «10.07, 13:30».
  String get dayMonthTime =>
      '${RuDates.dayMonth(startsAt)}, ${RuDates.time(startsAt)}';

  String? get basePriceLabel => RuMoney.withThousands(basePrice);

  String? get subscriberPriceLabel => RuMoney.withThousands(subscriberPrice);
}
