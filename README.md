# MedIx

Мобильное приложение агрегатора здравоохранения для Казахстана.
Описание продукта, состав фич и ограничения — в [PROJECT.md](PROJECT.md).

Flutter, архитектура feature-first, состояние на Riverpod.

## Установка на новой машине

Понадобится:

| | Версия | Зачем |
|---|---|---|
| Git | любая свежая | |
| Flutter | **ровно 3.41.8** | закреплена в CI; смена версии меняет растеризацию и ломает golden-тесты |
| JDK | 17 | совпадает с `sourceCompatibility` в `android/app/build.gradle.kts` |
| Android Studio | любая свежая | ради Android SDK и эмулятора |
| Xcode | — | только на macOS, для сборки под iOS |

Проверить, что всё встало: `flutter doctor`.

**Клонировать в путь без кириллицы и пробелов.** Android Gradle Plugin
отказывается собирать проект, если в пути есть не-ASCII символы, и падает
с `Your project path contains non-ASCII characters` ещё до компиляции.
Годится `C:\dev\medix-app` или `~/dev/medix-app`; не годится
`C:\Users\Иван\Новая папка\medix-app`.

```bash
git clone https://github.com/Yerbol08/medix-app.git
```

```bash
flutter pub get
```

Чтобы git показывал кириллические имена файлов в `design/` как есть,
а не восьмеричными кодами:

```bash
git config core.quotepath false
```

### Если машина не на Windows

Эталоны golden-тестов сняты на Windows. На macOS и Linux шесть из них
будут падать из-за различий в сглаживании — это не поломка вёрстки.
Локально гоняй тесты без них, а источником истины считай windows-джобу
в CI:

```bash
flutter test --exclude-tags golden
```

### Отладочные сборки с разных машин

Debug-подпись генерируется на каждой машине своя, поэтому установить
сборку с ноутбука Б поверх сборки с ноутбука А не выйдет: Android ответит
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Достаточно удалить приложение
с телефона перед первой установкой с другой машины.

## Запуск

```bash
flutter run
```

Бэкенд (FastAPI) в разработке, поэтому по умолчанию приложение работает
против заглушек. Переключение на реальный API:

```bash
flutter run --dart-define=MEDIX_USE_MOCKS=false --dart-define=MEDIX_API_URL=https://...
```

Сценарии заглушки: пароль `wrongpass` — отказ входа, почта `taken@medix.kz` —
занята при регистрации, код подтверждения `12345`.

## Проверки

```bash
dart format .
flutter analyze --fatal-infos
flutter test
```

## Golden-тесты

Экраны сверяются с макетами из `design/` попиксельно. Эталоны лежат
в `test/**/goldens/`.

```bash
flutter test --tags golden
flutter test --exclude-tags golden
flutter test --tags golden --update-goldens
```

Растеризация текста и теней зависит от платформы, поэтому эталоны привязаны
к Windows. В CI они гоняются отдельной джобой на `windows-latest` — см.
[.github/workflows/ci.yml](.github/workflows/ci.yml). Обновлять эталоны
только осознанно: расхождение обычно означает поехавшую вёрстку, а не
устаревший файл.

## CI

На каждый push и pull request в `main`:

| Джоба | Раннер | Что делает |
|---|---|---|
| Формат, анализ, тесты | ubuntu | `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, тесты без golden |
| Сверка с макетами | windows | golden-тесты; при расхождении выкладывает картинки различий артефактом |
| Сборка APK | ubuntu | debug-APK артефактом на 14 дней |

Версия Flutter в конвейере закреплена и должна совпадать с локальной —
её смена меняет растеризацию и ломает golden-тесты.

## О чём надо знать

**Шрифт обязан содержать казахские буквы** (ӘәҒғҚқҢңӨөҰұҮүҺһІі) —
интерфейс переключается на казахский. Стоит Golos Text. Onest, который
ближе к макетам по начертаниям, не подходит: в нём нет 16 из 18 этих букв.
Проверять покрытие при любой замене шрифта.

**Релиз подписывается debug-ключом.** См. `TODO` в
`android/app/build.gradle.kts`. До появления keystore выкладывать сборку
в Play Store нельзя, поэтому CI собирает только debug.

**Макеты нарисованы под 440×956** (iPhone 16 Pro Max). Это шире реальных
Android-телефонов, поэтому фиксированные размеры из макета нужно проверять
на узких экранах — `test/features/auth/responsive_layout_test.dart`
прогоняет вёрстку на 440, 393 и 360.

**Текст политики конфиденциальности — черновик.** На макете стоит пометка
дизайнера о согласовании с юристом; в коде лежит только структура разделов
и `TODO(legal)`.
