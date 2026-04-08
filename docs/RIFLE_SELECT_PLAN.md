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

### ProfilesViewModel

Watchає `appStateProvider` реактивно. `_buildCardData` джойнить weapon/ammo/sight
по `targetId` з `appState.weapons/cartridges/sights` (не lazy ToOne).

---

## Data Ownership

| Дані | Belongs to | Редагується де |
|---|---|---|
| name | Profile | ProfilesScreen (при створенні / rename) |
| weapon (ToOne) | Profile | WeaponWizardScreen (з ProfilesScreen) |
| ammo (ToOne) | Profile | MyAmmoScreen |
| sight (ToOne) | Profile | MySightsScreen |
| caliber, twist, barrelLength | Weapon | WeaponWizardScreen |
| dragType, bc, mv, zero* | Ammo | AmmoWizardScreen |
| sightHeight | Sight | SightWizardScreen |
| conditions (atmo, wind, distance) | ShootingConditions (global) | ConditionsScreen / HomeScreen |
| GeneralSettings, UnitSettings | Owner (global) | SettingsScreen |

> Термін "cartridge" і "projectile" залишаються тільки в таблицях, HTML-звітах
> та assets/json/collection.json. В коді — ammo/bullet.

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

### Flow 5: Duplicate Profile

```
FAB (or ProfileCard PopupMenu) → "Duplicate"
  └─ Введення нової назви
      └─ Копія Profile з новим id
         weapon → копіюється (новий Weapon entity з тими самими полями)
         ammo   → та сама ToOne reference
         sight  → та сама ToOne reference
```

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

Приймає `Ammo?` + тип (cartridge / bullet). MV — **завжди required**.

Секції: Ballistics · Muzzle Velocity · Zero Conditions

### SightWizardScreen

Приймає `Sight?`. Повертає `Sight`.

---

## ProfileCard Layout

```
┌──────────────────────────────────────┐
│  [_ProfileControlTile]               │  ← sight FAB (top-left) + ammo FAB (bottom-right)
│  sight btn ↖          ammo btn ↘    │    іконки відображають loaded/unloaded стан
├──────────────────────────────────────┤
│  ── Weapon ──────────  [edit ›]      │
│  Caliber     .338"                   │
│  Twist       1:10"  right            │
├──────────────────────────────────────┤
│  ── Ammo ───────────  [edit ›]       │
│  .338LM UKROP 250GR SMK              │
│  G7 · BC 0.314 · 888 m/s            │
├──────────────────────────────────────┤
│  ── Sight ──────────  [edit ›]       │
│  Generic Long-Range Scope            │
├──────────────────────────────────────┤
│         [ Select / Go to calc ]      │
└──────────────────────────────────────┘
```

Per-card actions (Duplicate / Export / Remove) — у `PopupMenuButton` в заголовку.

---

## ProfilesScreen UI

- **FAB** (одна кнопка `+`) → bottom sheet з Add flow
- **Per-card actions** → `PopupMenuButton` (⋮) на картці: Duplicate, Export, Remove
- **PageView** з `PageDotsIndicator`
- Активний профіль — перша сторінка (`_sortProfiles`)

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
├── MySightsScreen           (/home/profiles/sight-select)
│   ├── SightWizardScreen      (.../sight-create)
│   └── SightCollectionScreen  (.../sight-collection)
│         └── SightWizardScreen (.../sight-wizard)
└── SightWizardScreen        (/home/profiles/sight-edit)
```

---

## IncompleteBanner / Validation

1. **Wizard validation** — підсвітка обов'язкових і некоректних полів прямо у wizard screens.
2. **ProfileCard indicator** — якщо ammo або sight не вибрані → індикатор в заголовку картки.
3. **Home / Conditions / Tables banner** — `IncompleteBanner` якщо `!profile.isReadyForCalculation`.

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
| `lib/core/extensions/ammo_extensions.dart` | ✅ | DragType enum, typed getters |
| `lib/core/extensions/sight_extensions.dart` | ✅ | |
| `lib/core/extensions/profile_extensions.dart` | ✅ | isReadyForCalculation, toShot |
| `lib/core/extensions/conditions_extensions.dart` | ✅ | typed getters/setters |
| `lib/core/extensions/settings_extensions.dart` | ✅ | enum getters (ThemeMode, Unit) |
| `lib/core/a7p/a7p_parser.dart` | ✅ | proto → OB entities |
| `lib/core/collection/collection_parser.dart` | ✅ | JSON → OB entities |
| `lib/features/home/profiles_vm.dart` | ✅ | watches appStateProvider |
| `lib/features/home/sub_screens/profiles_screen.dart` | 🔧 | |
| `lib/features/home/sub_screens/profiles/widgets/profile_card.dart` | 🔧 | _ProfileControlTile interactive buttons |
| `lib/features/home/sub_screens/weapon_wizard_screen.dart` | ✅ | |
| `lib/router.dart` | ✅ | Routes константи |
| `assets/json/collection.json` | ✅ | Вбудована колекція |

---

## TODO

- [ ] `_ProfileControlTile` — interactive ammo/sight buttons (loaded/unloaded state)
- [ ] FAB logic — TBD (expandable або simple + → bottom sheet)
- [ ] `ProfileAddScreen` — реалізувати (зараз stub)
- [ ] `MyAmmoScreen` — реалізувати
- [ ] `MySightsScreen` — реалізувати
- [ ] Duplicate profile — реалізувати (weapon копіюється, ammo/sight — ті самі refs)
- [ ] Export / Import profile — формат TBD
- [ ] Wizard validation — підсвітка обов'язкових полів
- [ ] `IncompleteBanner` на Home / Conditions / Tables
