import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/providers/profile_providers.dart';
import 'l10n/app_localizations.dart';
import 'shared/models/app_language.dart';

class MedixApp extends ConsumerWidget {
  const MedixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Язык выбирается на 4 шаге регистрации и в настройках (appSettingsProvider),
    // а не системой: RU — язык по умолчанию для казахстанского рынка вне
    // зависимости от локали устройства.
    final language = ref.watch(appSettingsProvider).language ?? AppLanguage.ru;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      // Тёмной темы в макетах нет, поэтому системная смена оформления
      // игнорируется.
      themeMode: ThemeMode.light,
      locale: Locale(language.code),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
