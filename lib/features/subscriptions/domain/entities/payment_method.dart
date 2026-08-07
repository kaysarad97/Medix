import '../../../../core/widgets/icon_chip.dart';

/// Способ оплаты со экрана `design/Оплата.png`.
///
/// Подпись — в виджете (`PaymentMethodScreen`, `PrepaymentCard`), не здесь:
/// у enum нет доступа к `BuildContext`, а значит и к переводу.
enum PaymentMethod {
  kaspi(MedixIcon.paymentKaspi),
  halyk(MedixIcon.paymentHalyk),
  applePay(MedixIcon.paymentApplePay),
  otherBank(MedixIcon.paymentCard);

  const PaymentMethod(this.icon);

  final MedixIcon icon;

  /// Ведёт ли способ на форму ввода карты. Для Kaspi, Halyk и Apple Pay
  /// оплату проводит их собственный интерфейс, карту у себя мы не спрашиваем.
  bool get needsCardForm => this == PaymentMethod.otherBank;
}

/// Данные карты из формы `design/Ввод данных карты.png`.
///
/// ХРАНИТЬ НЕЛЬЗЯ. Объект живёт ровно до отправки в платёжный шлюз и не
/// попадает ни в наш бэкенд, ни в secure storage, ни в логи: номер карты,
/// срок и CVV — данные держателя карты по PCI DSS, и их хранение требует
/// сертификации, которой у проекта нет.
class CardDetails {
  const CardDetails({
    required this.number,
    required this.holder,
    required this.expiry,
    required this.cvv,
  });

  final String number;
  final String holder;

  /// «01/01» — месяц и год.
  final String expiry;

  final String cvv;

  /// Последние четыре цифры — единственное, что можно показать и сохранить.
  String get lastFour {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length < 4 ? digits : digits.substring(digits.length - 4);
  }

  /// Номер разбит по четыре: «4400 4301 1234 5678».
  static String formatNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, (i + 4).clamp(0, digits.length)));
    }
    return groups.join(' ');
  }

  /// Полей должно хватать на попытку оплаты: 16 цифр, имя, срок и три
  /// цифры кода. Настоящую валидацию делает шлюз.
  bool get isComplete =>
      number.replaceAll(RegExp(r'\D'), '').length == 16 &&
      holder.trim().isNotEmpty &&
      expiry.replaceAll(RegExp(r'\D'), '').length == 4 &&
      cvv.length == 3;
}
