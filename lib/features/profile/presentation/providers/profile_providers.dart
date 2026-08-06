import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_language.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/medical_card.dart';
import '../../domain/entities/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockProfileRepository(),
);

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).profile(),
);

final medicalCardProvider = FutureProvider<MedicalCard>(
  (ref) => ref.watch(profileRepositoryProvider).medicalCard(),
);

final myDoctorsProvider = FutureProvider<List<MyDoctor>>(
  (ref) => ref.watch(profileRepositoryProvider).myDoctors(),
);

final analysesProvider = FutureProvider<List<AnalysisResult>>(
  (ref) => ref.watch(profileRepositoryProvider).analyses(),
);

/// Выбранная вкладка над списком анализов.
final analysesFilterProvider =
    NotifierProvider<AnalysesFilterNotifier, AnalysesFilter>(
      AnalysesFilterNotifier.new,
    );

class AnalysesFilterNotifier extends Notifier<AnalysesFilter> {
  @override
  // В макете белая пилюля стоит на «Все результаты».
  AnalysesFilter build() => AnalysesFilter.all;

  void select(AnalysesFilter filter) => state = filter;
}

/// Настройки приложения, которые правятся на экране «Настройки».
///
/// Живут в памяти: экран регистрации собирает их в свой контроллер, а
/// общего хранилища настроек пока нет — появится вместе с бэкендом.
class AppSettings {
  const AppSettings({this.notificationsEnabled = true, this.language});

  final bool notificationsEnabled;

  /// `null` — язык не выбирали, интерфейс на языке системы.
  final AppLanguage? language;

  AppSettings copyWith({bool? notificationsEnabled, AppLanguage? language}) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings(language: AppLanguage.ru);

  void toggleNotifications(bool enabled) =>
      state = state.copyWith(notificationsEnabled: enabled);

  void selectLanguage(AppLanguage language) =>
      state = state.copyWith(language: language);
}
