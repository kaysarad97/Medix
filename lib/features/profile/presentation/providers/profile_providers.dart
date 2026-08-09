import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/app_language.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../../../shared/services/preferences_service.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/medical_card.dart';
import '../../domain/entities/medical_procedure.dart';
import '../../domain/entities/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockProfileRepository(),
);

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).profile(),
);

/// Аватарка, выбранная на экране «Выбор аватарки».
///
/// Живёт в памяти: поля под неё нет ни у бэкенда, ни у заглушки профиля,
/// а хранилища настроек в проекте пока нет — как и у выбора языка, после
/// перезапуска выбор сбрасывается. Появится хранилище — обе настройки
/// переедут в него вместе.
class AvatarSelection extends Notifier<String?> {
  @override
  String? build() => ref.read(preferencesServiceProvider).readAvatar();

  Future<void> select(String asset) async {
    state = asset;
    await ref.read(preferencesServiceProvider).saveAvatar(asset);
  }
}

final avatarSelectionProvider = NotifierProvider<AvatarSelection, String?>(
  AvatarSelection.new,
);

/// Что показывать в шапках: выбранное пользователем, иначе то, что пришло
/// с профилем.
final userAvatarProvider = Provider<String?>((ref) {
  return ref.watch(avatarSelectionProvider) ??
      ref.watch(profileProvider).value?.avatarAsset;
});

final medicalCardProvider = FutureProvider<MedicalCard>(
  (ref) => ref.watch(profileRepositoryProvider).medicalCard(),
);

final myDoctorsProvider = FutureProvider<List<MyDoctor>>(
  (ref) => ref.watch(profileRepositoryProvider).myDoctors(),
);

final analysesProvider = FutureProvider<List<AnalysisResult>>(
  (ref) => ref.watch(profileRepositoryProvider).analyses(),
);

final proceduresProvider = FutureProvider<List<MedicalProcedure>>(
  (ref) => ref.watch(profileRepositoryProvider).procedures(),
);

/// Строка поиска в «Название процедуры».
class ProcedureSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final procedureSearchQueryProvider =
    NotifierProvider<ProcedureSearchQuery, String>(ProcedureSearchQuery.new);

/// Вкладка «Мои процедуры» / «Процедуры ребёнка» / «Процедуры старших».
class ProcedureScopeFilter extends Notifier<FamilyScope> {
  @override
  FamilyScope build() => FamilyScope.self;

  void select(FamilyScope scope) => state = scope;
}

final procedureScopeFilterProvider =
    NotifierProvider<ProcedureScopeFilter, FamilyScope>(
      ProcedureScopeFilter.new,
    );

/// Процедуры с учётом вкладки и поиска — то, что реально попадает в список
/// на экране.
final visibleProceduresProvider = Provider<List<MedicalProcedure>>((ref) {
  final all = ref.watch(proceduresProvider).value ?? const [];
  final scope = ref.watch(procedureScopeFilterProvider);
  final query = ref.watch(procedureSearchQueryProvider).trim().toLowerCase();

  return all.where((p) {
    if (p.scope != scope) return false;
    if (query.isEmpty) return true;
    return p.doctorName.toLowerCase().contains(query) ||
        p.specialty.toLowerCase().contains(query);
  }).toList();
});

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

  /// Выбранный язык интерфейса. Системный не подхватываем: русский —
  /// язык по умолчанию для казахстанского рынка, см. [MedixApp].
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
  AppSettings build() {
    final stored = ref.read(preferencesServiceProvider).readLanguage();
    return AppSettings(language: AppLanguage.byCode(stored) ?? AppLanguage.ru);
  }

  void toggleNotifications(bool enabled) =>
      state = state.copyWith(notificationsEnabled: enabled);

  /// Экран не ждёт записи: интерфейс переключается сразу, на диск значение
  /// уходит следом. Не дойдёт — потеряется ровно один выбор, а не сессия.
  Future<void> selectLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await ref.read(preferencesServiceProvider).saveLanguage(language.code);
  }
}
