# ObjectBox Migration Plan — Simplified Architecture

> Phase 6 архітектурного плану. Замінює JSON file storage на ObjectBox, усуває рейс кондішни, спрощує шари провайдерів.

---

## Context

Поточна архітектура має задебагато шарів і рейс кондішни:
- `JsonFileStorage` → `AppState` (aggregate) → `AppStateNotifier` → `ShotProfileNotifier` → `SettingsNotifier` → `ShotConditionsNotifier` → `ConvertorsNotifier`
- Рейс кондішни в `deleteCartridge`/`deleteSight`: стан мутується до завершення cascaded storage deletes — невідповідність при помилці
- `moveProfileToFirst` зберігає кожен профіль окремо (без транзакції)
- ObjectBox (`ebalistyka_db`) вже налаштований і готовий, але не використовується

**Рішення:**
- ObjectBox = єдине джерело правди для persisted даних
- Старі класи `WeaponData`/`AmmoData`/`SightData`/`ProfileData` (JSON) → **extension methods on ObjectBox entities**
- `AppStateNotifier` залишається єдиним агрегатом в пам'яті (уникаємо рейс кондішнів з кількох StreamProviders)
- DB layer максимально голий — бізнес-логіка ТІЛЬКИ в extensions у main app

---

## Mapping: Old Classes → New

| Old (JSON class) | New (ObjectBox entity) | Extension file |
|---|---|---|
| `WeaponData` | `ebalistyka_db.Weapon` | `lib/core/extensions/weapon_extensions.dart` |
| `AmmoData` | `ebalistyka_db.Ammo` | `lib/core/extensions/ammo_extensions.dart` |
| `SightData` | `ebalistyka_db.Sight` | `lib/core/extensions/sight_extensions.dart` |
| `ProfileData` | `ebalistyka_db.Profile` | `lib/core/extensions/profile_extensions.dart` |
| `AppSettings` | `ebalistyka_db.GeneralSettings` + `UnitSettings` | `lib/core/extensions/settings_extensions.dart` |
| `ConvertorsState` (app model) | `ebalistyka_db.ConvertorsState` | `lib/core/extensions/settings_extensions.dart` |
| `Conditions` + `AtmoData` + `WindData` | `ebalistyka_db.ShootingConditions` (NEW) | `lib/core/extensions/conditions_extensions.dart` |

---

## Entity Changes in `ebalistyka_db`

**Modify `packages/ebalistyka_db/lib/src/entities.dart`:**

1. **`Profile`** — add `int sortOrder = 0` (replaces `moveProfileToFirst` re-save hack)
2. **Add `ShootingConditions` entity** — persists shooting conditions per Owner:

```dart
@Entity()
class ShootingConditions {
  @Id() int id = 0;
  double targetDistanceMeter = 100.0;
  double lookAngleRad = 0.0;
  double altitudeMeter = 0.0;
  double pressureHpa = 1013.25;
  double temperatureC = 15.0;
  double humidityFrac = 0.78;
  double powderTemperatureC = 15.0;
  bool usePowderSensitivity = false;
  bool useDiffPowderTemp = false;
  bool useCoriolis = false;
  double latitudeDeg = 0.0;
  double azimuthDeg = 0.0;
  // winds as parallel Float64Lists
  Float64List windVelocityMps = Float64List(0);
  Float64List windDirectionRad = Float64List(0);
  Float64List windUntilDistanceMeter = Float64List(0);
  final owner = ToOne<Owner>();
}
```

3. **`Owner`** — add backlink:
```dart
@Backlink('owner')
final conditions = ToMany<ShootingConditions>();
```

**Після змін:** `dart run build_runner build --delete-conflicting-outputs` у `packages/ebalistyka_db/`

---

## New Provider Architecture

**Зберігаємо `AppStateNotifier` як агрегат** — розбиття на per-entity StreamProviders викликає рейс кондішни (UI бачить несумісний стан коли кілька провайдерів перебудовуються незалежно).

```
storeProvider   (Provider<Store>)
ownerProvider   (Provider<Owner>)    — singleton Owner (token="local")
    │
    └── appStateProvider (AsyncNotifier<AppState>)
            │  — читає всі дані з ObjectBox при build()
            │  — CRUD через store.runInTransaction() (атомарно)
            │  — AppState: List<Ammo>, List<Sight>, List<Profile>,
            │    GeneralSettings, UnitSettings, TablesSettings,
            │    ConvertorsState, ShootingConditions
            │
            ├── cartridgesProvider      (selector → List<Ammo>)
            ├── sightsProvider          (selector → List<Sight>)
            ├── profilesProvider        (selector → List<Profile>)
            └── validProfilesProvider   (selector)

shotProfileProvider     (AsyncNotifier — watches appStateProvider)
shotConditionsProvider  (AsyncNotifier — watches appStateProvider, reads ShootingConditions)
settingsProvider        (AsyncNotifier — watches appStateProvider, reads GeneralSettings/UnitSettings)
convertorsProvider      (AsyncNotifier — watches appStateProvider)

recalcCoordinator (watches shotProfileProvider + shotConditionsProvider + settingsProvider)
```

