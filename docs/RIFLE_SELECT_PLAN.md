# Profiles & Selection Architecture

---

## Storage Architecture

### ObjectBox (поточний стан)

```
~/.eBalistyka/objectbox/
  Owner              ← singleton root (token="local")
  ├── Weapon[]
  ├── Ammo[]
  ├── Sight[]
  ├── Profile[]
  │     ├── ToOne<Weapon>   ← завжди required (profile без weapon не існує)
  │     ├── ToOne<Sight>
  │     └── ToOne<Ammo>
  ├── GeneralSettings
  ├── UnitSettings
  ├── TablesSettings
  ├── ConvertorsState
  └── ShootingConditions   ← global session state (не per-profile)

assets/json/collection.json  ← вбудована колекція (залишається JSON)
```

> Weapon є вбудованою структурою профілю логічно, але ObjectBox не підтримує
> embedded objects → one-to-one relation.

---

## Provider Architecture

### Single Source of Truth — `appStateProvider`

```
ObjectBox streams (Weapon/Ammo/Sight/Profile/Owner boxes)
    │  будь-який write → автоматичний reload
    ▼
AppStateNotifier  (AsyncNotifier<AppState>)
    │  _load() → AppState { weapons, cartridges, sights, profiles, activeProfile }
    ▼
┌─────────────────────────────────────────────────────┐
│  cartridgesProvider   — List<Ammo>                  │
│  sightsProvider       — List<Sight>                 │
│  weaponsProvider      — List<Weapon>                │
│  activeProfileProvider — Profile?                   │
└─────────────────────────────────────────────────────┘
```

### ShotContext — контекст для розрахунку

```
appStateProvider  ──┐
                    ├──► ShotContextNotifier  (AsyncNotifier<ShotContext?>)
shotConditionsProvider ─┘   { profile, conditions }
         │
         ▼
RecalcCoordinator  ← listen(shotContextProvider, settingsProvider, unitSettings)
    │  _triggerAll()
    ▼
homeVmProvider / shotDetailsVmProvider / trajectoryTablesVmProvider
```

### Reactive Settings & Conditions

Всі провайдери налаштувань і умов мають ObjectBox stream в `build()`:

```
SettingsNotifier         — watch GeneralSettings box
UnitSettingsNotifier     — watch UnitSettings box
TablesSettingsNotifier   — watch TablesSettings box
ShotConditionsNotifier   — watch ShootingConditions box
```

`save*` методи — тільки DB write. Stream сам оновлює стан.

### Profiles Provider Architecture

Три окремих провайдери з чіткими відповідальностями:

```
appStateProvider
    │
    ├──► profilesPagingProvider   Provider<ProfilesPagingState>
    │         Тільки структурні дані: orderedIds + activeId.
    │         Активний профіль іде першим у списку.
    │         Рівність через ==: не нотіфікує якщо структура не змінилась.
    │         → ProfilesScreen.ref.listen (пейджинг: add/delete/active change)
    │
    ├──► profileCardProvider(id)  Provider.autoDispose.family<ProfileCardData?, String>
    │         Дані одного профілю: джойнить weapon/ammo/sight по targetId.
    │         ProfileCardData.== спрощено до 7 полів: id, name, weaponFingerprint, ammoId, ammoFingerprint, sightId, sightFingerprint.
    │         → ProfileCard.ref.watch — ребілдиться тільки якщо цей профіль змінився.
    │
    └──► profilesActionsProvider  Notifier<void>
              Тільки actions: selectProfile, removeProfile, createProfile, renameProfile.
              Не тримає стан — делегує до appStateProvider.notifier.
```

**Ключова властивість:** синхронний `Provider<T>` не має intermediate states (AsyncLoading/AsyncRefreshing).
`ref.listen` на `profilesPagingProvider` спрацьовує тільки якщо `ProfilesPagingState.==` повертає `false`.
Зміна ammo/sight/weapon content → `appStateProvider` оновлюється → `profileCardProvider` оновлюється →
але `profilesPagingProvider` повертає той самий `ProfilesPagingState` → пейджинг не змінюється.

