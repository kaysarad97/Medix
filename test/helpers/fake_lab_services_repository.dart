import 'package:medix/features/lab_services/data/repositories/lab_services_repository.dart';
import 'package:medix/features/lab_services/domain/entities/lab_offer.dart';
import 'package:medix/features/lab_services/domain/entities/lab_service.dart';

/// Те же данные, что у [MockLabServicesRepository], но без задержки: таймер
/// вне `runAsync` роняет виджет-тест на «timersPending».
class FakeLabServicesRepository implements LabServicesRepository {
  const FakeLabServicesRepository();

  @override
  Future<List<LabService>> services() async =>
      MockLabServicesRepository.mockServices;

  @override
  Future<List<LabOffer>> offersFor(Set<String> serviceIds) async =>
      MockLabServicesRepository.mockOffers;
}