**Видалено:** `appStorageProvider`, `JsonFileStorage`, `AppStorage` interface

---

## Race Conditions: Як усуваються

Старий патерн (проблемний):
```dart
state = AsyncData(newState);             // мутуємо стан першим
await storage.deleteProfile(id);         // якщо fails → невідповідність
```

Новий патерн (ObjectBox транзакція):
```dart
store.runInTransaction(TxMode.write, () {
  final orphanIds = profileBox
      .query(Profile_.ammo.equals(id)).build().find()
      .map((p) => p.id).toList();
  profileBox.removeMany(orphanIds);
  ammoBox.remove(id);
});
// AppStateNotifier перечитує дані → завжди consistent
```

---

## Extension Files: Відповідальності

### `weapon_extensions.dart` — `extension WeaponData on Weapon`
- Typed getters: `Distance get caliber`, `Angular get twist`, `Angular get zeroElevation`, `Distance? get barrelLength`
- `bclibc.Weapon toShotWeapon()`

### `ammo_extensions.dart` — `extension AmmoData on Ammo`
- `Velocity? get muzzleVelocity`, `Temperature get powderTemp`
- `List<CoefRow> get coefRows` (з Float64Lists)
- `bool get isReadyForCalculation`
- `bclibc.DragModel toDragModel()`

### `sight_extensions.dart` — `extension SightData on Sight`
- `Angular get sightHeight`, `Angular get horizontalOffset`
- Click unit helpers, `bool get isFFP`

### `profile_extensions.dart` — `extension ProfileData on Profile`
- `bool get isReadyForCalculation`
- `bclibc.Shot toZeroShot(ShootingConditions cond)`
- `bclibc.Shot toCurrentShot(ShootingConditions cond)`

### `conditions_extensions.dart` — `extension ConditionsData on ShootingConditions`
- `bclibc.Atmo get atmo`
- `Wind get wind`

### `settings_extensions.dart`
- `extension AppSettings on GeneralSettings`: `ThemeMode get flutterThemeMode`, `AdjustmentFormat get adjustmentFormat`
- `extension AppUnitSettings on UnitSettings`: `UnitPrefs get unitPrefs`

### `convertors_extensions.dart` — `extension ConvertorsData on ConvertorsState`
---

## ShotProfileNotifier — Спрощення

ObjectBox `ToOne<>` relations вже resolved — не потрібен ручний `_resolve()`:

```dart
class ShotProfileNotifier extends AsyncNotifier<Profile?> {
  Future<Profile?> build() async {
    final appState = await ref.watch(appStateProvider.future);
    return appState.generalSettings.activeProfile.target;
  }

  Future<void> selectProfile(Profile p) async =>
      ref.read(appStateProvider.notifier).saveActiveProfile(p);

  Future<void> selectWeapon(Weapon w) async =>
      ref.read(appStateProvider.notifier).updateProfileWeapon(state.value!, w);

  Future<void> selectSight(Sight s) { ... }
  Future<void> selectAmmo(Ammo a) { ... }
}
```

Прибрано: `_resolve()`, `_saveCartridgeToGlobalState()`, backward-compat migration.

---

## Implementation Steps

### |Done| Step 1 — Fix ObjectBox initialization
- `packages/ebalistyka_db/lib/ebalistyka_db.dart`: повернути `Store`, прийняти `directory`
- `lib/main.dart`:
  ```dart
  final store = await initObjectBox();
  runApp(ProviderScope(
    overrides: [storeProvider.overrideWithValue(store)],
    child: App(),
  ));
  ```

### |Done| Step 2 — Entity changes + codegen
- Додати `ShootingConditions` entity та `sortOrder` до `Profile`
- `dart run build_runner build --delete-conflicting-outputs`

### |Done| Step 3 — `storeProvider` + `ownerProvider`
- `lib/core/providers/store_provider.dart`
- `ownerProvider`: шукає `Owner` з `token="local"`, створює якщо немає
- Seed: якщо Owner не має profiles → seed в одній транзакції

