import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/family_member.dart';
import '../../../../shared/models/gender.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../domain/entities/family_member_draft.dart';

abstract interface class FamilyRepository {
  Future<List<FamilyMember>> members();

  Future<List<MyDoctor>> doctorsOf(String memberId);

  Future<List<AnalysisResult>> analysesOf(String memberId);

  /// Заводит нового члена семьи и возвращает его уже с идентификатором.
  Future<FamilyMember> add(FamilyMemberDraft draft);

  Future<FamilyMember> update(String id, FamilyMemberDraft draft);

  Future<void> remove(String id);
}

/// Боевая реализация поверх FastAPI-бэкенда.
///
/// Сервер хранит о члене семьи три поля: `full_name`, `birth_date` и
/// `relation` свободным текстом. Пол, рост, вес и аватар, которые есть в
/// макетах карточки, на сервере отсутствуют — они приходят пустыми, и
/// карточка показывает на их месте прочерк.
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

  /// ЭНДПОИНТА НЕТ. Врачей члена семьи бэкенд не отдаёт: есть только его
  /// мед-карта (`/users/me/family/{id}/medical-records`), а записи в ней
  /// бывают пяти типов, и врача среди них нет. Пустой список честнее
  /// подставленных моков: карточка «Врачи…» покажет один заголовок.
  @override
  Future<List<MyDoctor>> doctorsOf(String memberId) async => const [];

  /// ЭНДПОИНТА НЕТ, по той же причине. Анализ — это число с единицей
  /// измерения и границами нормы, а `record_type` знает только
  /// `allergy·chronic_condition·medication·note·diagnosis`. Карточка
  /// анализов при пустом списке не рисуется вовсе.
  @override
  Future<List<AnalysisResult>> analysesOf(String memberId) async => const [];

  static Map<String, dynamic> _body(FamilyMemberDraft draft) => {
    'full_name': draft.fullName,
    'birth_date': _formatDate(draft.birthDate),
    'relation': draft.relation,
  };

  /// Дата в формате, который ждёт бэкенд: `2018-04-02`.
  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static FamilyMember _member(Map<String, dynamic> json) {
    final fullName = (json['full_name'] as String? ?? '').trim();
    final relation = (json['relation'] as String? ?? '').trim();
    final birthDate =
        DateTime.tryParse(json['birth_date'] as String? ?? '') ??
        DateTime(1900);

    return FamilyMember(
      id: json['id'] as String,
      firstName: _firstName(fullName),
      lastName: _lastName(fullName),
      birthDate: birthDate,
      relation: _relation(relation, birthDate),
      relationshipLabel: relation.isEmpty ? null : relation,
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

  /// Возраст, при котором член семьи перестаёт быть «ребёнком» в подписях
  /// карточек. Совершеннолетие в РК.
  static const int _adultAge = 18;

  /// В приложении две группы — дети и старшее поколение, от них зависят
  /// подписи карточек и аватар по умолчанию. На сервере вместо групп
  /// свободный текст («сын», «мама»), поэтому разбираем знакомые слова, а
  /// незнакомые раскладываем по возрасту.
  ///
  /// ВОПРОС БЭКЕНДУ: будет ли у `relation` словарь значений. Со словарём
  /// разбор строк здесь не нужен.
  static FamilyRelation _relation(String relation, DateTime birthDate) {
    const child = {
      'сын',
      'дочь',
      'дочка',
      'ребенок',
      'ребёнок',
      'внук',
      'внучка',
    };
    const senior = {
      'мама',
      'мать',
      'папа',
      'отец',
      'бабушка',
      'дедушка',
      'бабуля',
      'дедуля',
    };

    final word = relation.toLowerCase();
    if (child.contains(word)) return FamilyRelation.child;
    if (senior.contains(word)) return FamilyRelation.senior;

    final now = DateTime.now();
    var years = now.year - birthDate.year;
    final hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) years -= 1;
    return years < _adultAge ? FamilyRelation.child : FamilyRelation.senior;
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
    // Пол, рост, вес и аватар форма не трогает — их на сервере нет, и
    // сохранились они только у моков с макетов. Переносим как были.
    final old = _members[index];
    final member = _fromDraft(id, draft);
    _members[index] = FamilyMember(
      id: member.id,
      firstName: member.firstName,
      lastName: member.lastName,
      birthDate: member.birthDate,
      relation: member.relation,
      relationshipLabel: member.relationshipLabel,
      gender: old.gender,
      registrationAddress: old.registrationAddress,
      heightCm: old.heightCm,
      weightKg: old.weightKg,
      avatarAsset: old.avatarAsset,
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
        'relation': draft.relation,
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
      relation: FamilyRelation.senior,
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