`ProfileCardData` використовує три fingerprint-и замість перевірки кожного поля:

| Fingerprint | Що хешує |
|---|---|
| `weaponFingerprint` | всі поля `Weapon` (name, caliberInch, caliberName, twistInch, barrelLengthInch, zeroElevationRad, vendor) |
| `ammoFingerprint` | всі поля `Ammo` — display (name, caliber, weight, length, projectileName, vendor) + calc (mv, mvTemp, powderSens, всі zero*, bc, dragType тощо) |
| `sightFingerprint` | всі поля `Sight` (name, focalPlane, height, offset, clicks, clickUnits, magnification, vendor) |

`==` спрощено до 7 полів: `id`, `name`, `weaponFingerprint`, `ammoId`, `ammoFingerprint`, `sightId`, `sightFingerprint`.
Будь-яка зміна будь-якого entity автоматично тригерить rebuild картки — без ризику пропустити поле.

---

## Data Ownership

| Дані | Belongs to | Редагується де |
|---|---|---|
| name | Profile | ProfilesScreen (при створенні / rename) |
| weapon (ToOne) | Profile | WeaponWizardScreen (з ProfilesScreen) |
| ammo (ToOne) | Profile | MyAmmoScreen |
| sight (ToOne) | Profile | MySightsScreen |
| caliber, twist, barrelLength | Weapon | WeaponWizardScreen |
| dragType, bc, mv, mvTemperatureC, zero*, usePowderSensitivity, powderSensitivityFrac | Ammo | AmmoWizardScreen |
| sightHeight | Sight | SightWizardScreen |
| conditions (atmo, wind, distance, powderTemperatureC, usePowderSensitivity) | ShootingConditions (global) | ConditionsScreen / HomeScreen |
| GeneralSettings, UnitSettings | Owner (global) | SettingsScreen |

> Термін "cartridge" і "projectile" залишаються тільки в таблицях, HTML-звітах
> та assets/json/collection.json. В коді — ammo/bullet.

### Ammo — поля та їх семантика

| Поле | Тип | Семантика |
|---|---|---|
| `muzzleVelocityMps` | `double?` | MV виміряний / наданий виробником |
| `muzzleVelocityTemperatureC` | `double` | T₀ — температура пороху при вимірюванні MV (еталон для корекції). **Завжди** передається як `ammo.powderTemp` у bclibc |
| `usePowderSensitivity` | `bool` | Вмикає порохову температурну корекцію |
| `powderSensitivityFrac` | `double` | Коефіцієнт чутливості (fraction / 15°C) |
| `zeroPowderTemperatureC` | `double` | Температура пороху при пристрілці (якщо `zeroUseDiffPowderTemperature`) |
| `zeroUseDiffPowderTemperature` | `bool` | Відрізняється температура пороху при пристрілці від атмосферної |

> `Ammo.powderTemperatureC` і `Ammo.usePowderTempForMv` **видалені**. Поточна поточна
> температура пороху (T₁) знаходиться виключно в `ShootingConditions.powderTemperatureC`.
> `bclibc.Ammo.powderTemp` = T₀ (muzzleVelocityTemperatureC) завжди;
> `bclibc.Atmo.powderTemp` = T₁ (з conditions або zero) — поточна.

---

## Seed Data (перший старт)

### AppStateNotifier._seed()
Створює: 1 Sight, 1 Weapon (.338LM), 3 Ammo (.338LM), 3 Profile (один на кожен Ammo).

### ShotConditionsNotifier._loadOrCreate()
```dart
ShootingConditions()
  ..distanceMeter = 100.0      // entity default
  ..temperatureC = 15.0        // entity default
  ..pressurehPa = 1013.25      // entity default
  ..humidityFrac = 0.5         // overridden
  ..windSpeedMps = 0.0         // entity default
  ..windDirectionDeg = 0.0     // entity default
```

### SettingsNotifier._loadOrCreate()
```dart
GeneralSettings()
  ..homeShowMil = true          // overridden (решта false)
  ..homeChartDistanceStep = 10  // entity default
  ..homeTableDistanceStep = 10  // entity default
  ..themeMode = 'system'        // entity default
```

