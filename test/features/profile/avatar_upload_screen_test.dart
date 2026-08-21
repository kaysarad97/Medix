import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/data/services/avatar_file_picker.dart';
import 'package:medix/features/profile/data/services/avatar_upload_service.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/avatar_picker_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('выбирает файл, загружает и обновляет профиль', (tester) async {
    final picker = _AvatarPicker();
    final upload = _AvatarUpload();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          avatarFilePickerProvider.overrideWithValue(picker),
          avatarUploadServiceProvider.overrideWithValue(upload),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AvatarPickerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Загрузить своё фото'));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(upload.file?.name, 'avatar.png');
    expect(find.text('Фотография профиля обновлена'), findsOneWidget);
  });
}

class _AvatarPicker implements AvatarFilePicker {
  int calls = 0;

  @override
  Future<PickedAvatarFile?> pick() async {
    calls++;
    return PickedAvatarFile(
      name: 'avatar.png',
      contentType: 'image/png',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
  }
}

class _AvatarUpload implements AvatarUploadService {
  PickedAvatarFile? file;

  @override
  Future<UserProfile> upload(PickedAvatarFile file) async {
    this.file = file;
    return const UserProfile(
      id: 'u1',
      firstName: 'Имя',
      lastName: 'Фамилия',
      subscription: SubscriptionTier.silver,
      avatarUrl: 'https://storage.example/avatar.png',
    );
  }
}
