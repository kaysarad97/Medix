import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/family_access/data/repositories/family_repository.dart';
import 'package:medix/features/family_access/domain/entities/family_member_draft.dart';
import 'package:medix/shared/models/family_member.dart';
import 'package:medix/shared/models/gender.dart';

/// Разбор ответа сервера: ФИО приходит одной строкой, родство —
/// перечислением, а карточке нужны отдельные имя с фамилией.
///
/// Проверяется через заглушку: разбор у неё и у боевой реализации общий,
/// а сеть для этого поднимать незачем.
void main() {
  Future<FamilyMember> added({
    required String fullName,
    FamilyRelation relation = FamilyRelation.child,
    DateTime? birthDate,
  }) {
    return MockFamilyRepository().add(
      FamilyMemberDraft(
        fullName: fullName,
        birthDate: birthDate ?? DateTime(2018, 4, 2),
        relation: relation,
      ),
    );
  }

  test('имя и фамилия режутся по первому пробелу', () async {
    final member = await added(fullName: 'Пётр Иванов');

    expect(member.firstName, 'Пётр');
    expect(member.lastName, 'Иванов');
    expect(member.fullName, 'Пётр Иванов');
  });

  test('одно слово в имени не даёт висящего пробела', () async {
    final member = await added(fullName: 'Пётр');

    expect(member.lastName, isEmpty);
    expect(member.fullName, 'Пётр');
  });

  test('родство доходит до сервера и обратно как есть', () async {
    // Раньше группу угадывали по слову и по возрасту: сервер хранил
    // свободный текст. С 17 августа 2026 угадывать нечего.
    final mother = await added(
      fullName: 'Иванова Мария',
      relation: FamilyRelation.parent,
      birthDate: DateTime(1980, 3, 12),
    );
    final son = await added(
      fullName: 'Иванов Пётр',
      relation: FamilyRelation.child,
    );

    expect(mother.relation, FamilyRelation.parent);
    expect(son.relation, FamilyRelation.child);
    expect(son.relation.isChild, isTrue);
    expect(mother.relation.isChild, isFalse);
  });

  test('незнакомое значение родства не роняет разбор', () {
    // Сервер может завести новую степень родства раньше, чем приложение о
    // ней узнает.
    expect(FamilyRelation.fromApi('grandparent'), FamilyRelation.other);
    expect(FamilyRelation.fromApi(null), FamilyRelation.other);
    expect(FamilyRelation.fromApi('sibling'), FamilyRelation.sibling);
  });

  test('пол читается из ответа, а без него — прочерк', () {
    final member = MockFamilyRepository.mockMembers.first;
    expect(member.gender, Gender.male);

    // У заведённых через форму пола нет: она его не спрашивает.
    expect(
      MockFamilyRepository()
          .add(
            FamilyMemberDraft(
              fullName: 'Иванов Пётр',
              birthDate: DateTime(2018, 4, 2),
              relation: FamilyRelation.child,
            ),
          )
          .then((m) => m.genderLabel),
      completion('—'),
    );
  });
}
