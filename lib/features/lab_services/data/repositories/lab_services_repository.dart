import '../../domain/entities/lab_service.dart';

abstract interface class LabServicesRepository {
  Future<List<LabService>> services();
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
  ];

  @override
  Future<List<LabService>> services() async {
    await Future<void>.delayed(_latency);
    return mockServices;
  }
}
