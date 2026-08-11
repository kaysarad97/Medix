import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/family_access/data/repositories/family_repository.dart';
import 'package:medix/features/family_access/domain/entities/family_member_draft.dart';
import 'package:medix/shared/models/family_member.dart';

/// Разбор ответа сервера: ФИО приходит одной строкой, родство — свободным
/// текстом, а карточке нужны отдельные имя с фамилией и одна из двух групп.
///
/// Проверяется через заглушку: разбор у неё и у боевой реализации общий,
/// а сеть для этого поднимать незачем.
void main() {
  Future<FamilyMember> added({
    required String fullName,
    required String relation,
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

  test(
    'ФИО раскладывается на фамилию и имя, отчество остаётся при имени',
    () async {
      final member = await added(
        fullName: 'Иванов Пётр Сергеевич',
        relation: 'сын',
      );

      expect(member.lastName, 'Иванов');
      expect(member.firstName, 'Пётр Сергеевич');
      expect(member.fullName, 'Пётр Сергеевич Иванов');
    },
  );

  test('одно слово в ФИО не даёт висящего пробела', () async {
    final member = await added(fullName: 'Пётр', relation: 'сын');

    expect(member.lastName, isEmpty);
    expect(member.fullName, 'Пётр');
  });

  test('знакомое родство определяет группу, а не возраст', () async {
    // Мама 1980 года рождения — взрослая и по возрасту, но проверяем именно
    // слово: с ним разбор не зависит от даты.
    final mother = await added(
      fullName: 'Иванова Мария',
      relation: 'мама',
      birthDate: DateTime(1980, 3, 12),
    );
    final son = await added(
      fullName: 'Иванов Пётр',
      relation: 'сын',
      birthDate: DateTime(2018, 4, 2),
    );

    expect(mother.relation, FamilyRelation.senior);
    expect(son.relation, FamilyRelation.child);
  });

  test('незнакомое родство раскладывается по возрасту', () async {
    final now = DateTime.now();
    final child = await added(
      fullName: 'Иванов Тимур',
      relation: 'племянник',
      birthDate: DateTime(now.year - 7, now.month, now.day),
    );
    final adult = await added(
      fullName: 'Иванов Тимур',
      relation: 'племянник',
      birthDate: DateTime(now.year - 40, now.month, now.day),
    );

    expect(child.relation, FamilyRelation.child);
    expect(adult.relation, FamilyRelation.senior);
  });

  test('исходное слово сохраняется для поля «Родство с Вами»', () async {
    final member = await added(fullName: 'Иванов Пётр', relation: 'племянник');

    expect(member.relationshipLabel, 'племянник');
  });

  test('пол с сервера не приходит — в карточке прочерк', () async {
    final member = await added(fullName: 'Иванов Пётр', relation: 'сын');

    expect(member.gender, isNull);
    expect(member.genderLabel, '—');
  });
}
