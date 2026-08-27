# MedIx — HANDOFF

Актуальный срез для продолжения разработки.

Дата: **27 августа 2026**.

Продуктовые требования — в `PROJECT.md`, команды и правила разработки — в `README.md`. Этот файл фиксирует текущее состояние, принятые решения и ближайший остаток.

## Текущий статус

- Flutter frontend практически **feature-complete по текущему доступному Figma-дизайну**.
- В `main` реализованы основные пациентские экраны, кабинет врача, врач-фрилансер, карта, оплата, лаборатории, чаты, звонки и административные сценарии.
- Отсутствие backend endpoint не считается фронтовым блокером: если UI по Figma готов, используется mock/fake repository и задача считается frontend-complete.
- API transport для мобильных ролей ранее доведён до **78/78 операций**.
- CI Windows MAX_PATH исправлен в MED-89; golden checkout и golden tests снова работают.
- Logout и doctor no-show уже смержены.
- Три устаревших golden-эталона после logout пересняты и смержены.

## Figma

Канонический файл:

`https://www.figma.com/design/F6hQy6JyF4pl2b8S9K1IhJ/App-Prototyping?node-id=286-2152&p=f`

- fileKey: `F6hQy6JyF4pl2b8S9K1IhJ`
- основной клиентский canvas: `286:2152` (`Клиент`)

Frontend-аудит проводился по цепочке **Linear → Figma → актуальный main**.

По доступному экспортированному комплекту макетов и проверенным live Figma nodes после аудита найден один подтверждённый фронтовый пробел — отдельный шаг регистрации врача-фрилансера «Загрузите Ваши сертификаты». Он исправляется в PR #5.

Важно: Figma View-seat во время последней проверки достиг лимита вызовов. Поэтому после восстановления лимита полезно сделать финальный live-pass только на предмет новых макетов, добавленных после текущего экспорта.

## GitHub / PR

Уже смержено:

- PR #1 — logout;
- PR #2 — doctor no-show;
- PR #3 — MED-89 Windows `core.longpaths=true` до checkout;
- PR #4 — обновление 3 stale golden-эталонов.

Текущий открытый PR:

### PR #5 — шаг загрузки сертификатов врача-фрилансера

`https://github.com/kaysarad97/Medix/pull/5`

Ветка:

`kaysarad97/figma-doctor-certificate-registration`

Что исправлено:

- registration-state сертификатов отделён от обычного кабинетного экрана;
- добавлен отдельный шаг по макету `design/врач фрилансер/Загрузки документов.png`;
- есть progress bar, выбор файла, отображение выбранного файла, поле специализации и кнопка «Далее»;
- существующая загрузка credentials сохранена;
- обычный `DoctorCertificatesScreen` кабинета не меняется;
- добавлен widget-test на registration-state.

### Состояние CI PR #5

Workflow run `33070365171`:

- Windows golden job — **success**;
- checkout long paths — **success**;
- golden tests — **success**;
- обычный job — **failure только на `dart format`**;
- `flutter analyze` и обычные tests были skipped после format failure.

Следующий шаг по PR #5: применить форматирование к изменённым Dart-файлам, запушить и дождаться полного зелёного CI, затем merge.

## Linear — актуальный рабочий пул

После сверки frontend-задачи приведены к критерию «UI по Figma готов = Done».

В **Done** переведены, среди прочего:

- MED-32 — История процедур;
- MED-37 — Способ оплаты;
- MED-38 — Ввод данных карты;
- MED-51 — Поиск на карте;
- MED-52 — Поиск лабораторий на карте;
- MED-53 — Поиск больниц на карте;
- MED-54 — Карточка лаборатории;
- MED-55 — Перечень услуг;
- MED-56 — Перечень услуг — комплексы;
- MED-79 — Мои заявки;
- MED-80 — Заявка в администрацию;
- MED-81 — Ответ администрации;
- MED-84 — Рабочие часы врача.

Помечены как дубли:

- MED-28 — Детский поиск врача → `Duplicate` существующего поиска по специализации;
- MED-36 — Экран предоплаты (общий) → `Duplicate` существующего состояния предоплаты без подписки.

### Реально открытые задачи

1. **MED-66 — Платёжный шлюз** — Todo. Нужна реальная платёжная интеграция/backend/provider. UI уже готов.
2. **MED-63 — Push-уведомления** — Todo. REST `/devices` transport есть, но нужен FCM/APNs token lifecycle, регистрация/удаление device и хранение server device id.
3. **MED-64 — Локализация** — In Review. Техническая локализация ru/kk/en сделана; перед релизом нужен native-speaker review казахского и английского текста.

