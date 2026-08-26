import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/family_access/data/repositories/family_repository.dart';
import 'package:medix/features/family_access/domain/entities/family_member_draft.dart';
import 'package:medix/shared/models/family_member.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test(
    'список, добавление, правка и удаление используют семейный API',
    () async {
      final (:dio, :adapter) = cannedDio({
        'GET /users/me/family': (statusCode: 200, body: [_member()]),
        'POST /users/me/family': (statusCode: 201, body: _member()),
        'PATCH /users/me/family/f1': (statusCode: 200, body: _member()),
        'DELETE /users/me/family/f1': (statusCode: 204, body: const {}),
      });
      final repository = RemoteFamilyRepository(dio);
      final draft = FamilyMemberDraft(
        fullName: 'Айша Иванова',
        birthDate: DateTime(2018, 4, 2),
        relation: FamilyRelation.child,
      );

      expect(await repository.members(), hasLength(1));
      await repository.add(draft);
      await repository.update('f1', draft);
      await repository.remove('f1');

      expect(adapter.requests[1].data, {
        'full_name': 'Айша Иванова',
        'birth_date': '2018-04-02',
        'relation': 'child',
      });
      expect(adapter.requests.map((request) => request.method), [
        'GET',
        'POST',
        'PATCH',
        'DELETE',
      ]);
    },
  );

  test('деталь члена семьи читает серверный аватар', () async {
    final (:dio, :adapter) = cannedDio({
      'GET /users/me/family/f1': (statusCode: 200, body: _member()),
    });

    final member = await RemoteFamilyRepository(dio).member('f1');

    expect(member.fullName, 'Айша Иванова');
    expect(member.avatarUrl, 'https://storage.example/family/f1/avatar.png');
    expect(adapter.requests.single.path, '/users/me/family/f1');
  });

  test('аватар получает presigned-форму и подтверждает ключ', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /users/me/family/f1/avatar/upload-url': (
        statusCode: 200,
        body: {
          'upload_url': 'https://storage.example/upload',
          'fields': {'policy': 'signed'},
          'key': 'family/f1/avatar.png',
          'expires_at': '2026-08-24T12:00:00Z',
        },
      ),
      'POST /users/me/family/f1/avatar': (statusCode: 200, body: _member()),
    });
    final repository = RemoteFamilyRepository(dio);

    final ticket = await repository.requestAvatarUpload(
      'f1',
      filename: 'avatar.png',
      contentType: 'image/png',
    );
    final member = await repository.confirmAvatar('f1', ticket.key);

    expect(ticket.fields['policy'], 'signed');
    expect(member.avatarUrl, endsWith('avatar.png'));
    expect(adapter.requests.first.data, {
      'filename': 'avatar.png',
      'content_type': 'image/png',
    });
    expect(adapter.requests.last.data, {'avatar_s3_key': ticket.key});
  });
}

Map<String, dynamic> _member() => {
  'id': 'f1',
  'full_name': 'Айша Иванова',
  'birth_date': '2018-04-02',
  'relation': 'child',
  'sex': 'female',
  'iin': '180402600123',
  'avatar_url': 'https://storage.example/family/f1/avatar.png',
};
