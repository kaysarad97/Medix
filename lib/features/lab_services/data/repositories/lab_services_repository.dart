import '../../domain/entities/lab_offer.dart';
import '../../domain/entities/lab_service.dart';

abstract interface class LabServicesRepository {
  Future<List<LabService>> services();

  /// Предложения партнёров на ту же корзину — экран сравнения цен.
  /// Набор передаём, потому что у каждой лаборатории свой прайс и
  /// пересчитывать его должна она, а не приложение.
  Future<List<LabOffer>> offersFor(Set<String> serviceIds);
}

/// Заглушка на время разработки бэкенда. Названия — реальные лабораторные
/// анализы (часть — прямо с `design/Перечень услуг.png`, остальные
/// добавлены, чтобы список не выглядел так, будто буква «А» просто
/// скопирована четыре раза, как в самом макете — это Figma-плейсхолдер,
/// а не реальный контент).
class MockLabServicesRepository implements LabServicesRepository {
  const MockLabServicesRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  static const int _price = 1000;
  static const int _bundlePrice = 5000;

  static const List<LabService> mockServices = [
    LabService(id: 's1', name: 'Аланинаминотрансфераза (АЛТ)', price: _price),
    LabService(id: 's2', name: 'Альбумин в сыворотке', price: _price),
    LabService(id: 's3', name: 'Амилаза общая в сыворотке', price: _price),
    LabService(id: 's4', name: 'Антимюллеровский гормон', price: _price),
    LabService(id: 's5', name: 'Антистрептолизин O', price: _price),
    LabService(id: 's6', name: 'Аскаридоз, IgG', price: _price),
    LabService(id: 's7', name: 'Аспартатаминотрансфераза (АСТ)', price: _price),
    LabService(id: 's8', name: 'Билирубин общий', price: _price),
    LabService(id: 's9', name: 'Билирубин прямой', price: _price),
    LabService(id: 's10', name: 'Витамин D (25-ОН)', price: _price),
    LabService(id: 's11', name: 'Витамин B12', price: _price),
    LabService(id: 's12', name: 'Глюкоза в сыворотке', price: _price),
    LabService(id: 's13', name: 'Д-димер', price: _price),
    LabService(
      id: 'b1',
      name: 'Общий анализ крови (комплекс)',
      price: _bundlePrice,
      kind: LabServiceKind.bundle,
    ),
    LabService(
      id: 'b2',
      name: 'Биохимический скрининг',
      price: _bundlePrice,
      kind: LabServiceKind.bundle,
    ),
    LabService(
      id: 'b3',
      name: 'Гормоны щитовидной железы (комплекс)',
      price: _bundlePrice,
      kind: LabServiceKind.bundle,
    ),
    LabService(
      id: 'b4',
      name: 'Комплекс “Вегетарианский”',
      price: _bundlePrice,
      kind: LabServiceKind.bundle,
      // Состав — с `design/Моя корзина.png`.
      includes: [
        'Витамин D (25-ОН)',
        'Витамин B12',
        'Кальций общий',
        'Общий белок',
        'ОАК с лейкоцитарной формулой',
      ],
    ),
  ];

  /// Партнёры с `design/Сравнение корзины.png`. Цены отличаются от нашей
  /// суммы намеренно: в этом весь смысл экрана — показать, что тот же
  /// набор где-то дешевле.
  static const List<LabOffer> mockOffers = [
    LabOffer(
      id: 'l1',
      labName: 'Лаборатория N1',
      address: 'Название лаборатории, улица, город',
      rating: 4.5,
      isOpen: true,
      distanceMeters: 900,
      price: 2900,
    ),
    LabOffer(
      id: 'l2',
      labName: 'КДЛ “Анализы”',
      address: 'Название лаборатории, улица, город',
      rating: 4.5,
      isOpen: true,
      distanceMeters: 900,
      price: 2950,
    ),
    LabOffer(
      id: 'l3',
      labName: 'Инвитро',
      address: 'Название лаборатории, улица, город',
      rating: 4.5,
      isOpen: false,
      distanceMeters: 1200,
      price: 3100,
    ),
  ];

  @override
  Future<List<LabService>> services() async {
    await Future<void>.delayed(_latency);
    return mockServices;
  }

  @override
  Future<List<LabOffer>> offersFor(Set<String> serviceIds) async {
    await Future<void>.delayed(_latency);
    // Настоящего пересчёта нет: бэкенд отдаст цену каждого партнёра на
    // переданный набор, а заглушка всегда показывает один и тот же.
    return mockOffers;
  }
}