### |WIP| Step 4 — Create extension files
- |Done| `lib/core/extensions/weapon_extensions.dart`
- |Done| `lib/core/extensions/ammo_extensions.dart`
- |Done| `lib/core/extensions/sight_extensions.dart`
- |Done| `lib/core/extensions/conditions_extensions.dart`
- |Done| `lib/core/extensions/settings_extensions.dart`
- |Done| `lib/core/extensions/convertors_extensions.dart`
- |Done| `lib/core/extensions/profile_extensions.dart`
- |Late| Do we need to add https://pub.dev/packages/json_serializable, https://pub.dev/packages/json_annotation to entities.dart?

### |Done| - before 5, 6, 7 - Think
- Do we need separate Providers/Notifiers for different settings sections? Я думаю треба центральний провайде і прості селектори, враховуючи що кілька секцій може бути використано одним віджетом - треба один сорс оф тру
- ConvertorsNotifier - може бути окремим, не зав'язаний нікуди окрім convertors_screen.
- Провайдер для User/Profile/Rifle/Ammo/Sight - має бути один сорс оф тру, окрім треба написати логіку: коли коли Rifle/Ammo/Sight relative to Profile - отримує внутрішню зміну, Profile або профайл нотіфєр має про це дізнатись. Коли ж profile є активним - то юзермає дізнатись про всі зміни в профайлі або у relative сутностях профіля. Можливо схема зі єдиним агрегатором для StreamProvider та селекторами, або якесь інше рішення.

### |Done| Step 5 — Rewrite `AppStateNotifier`
- `build()`: читає всі Box<T> з ObjectBox
- CRUD через `store.runInTransaction()`
- `saveSettings()` → `GeneralSettings` + `UnitSettings` в ObjectBox
- `saveConditions()` → `ShootingConditions` в ObjectBox

### |Done| Step 6 — Simplify `ShotProfileNotifier`
- Прибрати `_resolve()`, backward-compat migration (backward compat - взагалі не потрібен)
- Делегувати writes до `AppStateNotifier`

### |Done| Step 7 — Update `SettingsNotifier` / `ConvertorsNotifier`
- Читають з `appStateProvider`, пишуть через `appStateProvider.notifier`

### |WIP| Step 8 — Delete old code
Files to delete:
- `lib/core/storage/json_file_storage.dart`
- `lib/core/storage/app_storage.dart`
- `lib/core/providers/storage_provider.dart`
- `lib/core/models/weapon_data.dart`
- `lib/core/models/ammo_data.dart`
- `lib/core/models/sight_data.dart`
- `lib/core/models/profile_data.dart`
- |Done| `lib/core/models/app_settings.dart`
- |DONE| `lib/core/models/convertors_state.dart`
- `lib/core/models/conditions_data.dart`

### |WIP| Step 8.1 — Update old code
- `lib/core/collection/collection_parser.dart`
- `lib/core/providers/builtin_collection_provider.dart`
- `lib/core/a7p/a7p_parser.dart`
- `lib/core/collection/collection_parser.dart`

### |Done| Step 9 — Update all consumers
- `WeaponData` → `Weapon`, `AmmoData` → `Ammo`, `SightData` → `Sight`
- `profile.rifle` → `profile.weapon.target`
- `profile.cartridge` → `profile.ammo.target`
- `AppSettings` → `GeneralSettings` (з extension)
- `Conditions` → `ShootingConditions` (з extension)

---

## Critical Files

| Файл | Дія |
|---|---|
| `packages/ebalistyka_db/lib/src/entities.dart` | modify — нові entities + fields |
| `packages/ebalistyka_db/lib/ebalistyka_db.dart` | modify — fix store init |
| `lib/main.dart` | modify — ObjectBox init before runApp |
| `lib/core/providers/app_state_provider.dart` | rewrite — ObjectBox замість JsonFileStorage |
| `lib/core/providers/shot_profile_provider.dart` | simplify — прибрати _resolve |
| `lib/core/providers/shot_conditions_provider.dart` | modify — читати ShootingConditions |
| `lib/core/providers/settings_provider.dart` | modify — читати GeneralSettings/UnitSettings |
| `lib/core/providers/recalc_coordinator.dart` | modify — оновити watched providers |
| `lib/core/providers/store_provider.dart` | create |
| `lib/core/extensions/*.dart` | create (6 files) |

---

## Verification

1. `flutter build linux` — no compile errors
2. Cold start → seed дані в ObjectBox
3. Create/edit/delete ammo → зміни в UI
4. Delete ammo → пов'язані profiles видаляються атомарно
5. Switch active profile → `GeneralSettings.activeProfile` оновлено в ObjectBox
6. Restart app → active profile, settings, conditions відновлені з ObjectBox
7. Conditions між сесіями зберігаються (ShootingConditions entity)
