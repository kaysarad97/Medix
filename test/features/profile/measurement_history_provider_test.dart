import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/profile/data/repositories/profile_repository.dart';
import 'package:medix/features/profile/domain/entities/medical_card.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';

void main() {
  test('forwards owner, kind and date range to profile repository', () async {
    final repository = _RecordingProfileRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final from = DateTime.utc(2026, 7);
    final to = DateTime.utc(2026, 8);

    final result = await container.read(
      measurementHistoryProvider((
        kind: MeasurementKind.weight,
        familyMemberId: 'family-1',
        from: from,
        to: to,
      )).future,
    );

    expect(result.single.id, 'point-1');
    expect(repository.kind, MeasurementKind.weight);
    expect(repository.familyMemberId, 'family-1');
    expect(repository.from, from);
    expect(repository.to, to);
  });
}

class _RecordingProfileRepository extends MockProfileRepository {
  MeasurementKind? kind;
  String? familyMemberId;
  DateTime? from;
  DateTime? to;

  @override
  Future<List<MeasurementPoint>> measurementHistory(
    MeasurementKind kind, {
    String? familyMemberId,
    DateTime? from,
    DateTime? to,
  }) async {
    this.kind = kind;
    this.familyMemberId = familyMemberId;
    this.from = from;
    this.to = to;
    return [
      MeasurementPoint(
        id: 'point-1',
        kind: kind,
        value: 78,
        unit: 'kg',
        measuredAt: DateTime.utc(2026, 7, 15),
      ),
    ];
  }
}
