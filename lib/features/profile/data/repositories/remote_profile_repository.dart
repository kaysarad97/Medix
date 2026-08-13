import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../domain/entities/medical_card.dart';
import '../../domain/entities/medical_procedure.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_repository.dart';

/// Профиль и мед-карта поверх FastAPI-бэкенда.
///
/// Мед-карта на сервере — не документ, а лента записей: у каждой свой тип и
/// свой `payload`, правка не меняет запись, а заводит новую и помечает
/// старую `superseded_by`. Поэтому карта здесь собирается из записей при
/// чтении и раскладывается обратно при сохранении.
class RemoteProfileRepository implements ProfileRepository {
  const RemoteProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> profile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      final json = response.data!;
      final fullName = (json['full_name'] as String? ?? '').trim();
      final space = fullName.indexOf(' ');

      return UserProfile(
        id: json['id'] as String,
        // ФИО одной строкой, как и у члена семьи, но порядок обратный:
        // на регистрации поле подписано «ФИО», то есть фамилия впереди.
        firstName: space == -1
            ? fullName
            : fullName.substring(space + 1).trim(),
        lastName: space == -1 ? '' : fullName.substring(0, space),
        email: json['email'] as String?,
        subscription: await _subscription(),
        // Пол, рост, вес и аватар сервер не хранит; даты рождения нет в
        // ответе, хотя PATCH её принимает.
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Тариф из действующей подписки. Её нет — сервер отвечает 404, и это
  /// нормальный ответ: значит, тариф бесплатный.
  Future<SubscriptionTier> _subscription() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mySubscription,
      );
      return switch (response.data?['plan_code']) {
        'gold' => SubscriptionTier.gold,
        'silver' => SubscriptionTier.silver,
        _ => SubscriptionTier.free,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return SubscriptionTier.free;
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<MedicalCard> medicalCard() async {
    final records = await _records();
    var card = const MedicalCard();

    for (final record in records) {
      final payload = record['payload'] as Map<String, dynamic>? ?? const {};
      final details = payload['details'] as String?;

      switch (record['record_type']) {
        case 'blood_type':
          card = card.copyWith(
            bloodGroup: _groupFrom(payload['group'] as String?),
            rhesus: payload['rh'] == 'negative'
                ? RhesusFactor.negative
                : RhesusFactor.positive,
          );
        case 'allergy':
          card = card.copyWith(allergies: details);
        case 'chronic_condition':
          card = card.copyWith(
            hasChronicDiseases: true,
            chronicDiseases: details,
          );
        case 'note':
          card = _applyNote(card, payload['title'] as String?, details);
      }
    }
    return card;
  }

  /// Поля, которым на сервере нет своего типа, лежат заметками с известным
  /// заголовком.
  ///
  /// ЭТО НАША ДОГОВОРЁННОСТЬ, А НЕ КОНТРАКТ. `record_type` знает про кровь,
  /// аллергии, хронические, лекарства, диагнозы и заметки — ни роста, ни
  /// веса, ни операций, ни вредных привычек среди них нет, а в макете
  /// мед-карты они есть. Вопрос бэкенду: заводить ли им отдельные типы.
  static const String _heightTitle = 'Рост';
  static const String _weightTitle = 'Вес';
  static const String _surgeriesTitle = 'Операции';
  static const String _habitsTitle = 'Вредные привычки';

  static MedicalCard _applyNote(
    MedicalCard card,
    String? title,
    String? details,
  ) => switch (title) {
    _heightTitle => card.copyWith(heightCm: int.tryParse(details ?? '')),
    _weightTitle => card.copyWith(weightKg: int.tryParse(details ?? '')),
    _surgeriesTitle => card.copyWith(surgeries: details),
    _habitsTitle => card.copyWith(hasBadHabits: details == 'да'),
    _ => card,
  };

  static BloodGroup? _groupFrom(String? group) => switch (group) {
    'O' => BloodGroup.first,
    'A' => BloodGroup.second,
    'B' => BloodGroup.third,
    'AB' => BloodGroup.fourth,
    _ => null,
  };

  static String _groupOf(BloodGroup group) => switch (group) {
    BloodGroup.first => 'O',
    BloodGroup.second => 'A',
    BloodGroup.third => 'B',
    BloodGroup.fourth => 'AB',
  };

  Future<List<Map<String, dynamic>>> _records() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.medicalRecords,
      );
      return [
        for (final item in response.data ?? const [])
          item as Map<String, dynamic>,
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> saveMedicalCard(MedicalCard card) async {
    // Перечитываем перед записью: чтобы понять, править существующую запись
    // или заводить новую, нужно знать её идентификатор.
    final existing = await _records();

    String? idOf(String type, [String? title]) {
      for (final record in existing) {
        if (record['record_type'] != type) continue;
        if (title == null) return record['id'] as String;

        final payload = record['payload'] as Map<String, dynamic>? ?? const {};
        if (payload['title'] == title) return record['id'] as String;
      }
      return null;
    }

    Future<void> put(String type, Map<String, dynamic> payload, [String? t]) =>
        _upsert(recordType: type, payload: payload, id: idOf(type, t));

    final group = card.bloodGroup;
    if (group != null) {
      await put('blood_type', {
        'group': _groupOf(group),
        'rh': card.rhesus == RhesusFactor.negative ? 'negative' : 'positive',
      });
    }

    // Пустые поля не отправляем: у записей нет удаления, и пустая заметка
    // осталась бы в ленте навсегда.
    await _putText(put, 'allergy', 'Аллергии', card.allergies);
    if (card.hasChronicDiseases ?? false) {
      await _putText(
        put,
        'chronic_condition',
        'Хронические заболевания',
        card.chronicDiseases ?? 'да',
      );
    }
    await _putText(put, 'note', _surgeriesTitle, card.surgeries);
    await _putText(put, 'note', _heightTitle, card.heightCm?.toString());
    await _putText(put, 'note', _weightTitle, card.weightKg?.toString());
    if (card.hasBadHabits != null) {
      await _putText(
        put,
        'note',
        _habitsTitle,
        card.hasBadHabits! ? 'да' : 'нет',
      );
    }
  }

  static Future<void> _putText(
    Future<void> Function(String, Map<String, dynamic>, [String?]) put,
    String type,
    String title,
    String? details,
  ) async {
    if (details == null || details.trim().isEmpty) return;
    await put(type, {'title': title, 'details': details.trim()}, title);
  }

  Future<void> _upsert({
    required String recordType,
    required Map<String, dynamic> payload,
    String? id,
  }) async {
    final data = {
      'family_member_id': null,
      'record_type': recordType,
      'payload': payload,
    };
    try {
      if (id == null) {
        await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.medicalRecords,
          data: data,
        );
      } else {
        await _dio.patch<Map<String, dynamic>>(
          ApiEndpoints.medicalRecord(id),
          data: data,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ЭНДПОИНТА НЕТ. «Мои Врачи» вывести неоткуда: в записях к врачу нет ни
  /// врача, ни времени — см. `RemoteDoctorsRepository`.
  @override
  Future<List<MyDoctor>> myDoctors() async => const [];

  /// ЭНДПОИНТА НЕТ. Анализ — число с единицей измерения и границами нормы,
  /// а `record_type` таких записей не знает. Лабораторная ветка сервера
  /// (`/lab`) пока отвечает заглушкой.
  @override
  Future<List<AnalysisResult>> analyses() async => const [];

  /// ЭНДПОИНТА НЕТ. Прошедшие приёмы можно было бы взять из своих записей,
  /// но в них нет ни врача, ни специальности, ни времени.
  @override
  Future<List<MedicalProcedure>> procedures() async => const [];
}
