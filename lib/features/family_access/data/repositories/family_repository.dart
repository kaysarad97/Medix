import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/data/my_doctors_from_appointments.dart';
import '../../../../shared/models/family_member.dart';
import '../../../../shared/models/gender.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../domain/entities/family_avatar_upload_ticket.dart';
import '../../domain/entities/family_member_draft.dart';

abstract interface class FamilyRepository {
  Future<List<FamilyMember>> members();

  Future<FamilyMember> member(String id);

  Future<List<MyDoctor>> doctorsOf(String memberId);

  Future<List<AnalysisResult>> analysesOf(String memberId);

  Future<FamilyAvatarUploadTicket> requestAvatarUpload(
    String memberId, {
    required String filename,
    required String contentType,
  });

  Future<FamilyMember> confirmAvatar(String memberId, String s3Key);

  /// Заводит нового члена семьи и возвращает его уже с идентификатором.
  Future<FamilyMember> add(FamilyMemberDraft draft);

  Future<FamilyMember> update(String id, FamilyMemberDraft draft);

  Future<void> remove(String id);
}

/// Боевая реализация поверх FastAPI-бэкенда.
///
/// Сервер хранит о члене семьи `full_name`, `birth_date`, `relation`
/// (перечисление из пяти значений), `sex`, `iin` и аватар. Рост и вес из
/// макетов карточки он не хранит — они приходят пустыми, и карточка
/// показывает на их месте прочерк.
class RemoteFamilyRepository implements FamilyRepository {
  const RemoteFamilyRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<FamilyMember>> members() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.family);
      return [
        for (final item in response.data ?? const [])
          _member(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<FamilyMember> member(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.familyMember(id),
      );
      return _member(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<FamilyMember> add(FamilyMemberDraft draft) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.family,
        data: _body(draft),
      );
      return _member(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<FamilyMember> update(String id, FamilyMemberDraft draft) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.familyMember(id),
        data: _body(draft),
      );
      return _member(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.familyMember(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<MyDoctor>> doctorsOf(String memberId) async {
    try {
      return await fetchMyDoctorsFromAppointments(
        _dio,
        familyMemberId: memberId,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Серверный `/lab/results?family_member_id=` отдаёт файлы результатов,
  /// но не числовые показатели с единицами и границами нормы, которые нужны
  /// [AnalysisResult]. Файлы уже открываются отдельным экраном; эта карточка
  /// остаётся пустой до расширения контракта.
  @override
  Future<List<AnalysisResult>> analysesOf(String memberId) async => const [];

  @override
  Future<FamilyAvatarUploadTicket> requestAvatarUpload(
    String memberId, {
    required String filename,
    required String contentType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.familyMemberAvatarUploadUrl(memberId),
        data: {'filename': filename, 'content_type': contentType},
      );
      final json = response.data!;
      return FamilyAvatarUploadTicket(
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
  Future<FamilyMember> confirmAvatar(String memberId, String s3Key) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.familyMemberAvatar(memberId),
        data: {'avatar_s3_key': s3Key},
      );
      return _member(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static Map<String, dynamic> _body(FamilyMemberDraft draft) => {
    'full_name': draft.fullName,
    'birth_date': _formatDate(draft.birthDate),
    'relation': draft.relation.api,
  };

  /// Дата в формате, который ждёт бэкенд: `2018-04-02`.
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static FamilyMember _member(Map<String, dynamic> json) {
    final fullName = (json['full_name'] as String? ?? '').trim();

    return FamilyMember(
      id: json['id'] as String,
      firstName: _firstName(fullName),
      lastName: _lastName(fullName),
      birthDate:
          DateTime.tryParse(json['birth_date'] as String? ?? '') ??
          DateTime(1900),
      relation: FamilyRelation.fromApi(json['relation'] as String?),
      gender: switch (json['sex']) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => null,
      },
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Имя приходит одной строкой, а карточка ставит имя и фамилию разными
  /// строками — режем по первому пробелу.
  ///
  /// Порядок «Имя Фамилия», а не «Фамилия Имя»: так подписано поле в
  /// `design/Данные о родственниках.png`. У самого пользователя на шаге
  /// регистрации порядок обратный («ФИО»), но это другая форма и другая
  /// сущность — важно, чтобы разбор совпадал с тем, что мы же и отправили.
  static String _firstName(String fullName) {
    final space = fullName.indexOf(' ');
    return space == -1 ? fullName : fullName.substring(0, space);
  }

  static String _lastName(String fullName) {
    final space = fullName.indexOf(' ');
    return space == -1 ? '' : fullName.substring(space + 1).trim();
  }
}

/// Заглушка на время разработки бэкенда. Данные — с макетов
/// `design/Моя Семья Ребенок.png` и `design/Моя Семья Старшие.png`.
///
/// В обоих макетах карточки врачей и строки анализов совпадают дословно с
/// теми же блоками на `design/Профиль.png` — это повторяющийся
/// Figma-плейсхолдер, не разные данные. Мок здесь намеренно свой:
/// специальности и анализы подобраны по смыслу (педиатр ребёнку, кардиолог
/// старшим), а не скопированы один в один.
///
/// Список правится и живёт в памяти, а не пересоздаётся из [mockMembers]:
/// иначе добавленный член семьи исчезал бы при следующем чтении, и форму
/// нельзя было бы проверить без поднятого сервера.
class MockFamilyRepository implements FamilyRepository {
  MockFamilyRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  final List<FamilyMember> _members = [...mockMembers];

  /// Сквозной счётчик, а не длина списка: после удаления длина повторяется,
  /// и новый член семьи получил бы идентификатор уже удалённого.
  int _lastId = mockMembers.length;

  @override
  Future<List<FamilyMember>> members() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_members);
  }

  @override
  Future<FamilyMember> member(String id) async {
    await Future<void>.delayed(_latency);
    return _members.firstWhere((member) => member.id == id);
  }

  @override
  Future<List<MyDoctor>> doctorsOf(String memberId) async {
    await Future<void>.delayed(_latency);
    return mockDoctors[memberId] ?? const [];
  }

  @override
  Future<List<AnalysisResult>> analysesOf(String memberId) async {
    await Future<void>.delayed(_latency);
    return mockAnalyses[memberId] ?? const [];
  }

  @override
  Future<FamilyAvatarUploadTicket> requestAvatarUpload(
    String memberId, {
    required String filename,
    required String contentType,
  }) async {
    await Future<void>.delayed(_latency);
    return FamilyAvatarUploadTicket(
      uploadUrl: 'https://storage.example/family-avatar',
      fields: const {},
      key: 'family/$memberId/$filename',
      expiresAt: DateTime(2026, 8, 24, 12),
    );
  }

  @override
  Future<FamilyMember> confirmAvatar(String memberId, String s3Key) async {
    await Future<void>.delayed(_latency);
    return member(memberId);
  }

  @override
  Future<FamilyMember> add(FamilyMemberDraft draft) async {
    await Future<void>.delayed(_latency);
    final member = _fromDraft('f${++_lastId}', draft);
    _members.add(member);
    return member;
  }

  @override
  Future<FamilyMember> update(String id, FamilyMemberDraft draft) async {
    await Future<void>.delayed(_latency);
    final index = _members.indexWhere((m) => m.id == id);
    if (index == -1) {
      throw const ApiException('Член семьи не найден', statusCode: 404);
    }
    // Пол, рост, вес и аватар форма не трогает — их в ней нет. Переносим
    // как были.
    final old = _members[index];
    final member = _fromDraft(id, draft);
    _members[index] = FamilyMember(
      id: member.id,
      firstName: member.firstName,
      lastName: member.lastName,
      birthDate: member.birthDate,
      relation: member.relation,
      gender: old.gender,
      registrationAddress: old.registrationAddress,
      heightCm: old.heightCm,
      weightKg: old.weightKg,
      avatarAsset: old.avatarAsset,
      avatarUrl: old.avatarUrl,
    );
    return _members[index];
  }

  @override
  Future<void> remove(String id) async {
    await Future<void>.delayed(_latency);
    _members.removeWhere((member) => member.id == id);
  }

  /// Разбор ФИО и родства — тот же, что у боевой реализации: заглушка
  /// должна вести себя так же, иначе на ней не поймать ошибку разбора.
  static FamilyMember _fromDraft(String id, FamilyMemberDraft draft) =>
      RemoteFamilyRepository._member({
        'id': id,
        'full_name': draft.fullName,
        'birth_date': draft.birthDate.toIso8601String(),
        'relation': draft.relation.api,
      });

  static final List<FamilyMember> mockMembers = [
    FamilyMember(
      id: 'f1',
      firstName: 'Имя',
      lastName: 'Фамилия',
      gender: Gender.male,
      birthDate: DateTime(2020, 10, 7),
      relation: FamilyRelation.child,
      heightCm: 106,
      weightKg: 30,
      avatarAsset: MedixAvatars.all[5],
    ),
    FamilyMember(
      id: 'f2',
      firstName: 'Имя',
      lastName: 'Фамилия',
      gender: Gender.female,
      birthDate: DateTime(1957, 12, 9),
      relation: FamilyRelation.parent,
      heightCm: 168,
      weightKg: 64,
      avatarAsset: MedixAvatars.all[1],
    ),
  ];

  static const Map<String, List<MyDoctor>> mockDoctors = {
    'f1': [
      MyDoctor(id: 'd3', specialty: 'Педиатр', fullName: 'Ф. Имя Отчество'),
      MyDoctor(id: 'd2', specialty: 'Офтальмолог', fullName: 'Ф. Имя Отчество'),
    ],
    'f2': [
      MyDoctor(id: 'd4', specialty: 'Кардиолог', fullName: 'Ф. Имя Отчество'),
      MyDoctor(id: 'd2', specialty: 'Офтальмолог', fullName: 'Ф. Имя Отчество'),
    ],
  };

  static final Map<String, List<AnalysisResult>> mockAnalyses = {
    'f1': [
      AnalysisResult(
        id: 'af1-1',
        name: 'Гемоглобин',
        value: 128,
        unit: 'г/л',
        referenceLow: 110,
        referenceHigh: 140,
        takenAt: DateTime(2026, 6, 12),
      ),
      AnalysisResult(
        id: 'af1-2',
        name: 'Глюкоза',
        value: 4.6,
        unit: 'ммоль/л',
        referenceLow: 3.3,
        referenceHigh: 5.5,
        takenAt: DateTime(2026, 6, 12),
      ),
    ],
    'f2': [
      AnalysisResult(
        id: 'af2-1',
        name: 'Холестерин общий',
        value: 5.8,
        unit: 'ммоль/л',
        referenceLow: 3.0,
        referenceHigh: 5.2,
        takenAt: DateTime(2026, 5, 28),
      ),
      AnalysisResult(
        id: 'af2-2',
        name: 'Витамин D',
        value: 24,
        unit: 'нг/мл',
        referenceLow: 30,
        referenceHigh: 100,
        takenAt: DateTime(2026, 5, 28),
      ),
    ],
  };
}
