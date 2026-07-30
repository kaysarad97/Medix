import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class MedixApp extends ConsumerWidget {
  const MedixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      // Интерфейс русскоязычный; тёмной темы в макетах нет, поэтому
      // системная смена оформления игнорируется.
      themeMode: ThemeMode.light,
    );
  }
}