### TablesSettingsNotifier._loadOrCreate()
```dart
TablesSettings()
  ..distanceEndMeter = 1000.0   // overridden (entity: 2000)
  ..showMil = true              // overridden (entity: false)
  ..distanceStepMeter = 100.0   // entity default
  ..showZeros = true            // entity default
```

> `make run-clean` перестворює DB з новими дефолтами.

---

## isReadyForCalculation

```dart
extension ProfileExtension on Profile {
  bool get isReadyForCalculation {
    final ammo = this.ammo.target;
    return ammo != null && ammo.isReadyForCalculation;
  }
}
```

Якщо `false` → Home / Conditions / Tables показують `IncompleteBanner`.

---

## Built-in Collection

Файл: `assets/json/collection.json`

```json
{
  "calibers": [...],
  "weapon": [...],
  "cartridges": [...],
  "projectiles": [...],
  "sights": [...]
}
```

При виборі з вбудованої колекції → entity **копіюється** у ObjectBox юзера,
прив'язується до Profile. Ніколи не зберігається як `builtin` reference.

---

## Flow Branches

### Flow 1: Новий профіль

```
ProfilesScreen
  └─ FAB → "Add"
      └─ Bottom sheet: Create new / From collection / Import from file
          └─ Введення назви профілю + вибір weapon:
              ├─ "From Collection" → WeaponCollectionScreen
              │     └─ Select → WeaponWizardScreen (pre-filled, caliber readonly)
              └─ "Create manually" → WeaponWizardScreen (порожній)
                    └─ Save → appStateProvider.saveWeapon + saveProfile
```

Profile завжди створюється з weapon. Profile без weapon не існує.
Після створення — ammo і sight не вибрані.

### Flow 2: Вибір / зміна Ammo

```
ProfileCard (_ProfileControlTile ammo button)
  └─ MyAmmoScreen
      ├─ My Ammo list → Select → appStateProvider.saveProfile
      ├─ "Create Ammo"              → AmmoWizardScreen
      ├─ "From Collection (cartridge)" → AmmoCollectionScreen (filter: cartridge)
      │       └─ AmmoWizardScreen (pre-filled) → copy to ObjectBox
      └─ "From Collection (bullet)"    → AmmoCollectionScreen (filter: bullet)
              └─ AmmoWizardScreen (pre-filled) → copy to ObjectBox
```

### Flow 3: Вибір / зміна Sight

```
ProfileCard (_ProfileControlTile sight button)
  └─ MySightsScreen
      ├─ My Sights list → Select → appStateProvider.saveProfile
      ├─ "Create Sight" → SightWizardScreen
      └─ "From Collection" → SightCollectionScreen
```

### Flow 4: Edit Weapon

```
ProfileCard
  └─ "Weapon" section tap (ListSectionTile)
      └─ WeaponWizardScreen (pre-filled, caliber readonly)
          └─ Save → appStateProvider.saveWeapon
                  → stream auto-triggers ProfilesViewModel rebuild
```

✅ Реалізовано. `appStateProvider.saveWeapon` → OB stream → `appStateProvider` reload →
`profileCardProvider(id)` оновлюється (content) → `profilesPagingProvider` не змінюється (paging).

### Flow 5: Edit Ammo properties

```
ProfileCard
  └─ "Ammo" section tap → onEditAmmo callback → _ProfilesScreenState._onEditAmmo
      └─ reads Ammo + weapon.caliberInch від профілю
          └─ AmmoWizardScreen(initial: ammo, caliberInch: weapon.caliberInch)  ← /home/profiles/ammo-edit
              │  extra: (Ammo?, double?) — record передається через router
              │  якщо ammo.caliberInch != weapon.caliberInch → SnackBar з кнопкою "Update"
              └─ context.pop(Ammo) → appStateProvider.saveAmmo
```

✅ Роутинг і callbacks реалізовані. AmmoWizardScreen повністю реалізований.

### Flow 6: Edit Sight properties

```
ProfileCard
  └─ "Sight" section tap → onEditSight callback → _ProfilesScreenState._onEditSight
      └─ reads Sight entity from appState
          └─ SightWizardScreen(initial: sight)  ← /home/profiles/sight-edit
              └─ context.pop(Sight) → appStateProvider.saveSight
```