## Backend / интеграции, которые не считать frontend-долгом

Следующие сценарии могут работать на mocks до появления контрактов:

- поиск мест на карте и реальные данные больниц/лабораторий;
- каталог анализов/комплексов и реальные цены;
- заявки врача в администрацию;
- платёжный provider;
- отдельные семейные/лабораторные данные, которых backend пока не отдаёт.

Не открывать заново UI-задачи только из-за отсутствия endpoint. Для backend работы создавать/вести отдельные integration-задачи.

## LiveKit / звонки

Клиентский экран звонка уже поддерживает LiveKit-сессию и получает токен через backend-контур; Flutter не должен хранить LiveKit secret.

Для реального E2E видеозвонка всё ещё нужны:

- рабочая конфигурация LiveKit на backend/environment;
- реальные server URL/token;
- проверка на двух клиентах/ролях.

Не добавлять LiveKit secret в Flutter.

## Push

Transport для device endpoints есть, но lifecycle не закрыт. MED-63 должен включать минимум:

- получение FCM/APNs token;
- регистрацию device после auth/получения token;
- обновление при rotation token;
- сохранение server device id;
- удаление device при logout, когда это возможно;
- разрешения notifications и обработку platform-specific состояний.

## Платежи

Экраны способов оплаты, карты, ожидания, success/failure и предоплаты уже существуют. Пока нет реального gateway, это frontend-complete состояние с mock result.

MED-66 — интеграционная задача, а не повод создавать новые UI-экраны.

## Локализация

- `gen-l10n`, locales `ru`, `kk`, `en`;
- русская ARB — template;
- generated `app_localizations*.dart` не коммитить;
- используется Golos Text для казахских glyphs.

MED-64 нельзя честно закрыть без native review kk/en. Можно исправлять техническую консистентность и glossary, но native sign-off должен сделать носитель языка.

## Архитектурные правила

Feature-first:

```text
lib/features/<feature>/
  data/
  domain/
  presentation/
lib/core/
lib/shared/
lib/l10n/
```

Основной стек:

- Flutter / Dart;
- Riverpod 3;
- go_router + `StatefulShellRoute.indexedStack`;
- Dio;
- secure storage;
- flutter_map;
- LiveKit;
- websocket_channel;
- file_selector;
- url_launcher;
- gen-l10n.

Правила:

- модели/виджеты для нескольких features выносить в `shared`/`core`;
- не импортировать internal-модели одного feature в другой без необходимости;
- в Riverpod 3 использовать Notifier-подходы, не возвращаться к устаревшим provider patterns;
- fake repositories всегда синхронизировать с интерфейсами;
- geometry tests вызывают `loadAppFonts()`;
- golden refs platform-sensitive, штатная сверка идёт Windows job;
- CI Flutter pinned `3.41.8`;
- `MEDIX_USE_MOCKS=true` включает mocks;
- `MEDIX_API_URL` задаёт backend URL.

Основной CI job:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --exclude-tags golden
```

## Что делать следующим разработчику

Порядок:

1. Исправить `dart format` в PR #5, дождаться полного зелёного CI и смержить PR.
2. После merge считать frontend по текущему утверждённому Figma закрытым.
3. Взять MED-63 Push lifecycle как ближайшую независимую интеграционную задачу.
4. Затем MED-66 Payment gateway после выбора/готовности provider/backend.
5. MED-64 оставить на native review перед релизом.
6. Параллельно проверить реальный LiveKit environment и провести двухклиентный E2E звонка.
7. После восстановления Figma connector quota выполнить короткий финальный live-pass на новые/изменённые макеты.

## Важные продуктовые решения

- Gold удалён/no-op; актуальная продуктовая логика — Basic/Silver. Не возвращать Gold из старых Figma-макетов без нового решения.
- Google auth исключён из MVP.
- Buffer Strategy и SOS 103 исключены из MVP.
- Отсутствие backend не блокирует завершение Figma frontend.
- Отдельный детский поиск врача сейчас не нужен: педиатрия покрывается существующим поиском по специализации.
- Отдельный «общий» экран предоплаты не нужен: состояния объединены существующим компонентом.

---

Если этот файл расходится со старым аудитом от 25 августа, приоритет у текущего `main`, актуального Linear и этого HANDOFF.