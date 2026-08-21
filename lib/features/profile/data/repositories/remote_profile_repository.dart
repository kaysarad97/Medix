import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/gender.dart';
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
      return _profile(response.data!, await _subscription());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {
          'full_name': '${profile.lastName} ${profile.firstName}'.trim(),
          'birth_date': profile.birthDate?.toIso8601String().split('T').first,
          'sex': profile.gender?.name,
          'iin': profile.iin,
        },
      );
      return _profile(response.data!, profile.subscription);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<AvatarUploadTicket> requestAvatarUpload({
    required String filename,
    required String contentType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.myAvatarUploadUrl,
        data: {'filename': filename, 'content_type': contentType},
      );
      final json = response.data!;
      return AvatarUploadTicket(
        uploadUrl: json['upload_url'] as String,
        fields: (json['fields'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as String),
        ),
        key: json['key'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<UserProfile> confirmAvatar(String s3Key) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.myAvatar,
        data: {'avatar_s3_key': s3Key},
      );
      return _profile(response.data!, await _subscription());
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static UserProfile _profile(
    Map<String, dynamic> json,
    SubscriptionTier subscription,
  ) {
    final fullName = (json['full_name'] as String? ?? '').trim();
    final space = fullName.indexOf(' ');
    return UserProfile(
      id: json['id'] as String,
      // На регистрации поле подписано «ФИО»: фамилия идёт первой.
      firstName: space == -1 ? fullName : fullName.substring(space + 1).trim(),
      lastName: space == -1 ? '' : fullName.substring(0, space),
      email: json['email'] as String?,
      iin: json['iin'] as String?,
      birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
      gender: switch (json['sex']) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => null,
      },
      subscription: subscription,
      avatarUrl: json['avatar_url'] as String?,
      // Рост и вес лежат в мед-карте отдельными записями measurement.
    );
  }

  /// Тариф из действующей подписки. Её нет — сервер отвечает 404, и это
  /// нормальный ответ: значит, тариф бесплатный.
  Future<SubscriptionTier> _subscription() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mySubscription,
      );
      return SubscriptionTier.fromCode(response.data?['plan_code']);
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
        case 'measurement':
          final value = (payload['value'] as num?)?.round();
          card = switch (payload['kind']) {
            'height' => card.copyWith(heightCm: value),
            'weight' => card.copyWith(weightKg: value),
            _ => card,
          };
        case 'note':
          card = _applyNote(card, payload['title'] as String?, details);
      }
    }
    return card;
  }

  @override
  Future<List<MeasurementPoint>> measurementHistory(
    MeasurementKind kind, {
    String? familyMemberId,
    DateTime? from,
    DateTime? to,
  }) async {
    final path = familyMemberId == null
        ? ApiEndpoints.medicalRecordHistory
        : ApiEndpoints.familyMedicalRecordHistory(familyMemberId);
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          'kind': kind.apiValue,
          'from': ?from?.toUtc().toIso8601String(),
          'to': ?to?.toUtc().toIso8601String(),
        },
      );
      return [
        for (final item in response.data ?? const [])
          _measurementPoint(item as Map<String, dynamic>, kind),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static MeasurementPoint _measurementPoint(
    Map<String, dynamic> json,
    MeasurementKind requestedKind,
  ) {
    final payload = json['payload'] as Map<String, dynamic>? ?? const {};
    final kind = switch (payload['kind']) {
      'height' => MeasurementKind.height,
      'weight' => MeasurementKind.weight,
      _ => requestedKind,
    };
    return MeasurementPoint(
      id: json['id'] as String,
      kind: kind,
      value: (payload['value'] as num).toDouble(),
      unit: payload['unit'] as String,
      measuredAt: DateTime.parse(payload['measured_at'] as String).toLocal(),
    );
  }

  /// Полям, которым на сервере нет своего типа, остаются заметки с
  /// известным заголовком.
  ///
  /// ЭТО НАША ДОГОВОРЁННОСТЬ, А НЕ КОНТРАКТ, и осталась она только для
  /// операций и вредных привычек: у роста с весом с 17 августа 2026 есть
  /// свой `record_type: measurement`, и они переехали туда.
  static const String _surgeriesTitle = 'Операции';
  static const String _habitsTitle = 'Вредные привычки';

  /// Заголовки, которыми рост и вес лежали в заметках до появления
  /// `measurement`. Читаются, но больше не пишутся: у кого-то из тестовых
  /// аккаунтов такие заметки остались, и терять их при чтении незачем.
  static const String _legacyHeightTitle = 'Рост';
  static const String _legacyWeightTitle = 'Вес';

  static MedicalCard _applyNote(
    MedicalCard card,
    String? title,
    String? details,
  ) => switch (title) {
    _legacyHeightTitle => card.copyWith(heightCm: int.tryParse(details ?? '')),
    _legacyWeightTitle => card.copyWith(weightKg: int.tryParse(details ?? '')),
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
        // У замеров различает не заголовок, а `kind`: рост и вес — записи
        // одного типа.
        final key = type == 'measurement' ? 'kind' : 'title';
        if (payload[key] == title) return record['id'] as String;
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
    await _putMeasurement(put, 'height', card.heightCm, 'cm');
    await _putMeasurement(put, 'weight', card.weightKg, 'kg');
    if (card.hasBadHabits != null) {
      await _putText(
        put,
        'note',
        _habitsTitle,
        card.hasBadHabits! ? 'да' : 'нет',
      );
    }
  }

  /// Замер: у сервера свой тип записи со значением, единицей и временем.
  ///
  /// `measured_at` — момент сохранения, а не отдельное поле формы: в макете
  /// мед-карты рост и вес вводятся числом, без даты. По этой же метке
  /// строится история (`/users/me/medical-records/history?kind=`), так что
  /// каждая правка ложится в неё новой точкой.
  static Future<void> _putMeasurement(
    Future<void> Function(String, Map<String, dynamic>, [String?]) put,
    String kind,
    int? value,
    String unit,
  ) async {
    if (value == null) return;
    await put('measurement', {
      'kind': kind,
      'value': value,
      'unit': unit,
      'measured_at': DateTime.now().toUtc().toIso8601String(),
    }, kind);
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

  @override
  Future<List<MedicalProcedure>> procedures() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.appointments,
        queryParameters: {'upcoming': false, 'limit': 100},
      );
      return [
        for (final item in response.data ?? const [])
          if (_isOwnCompletedAppointment(item as Map<String, dynamic>))
            _procedure(item),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Семейные записи пока не попадают в этот список: ответ содержит только
  /// `family_member_id`, но не возраст или категорию профиля, а экран делит
  /// их на «ребёнка» и «старших». Присваивать категорию наугад нельзя.
  static bool _isOwnCompletedAppointment(Map<String, dynamic> json) =>
      json['status'] == 'completed' && json['family_member_id'] == null;

  static MedicalProcedure _procedure(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>? ?? const {};
    return MedicalProcedure(
      id: json['id'] as String,
      doctorName: (doctor['full_name'] as String? ?? '').trim(),
      specialty: (doctor['specialty'] as String? ?? '').trim(),
      date: DateTime.parse(json['starts_at'] as String).toLocal(),
    );
  }
}