✅ Роутинг і callbacks реалізовані, SightWizardScreen — повністю реалізований.

### Flow 7: Duplicate Profile

```
ProfileCard PopupMenu → "Duplicate"
  └─ Введення нової назви
      └─ Копія Profile з новим id
         weapon → копіюється (новий Weapon entity з тими самими полями)
         ammo   → та сама ToOne reference
         sight  → та сама ToOne reference
```

✅ Реалізовано.

---

## Wizard Screens

### WeaponWizardScreen

Приймає `Weapon?` (null = новий). Повертає `Weapon` через `context.pop(weapon)`.

| Поле | Create | From Collection | Edit |
|---|---|---|---|
| name | редагується | редагується | редагується |
| caliber | редагується | **readonly** | **readonly** |
| twist | редагується | редагується | редагується |
| twistDirection | редагується | редагується | редагується |
| barrelLength | optional | optional | optional |

### AmmoWizardScreen

Приймає `Ammo? initial` (null = новий). Повертає `Ammo?` через `context.pop(ammo)`.

Використовується в трьох контекстах:
- `ammo-select/create` — створення нового (initial = null)
- `ammo-select/cartridge-collection` або `bullet-collection` → AmmoWizardScreen (pre-filled, тип readonly)
- `ammo-edit` — редагування існуючого (initial = Ammo з appState)

**Поточний стан:**
- ✅ Name — з touched-validation
- ✅ Projectile name — nullable, без валідації
- ✅ Projectile — Caliber (readonly info), Weight, Length (`UnitValueFieldTile`)
- ✅ DragModel — `SegmentedButton<DragType>` (G1/G7/CUSTOM) + `_buildBcSection`: Multi-BC switch, Single BC field, placeholder ListTile для редактора Multi-BC таблиці / Custom drag table
- ✅ Cartridge — Muzzle Velocity, Muzzle Velocity Temperature (T₀), `usePowderSensitivity` switch
- ✅ Zero Conditions — Distance, Look Angle, Temperature, Pressure, Humidity, Altitude
- ✅ Powder Sensitivity — `PowderSensSection(showToggle: false)` (розгортається після switch у Cartridge): diff temp switch, powder temp field, sensitivity input, calculated MV info. Scroll-to-section при вмиканні.
- ✅ Coriolis — `CoriolisSection`: switch + latitude + azimuth. Scroll-to-section при вмиканні.
- ✅ Caliber mismatch detection — при edit передається `caliberInch` з weapon профілю через record `(Ammo?, double?)`; якщо розходження → SnackBar "Ammo caliber differs from weapon caliber" з кнопкою "Update"
- ❌ Routes до multi-bc editor і custom drag table editor — `debugPrint` placeholder

### SightWizardScreen

Приймає `Sight? initial` (null = новий). Повертає `Sight?` через `context.pop(sight)`.

Використовується в трьох контекстах:
- `sight-select/create` — створення нового (initial = null)
- `sight-select/collection` → SightWizardScreen (pre-filled)
- `sight-edit` — редагування існуючого (initial = Sight з appState)

---

## ProfileCard Layout

```
┌──────────────────────────────────────┐
│  [_ProfileControlTile]               │  ← sight FAB (top-left) + ammo FAB (bottom-right)
│  sight btn ↖          ammo btn ↘    │    кнопки завжди є; hint "Select X" якщо не вибрано
├──────────────────────────────────────┤
│  ── Weapon ──────────  [edit ›]      │
│  Caliber     .338"                   │
│  Twist       1:10"  right            │
├──────────────────────────────────────┤
│  ── Ammo ───────────  [edit ›]       │  ← секція видима тільки якщо ammoId != null
│  .338LM UKROP 250GR SMK              │    [edit ›] → AmmoEditScreen(ammoId)
│  G7 · BC 0.314 · 888 m/s            │
├──────────────────────────────────────┤
│  ── Sight ──────────  [edit ›]       │  ← секція видима тільки якщо sightId != null
│  Generic Long-Range Scope            │    [edit ›] → SightWizardScreen(sightId)
│  Height · FFP · 4-16x               │
│  V-click: 0.1 MIL  H-click: 0.1 MIL │
├──────────────────────────────────────┤
│  [ Select / Go to calc ]             │  ← кнопка якщо ammoId != null && sightId != null
│  або banner "Select ammo and sight"  │  ← banner інакше
└──────────────────────────────────────┘
```

Per-card actions (Duplicate / Export / Rename / Remove) — у bottom action sheet через ⋮ кнопку в `_ProfileControlTile`.

---

## ProfilesScreen UI

- **FAB** (одна кнопка `+`) → bottom sheet з Add flow
- **Per-card actions** → bottom action sheet через ⋮ кнопку (`_ProfileControlTile`): Duplicate, Export, Rename, Remove
- **PageView** з `PageDotsIndicator`
- Активний профіль — перша сторінка (сортується у `profilesPagingProvider`)

**Paging rules** (`ref.listen<ProfilesPagingState>`):

| Подія | Дія |
|---|---|
| Профіль доданий (`length` збільшився) | navigate to last page (animated) |
| Профіль видалений (`length` зменшився) | stay on current page якщо він ще існує; інакше `clamp` до найближчого |
| Активний профіль змінився (`activeId` інший) | navigate to page 0 |
| Зміна content (ammo/sight/weapon edit) | нічого — `profilesPagingProvider` не нотіфікує |

`ProfileCard` — `ConsumerStatefulWidget`, watchає `profileCardProvider(profileId)` незалежно.
Кожна картка ребілдиться тільки якщо її власні дані змінились.

---

## Route Architecture

```
ProfilesScreen  (/home/profiles)
├── WeaponWizardScreen       (/home/profiles/weapon-create)
├── WeaponCollectionScreen   (/home/profiles/weapon-collection)
├── WeaponWizardScreen       (/home/profiles/weapon-edit)
├── MyAmmoScreen             (/home/profiles/ammo-select)
│   ├── AmmoWizardScreen           (.../ammo-create)
│   ├── AmmoCollectionScreen       (.../cartridge-collection)  ← filter: cartridges
│   │     └── AmmoWizardScreen     (.../ammo-wizard)
│   └── AmmoCollectionScreen       (.../bullet-collection)     ← filter: bullets
│         └── AmmoWizardScreen     (.../ammo-wizard)
├── AmmoWizardScreen         (/home/profiles/ammo-edit)
│   ├── MultiBcEditorScreen        (.../ammo-edit/multi-bc-g1)   ← TODO: G1 multi-BC table
│   ├── MultiBcEditorScreen        (.../ammo-edit/multi-bc-g7)   ← TODO: G7 multi-BC table
│   ├── CustomDragTableScreen      (.../ammo-edit/drag-table)    ← TODO: custom drag model
│   └── PowderSensitivityScreen    (.../ammo-edit/powder-sensitivity) ← TODO: temperature sensitivity table → auto-calc powderSensitivityFrac
├── MySightsScreen           (/home/profiles/sight-select)
│   ├── SightWizardScreen      (.../sight-create)
│   └── SightCollectionScreen  (.../sight-collection)
│         └── SightWizardScreen (.../sight-wizard)
└── SightWizardScreen        (/home/profiles/sight-edit)
```

---

## IncompleteBanner / Validation

1. **Wizard validation** — підсвітка обов'язкових полів у wizard screens. `touched` флаг: помилка тільки після першої спроби Save, потім — реактивна. ✅ Реалізовано для WeaponWizardScreen і `showTextInputDialog`.
2. **ProfileCard bottom** — `ColoredBox(errorContainer)` з текстом якщо `ammoId == null || sightId == null`, інакше FilledButton. ✅ Реалізовано.
3. **Home / Tables** — `HomeUiNoData(message)` / `TrajectoryTablesUiEmpty(message)` замість спінера. ✅ Реалізовано через `EmptyStatePlaceholder`.
4. **Confirm dialog** — `showConfirmDialog` (`lib/shared/widgets/confirm_dialog.dart`). `isDestructive: true` → error colors, `false` → tertiary colors. ✅ Використовується у Remove profile / ammo / sight.

---

## Export / Import

Формат TBD (json або кастомний). Буде реалізовано пізніше.

---

## Critical Files

| Файл | Стан | Опис |
|---|---|---|
| `packages/ebalistyka_db/lib/src/entities.dart` | ✅ | ObjectBox entities |
| `lib/core/providers/app_state_provider.dart` | ✅ | Single source of truth, OB streams |
| `lib/core/providers/shot_context_provider.dart` | ✅ | ShotContext (profile + conditions) |
| `lib/core/providers/recalc_coordinator.dart` | ✅ | Централізований trigger розрахунків |
| `lib/core/providers/shot_conditions_provider.dart` | ✅ | OB stream, seed defaults |
| `lib/core/providers/settings_provider.dart` | ✅ | OB streams, seed defaults |
| `lib/core/providers/db_provider.dart` | ✅ | storeProvider + ownerProvider |
| `lib/core/extensions/weapon_extensions.dart` | ✅ | |
| `lib/core/extensions/ammo_extensions.dart` | ✅ | DragType enum, typed getters; `toZeroAmmo()`/`toCurrentAmmo()` завжди передають `mvTemperature` як T₀ |
| `lib/core/extensions/sight_extensions.dart` | ✅ | |
| `lib/core/extensions/profile_extensions.dart` | ✅ | isReadyForCalculation, toShot |
| `lib/core/extensions/conditions_extensions.dart` | ✅ | typed getters/setters |
| `lib/core/extensions/settings_extensions.dart` | ✅ | enum getters (ThemeMode, Unit) |
| `lib/core/a7p/a7p_parser.dart` | ✅ | proto → OB entities |
| `lib/core/collection/collection_parser.dart` | ✅ | JSON → OB entities |
| `lib/features/home/profiles_vm.dart` | ✅ | `profilesPagingProvider` (sync Provider), `profileCardProvider` (family), `profilesActionsProvider` (Notifier<void>); `ProfileCardData.==` — 7 полів: id + name + `weaponFingerprint` + ammoId + `ammoFingerprint` + sightId + `sightFingerprint`; кожен fingerprint хешує всі поля відповідного entity |
| `lib/features/home/sub_screens/my_profiles_screen.dart` | ✅ | ProfilesScreen: PageView, paging listener, FAB, per-profile callbacks |
| `lib/features/home/sub_screens/profiles/widgets/profile_card.dart` | ✅ | ConsumerStatefulWidget; watchає profileCardProvider(id); _ProfileControlTile з ammo/sight FABs + hints |
| `lib/features/home/sub_screens/my_ammo_screen.dart` | ✅ | Вибір ammo для профілю |
| `lib/features/home/sub_screens/my_sights_screen.dart` | ✅ | Вибір sight для профілю |
| `lib/shared/widgets/text_input_dialog.dart` | ✅ | touched-validation |
| `lib/shared/widgets/confirm_dialog.dart` | ✅ | reusable confirm: isDestructive (error) / tertiary colors |
| `lib/features/home/sub_screens/weapon_wizard_screen.dart` | ✅ | |
| `lib/features/home/sub_screens/ammo_wizard_screen.dart` | 🔧 | Name + ProjectileName (nullable) + Projectile + DragModel + Cartridge (MV, mvTemp, powderSens switch) + Zero Conditions + PowderSensSection + CoriolisSection. Caliber mismatch SnackBar з "Update". Відсутнє: multi-bc/drag-table editor routes |
| `lib/shared/widgets/snackbars.dart` | ✅ | `showNotAvailableSnackBar(context, feature)` — реюзабл тост для незавершених функцій |
| `lib/shared/widgets/powder_sens_section.dart` | ✅ | Reusable powder sensitivity section. `showToggle:false` (wizard) — switch зовні, контент завжди показується; `showToggle:true` default (conditions) — switch вбудований. `powderSensRaw!=null` → input; `powderSensRaw==null` → info tile |
| `lib/shared/widgets/coriolis_section.dart` | ✅ | Reusable coriolis section: switch + latitude + azimuth |
| `lib/features/home/sub_screens/sight_wizard_screen.dart` | ✅ | Sight form: Name/Optics/Mounting/Clicks/Magnification |
| `lib/router.dart` | ✅ | Routes константи |
| `assets/json/collection.json` | ✅ | Вбудована колекція |

---

## TODO

- [~] `AmmoWizardScreen` — майже готовий. Залишилось: routes до multi-bc/drag-table editor
- [x] `SightWizardScreen` — реалізовано
- [ ] `AmmoCollectionScreen` — реалізувати (filter: cartridge / bullet)
- [ ] `WeaponCollectionScreen` — реалізувати
- [ ] `SightCollectionScreen` — реалізувати
- [x] Duplicate profile — реалізовано
- [x] Duplicate ammo — реалізовано
- [x] Duplicate sight — реалізовано
- [x] Remove ammo / sight — реалізовано з confirm dialog
- [x] Caliber mismatch detection в AmmoWizardScreen (edit mode) — SnackBar з "Update"
- [ ] Export / Import profile / ammo / sight — формат TBD (наразі `showNotAvailableSnackBar`)

---

## Alpha Release TODO

### 🔴 Блокери (без цього альфа не функціональна)

- [~] `AmmoWizardScreen` — майже готовий. Залишилось: routes до multi-bc/drag-table editor
  - ⚠️ **`Weapon.caliberName`:** поле є в entity та копіюється при duplicate, але ніде не відображається і не задається в UI (тільки `caliberInch` використовується в розрахунках). При реалізації WeaponWizardScreen вирішити: відображати як human-readable label (readonly, з колекції) або прибрати з UI зовсім.
  - ⚠️ **Powder sensitivity — потенційна зміна логіки:** поточний стан — on/off (`powderSensitivityFrac`). Планується 3 режими:
    - `off` — без температурної корекції
    - `coeff` — задається `powderSensitivityFrac` вручну
    - `table` — задається таблицею (`powderSensitivityTC` + `powderSensitivityVMps`); таблиця для розрахунку і автоматичного оновлення `powderSensitivityFrac` (в окремому підекрані wizard), після чого engine працює через `frac` → **зміни до entities не потрібні**
  - ✅ **Caliber mismatch detection:** при edit передається `caliberInch` з weapon профілю через record `(Ammo?, double?)`; розходження → SnackBar з кнопкою "Update" для автоматичного виправлення
  - ✅ **T₀/T₁ логіка:** `Ammo.powderTemperatureC` і `Ammo.usePowderTempForMv` видалені. `bclibc.Ammo.powderTemp` = T₀ = `muzzleVelocityTemperatureC` (завжди). T₁ — виключно у `ShootingConditions` або `zeroConditions`.
- [ ] `AmmoCollectionScreen` — реалізувати (filter: cartridge / bullet)
- [ ] `WeaponCollectionScreen` — реалізувати
- [ ] `SightCollectionScreen` — реалізувати

### 🟠 Важливо для альфи

- [ ] `DistanceConvertorScreen` — реалізувати (stub)
- [ ] `VelocityConvertorScreen` — реалізувати (stub)
- [ ] Table export — підключити кнопку (HTML exporter `table_html_exporter.dart` вже є)
- [ ] Zero Conditions UI — окремий екран редагування `zeroConditions` (відмінних від поточних `conditions`)
- [ ] Settings → About links — GitHub посилання як мінімум

---

## Post-Alpha TODO

- [ ] A7P import UI — `file_picker` → `a7p_parser.dart` → завантажити в профіль
- [ ] A7P export UI — серіалізація → `share_plus`
- [ ] Profile / ammo / sight Export/Import — формат TBD
- [ ] Localization uk/en — ARB + `flutter_localizations`
- [ ] RulerSelector widget — touch-drag ruler для QuickActionsPanel
- [ ] Reticle fullscreen screen — відкривається з Home Page 1
- [ ] Help overlay — coach marks
- [ ] Tools screen — відкривається з кнопки More на Home (наразі `showNotAvailableSnackBar`)
- [ ] Settings → Privacy Policy / Terms of Use / Changelog links
