# Profiles & Selection Architecture

> Об'єднаний документ (замінює `RIFLE_SELECT_PLAN.md` і `plan_profile_select_architecture.md`)

---

## Поточний стан

### Реалізовано (Phase 1–4)
- Phase 1 ✅ — Powder sensitivity: `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`, `useDiffPowderTemp` у `ShotProfile`
- Phase 2 ✅ — Data ownership: межі відповідальності між ballistic / runtime / global даними
- Phase 3 ✅ — Profile Library Provider + Storage refactor: `profiles.json` як `{activeProfileId, profiles:[...]}`, `moveToFirst`, backward-compat
- Phase 4 ✅ — Profiles Screen: `ProfilesVm`, `ProfilesScreen`, `ProfileCardData`, `profile_card.dart`
- `rifle_wizard_screen.dart` ✅ — повністю реалізований
- `home_sub_screens.dart` 🔲 — всі під-екрани як заглушки (`StubScreen`)
- Phase 5 ✅ — Зроблено. Один тест ламається — TODO: виправити.
- Phase 6 🔲 — ObjectBox Migration (замінює JSON storage): див. `docs/OBJECTBOX_MIGRATION.md`
---

## Storage Architecture

> ⚠️ Phase 6 (ObjectBox Migration) замінює JSON storage на ObjectBox. Деталі в `docs/OBJECTBOX_MIGRATION.md`.

### Поточний стан (до Phase 6): JSON файли

```
~/.eBalistyka/
  cartridges.json    ← List<AmmoData>
  sights.json        ← List<SightData>
  profiles.json      ← {activeProfileId, profiles:[...]}
  settings.json      ← AppSettings (одиниці, теми, конвертори)
  conditions.json    ← Conditions (умови стрільби)
  collection.json    ← вбудована колекція (кеш або assets fallback)
```

### Цільовий стан (після Phase 6): ObjectBox

```
~/.eBalistyka/objectbox/  ← ObjectBox database (ebalistyka_db)
  Owner              ← singleton root (token="local")
  ├── Weapon[]       ← гвинтівки (замість WeaponData JSON)
  ├── Ammo[]         ← патрони/кулі (замість AmmoData JSON)
  ├── Sight[]        ← прицілі (замість SightData JSON)
  ├── Profile[]      ← профілі (замість ProfileData JSON)
  │     ├── ToOne<Weapon>
  │     ├── ToOne<Sight>
  │     └── ToOne<Ammo>
  ├── GeneralSettings    ← замість AppSettings JSON
  ├── UnitSettings
  ├── TablesSettings
  ├── ConvertorsState
  └── ShootingConditions ← замість Conditions JSON (NEW entity)

~/.eBalistyka/collection.json  ← вбудована колекція (залишається JSON)
```

---

### `data.json`

```json
{
  "activeProfileId": "some-uuid",
  "profiles": [
    {
      "id": "...",
      "name": "...",
      "rifle": { "id": "...", "name": "...", "sightHeight": 8.5, "twist": 10.0, "caliberDiameter": 0.338, ... },
      "cartridgeId": "some-uuid-or-null",
      "sightId": "some-uuid-or-null",
      "conditions": { ... },
      "winds": [...],
      "lookAngle": 0.0,
      "targetDistance": 100.0,
      "usePowderSensitivity": false,
      "useDiffPowderTemp": false
    }
  ],
  "cartridges": [
    {
      "id": "...",
      "type": "cartridge",
      "name": "...",
      "projectile": { ... },
      "mv": 888.0,
      "powderTemp": 15.0,
      "powderSensitivity": 0.02,
      "usePowderSensitivity": true,
      "zeroDistance": 100.0,
      "zeroConditions": { "temperature": 15.0, "pressure": 1000.0, "humidity": 0.47, "powderTemp": 15.0 },
      "zeroUsePowderSensitivity": true,
      "zeroUseDiffPowderTemp": false
    },
    {
      "id": "...",
      "type": "bullet",
      "name": "...",
      "projectile": { ... },
      "mv": 850.0,
      "zeroDistance": 100.0,
      "zeroConditions": { ... }
    }
  ],
  "sights": [
    {
      "id": "...",
      "name": "...",
      "sightHeight": 50.0,
      "zeroElevation": 0.0
    }
  ]
}
```

> Bullet = cartridge з `type: bullet`. MV **завжди required** у wizard (навіть для bullet з вбудованої колекції де MV = null — юзер зобов'язаний заповнити).

Backward-compat: при читанні старого формату (`profiles.json` як окремий файл або plain array) — мігруємо автоматично.

---

## Data Ownership

| Дані                                            | Належить                         | Редагується де                    |
| ----------------------------------------------- | -------------------------------- | --------------------------------- |
| name, rifle                                     | `ShotProfile`                    | Profile wizard                    |
| cartridgeId, sightId                            | `ShotProfile`                    | Profile card (вибір з бібліотеки) |
| conditions (Atmo)                               | `ShotProfile` (runtime, per-app) | Conditions screen                 |
| usePowderSensitivity, useDiffPowderTemp         | `ShotProfile` (runtime, per-app) | Conditions screen                 |
| winds, lookAngle, targetDistance                | `ShotProfile` (runtime, per-app) | Home screen                       |
| zeroDistance, zeroConditions                    | `Cartridge`                      | Cartridge wizard                  |
| zeroUsePowderSensitivity, zeroUseDiffPowderTemp | `Cartridge`                      | Cartridge wizard                  |
| Rifle (вся модель)                              | embedded у `ShotProfile`         | Rifle wizard (з profile card)     |
| Cartridge (вся модель)                          | `cartridges.json`                | Cartridge wizard                  |
| Sight (вся модель)                              | `sights.json`                    | Sight wizard                      |
| AppSettings                                     | Global                           | Settings screen                   |

---

## Profile Model

> Назви класів після рефакторингу:
> - `ShotProfile` / `ProfileData` → **`ebalistyka_db.Profile`** (ObjectBox entity) + `extension ProfileData on Profile`
> - `Rifle` / `WeaponData` → **`ebalistyka_db.Weapon`** + `extension WeaponData on Weapon`
> - `Cartridge` / `AmmoData` → **`ebalistyka_db.Ammo`** + `extension AmmoData on Ammo`
> - `Sight` / `SightData` → **`ebalistyka_db.Sight`** + `extension SightData on Sight`
> - `Conditions` / `AtmoData` → **`ebalistyka_db.ShootingConditions`** + `extension ConditionsData on ShootingConditions`

### ObjectBox Profile entity (після Phase 6)

```dart
// packages/ebalistyka_db/lib/src/entities.dart
@Entity()
class Profile {
  @Id() int id = 0;
  String name = "";
  int sortOrder = 0;

  final weapon = ToOne<Weapon>();  // завжди belongs to profile
  final sight = ToOne<Sight>();    // null = не вибрано
  final ammo = ToOne<Ammo>();      // null = не вибрано
  final owner = ToOne<Owner>();
}
```

Умови стрільби (conditions, winds, lookAngle тощо) зберігаються в **`ShootingConditions`** entity (linked до Owner, не до Profile — global session state).

### Ammo entity містить zero-related поля

```dart
@Entity()
class Ammo {
  // ... ballistics fields (caliber, weight, drag, bc, mv, powderTemp...) ...
  // Zero data:
  double zeroDistanceMeter = 100.0;
  double zeroLookAngleRad = 0.0;
  double zeroTemperatureC = 15.0;
  double zeroPressurehPa = 1013;
  double zeroHumidityFrac = 0.0;
  double zeroPowderTemperatureC = 15.0;
  bool usePowderSensitivity = false;
  bool zeroUseDiffPowderTemperature = false;
  bool zeroUseCoriolis = false;
  // ...
}
```

`DragType` (g1/g7/custom) — через `@Transient()` enum з string getter/setter.

---

## Resolve Strategy

**Тільки активний профіль резолвиться повністю.**

`shotProfileProvider` при завантаженні / зміні активного профілю:
1. Читає `ShotProfile` з `profileLibraryProvider` (має `cartridgeId`, `sightId`, але `cartridge == null`, `sight == null`)
2. Lookup в `cartridgeLibraryProvider` по `cartridgeId`
3. Lookup в `sightLibraryProvider` по `sightId`
4. Повертає `ShotProfile` з заповненими `cartridge?` і `sight?`

`profileLibraryProvider` — зберігає список профілів **без** resolve (тільки ids).

**Broken reference handling:**
- `cartridgeId` не знайдено в бібліотеці → обнуляємо `cartridgeId` в профілі → toast з помилкою "Cartridge not found, please select again"
- `sightId` не знайдено → аналогічно

---

## isReadyForCalculation

```dart
bool get isReadyForCalculation =>
  cartridge != null &&
  cartridge!.mv.raw > 0 &&
  cartridge!.projectile.coefRows.isNotEmpty &&
  cartridge!.projectile.diameter.raw > 0 &&
  cartridge!.projectile.weight.raw > 0 &&
  rifle.twist.raw != 0;
```

Sight — необов'язковий для розрахунку (sightHeight в rifle використовується як fallback = 0 якщо sight не вибрано або не має sightHeight).

Якщо `!isReadyForCalculation` → Home / Conditions / Tables показують `IncompleteBanner` з посиланням на ProfilesScreen.

---

## Вбудована vs Користувацька колекції

### Дві точки доступу

**Вбудована колекція** (`builtin: true`) — поставляється з додатком (assets або тег git). Доступна виключно через "From Collection" → `CollectionBrowserScreen`. При виборі — запис **копіюється** у бібліотеку юзера (новий UUID, `builtin: false`), і одразу прив'язується до профілю.

**Бібліотека юзера** (`builtin: false`) — все що юзер створив, імпортував, або скопіював з вбудованої колекції.

```
My Cartridges / My Sights              Built-in Collection (hidden)
─────────────────────────────          ──────────────────────────────
 [.338LM UKROP 250GR SMK]  ←copy────   🔒 .338LM UKROP 250GR SMK
 [Hornady 285 copy]        ←copy────   🔒 Hornady 285GR ELD-M
 [My custom load]                      🔒 ...

  "From Collection" btn ─────────────► CollectionBrowserScreen
```

---

## Wizard Screen — Концепція

### RifleWizardScreen

Приймає `Rifle?` (null = новий вручну). Повертає `Rifle` через `Navigator.pop(rifle)`.

| Поле            | Новий вручну           | Copy from collection   | Edit existing          |
| --------------- | ---------------------- | ---------------------- | ---------------------- |
| name            | редагується            | редагується            | редагується            |
| caliberDiameter | редагується            | **readonly**           | **readonly**           |
| sightHeight     | редагується            | редагується            | редагується            |
| twist           | редагується            | редагується            | редагується            |
| twistDirection  | редагується            | редагується            | редагується            |
| barrelLength    | редагується (optional) | редагується (optional) | редагується (optional) |

> Twist direction: позитивне значення = правий твіст, від'ємне = лівий. Це стосується як вбудованої колекції так і користувацьких записів.

### CartridgeWizardScreen

Приймає `Cartridge?` + `CartridgeType`. MV — **завжди required** (навіть для `type: bullet`). Повертає `Cartridge` через `Navigator.pop(cartridge)`.

Секції wizard:
- Ballistics (dragType, BC / multi-BC / custom table, bullet weight/diameter/length)
- Muzzle velocity (mv, powderTemp, powderSensitivity)
- Zero (zeroDistance, zeroConditions, zeroUsePowderSensitivity, zeroUseDiffPowderTemp)

**Wizard не знає контексту виклику** — просто редагує і повертає результат. Логіка збереження — у caller.

Після збереження у wizard → зберігається в ObjectBox (Ammo entity) → прив'язується до Profile через `profile.ammo.target`.

### SightWizardScreen

Аналогічно, повертає `Sight`. Після збереження → ObjectBox (Sight entity) → прив'язується до Profile через `profile.sight.target`.

---

## Flow Branches

### Flow 1: Новий профіль

```
ProfilesScreen
  └─ FAB → "Add"
      └─ Enter profile name dialog
          └─ ProfileAddScreen
              └─ Вибір rifle:
                  ├─ "From Collection" → RifleCollectionScreen
                  │     └─ Select → RifleWizardScreen (pre-filled, caliberDiameter readonly)
                  │           └─ Save → weapon linked до нового Profile
                  └─ "Create manually" → RifleWizardScreen (порожній, всі поля редагуються)
                        └─ Save → weapon linked до нового Profile
```

Профіль створюється з rifle, але **без** cartridge і sight (cartridgeId = null, sightId = null).

### Flow 2: Вибір / зміна Cartridge з ProfileCard

```
ProfileCard
  └─ "Select Cartridge" btn
      └─ CartridgeSelectScreen
          ├─ My Cartridges list
          │   ├─ Select item → прив'язати cartridgeId до профілю
          │   └─ Cog → Edit / Duplicate / Delete
          ├─ "Create Cartridge" btn → CartridgeWizardScreen (порожній, type: cartridge)
          │     └─ Save → зберегти в ObjectBox (Ammo) → прив'язати до Profile
          ├─ "Create Bullet" btn → CartridgeWizardScreen (порожній, type: bullet)
          │     └─ Save → зберегти в ObjectBox (Ammo) → прив'язати до Profile
          └─ "From Collection" btn → CartridgeCollectionScreen
                └─ Select → CartridgeWizardScreen (pre-filled)
                      └─ Save → copy до ObjectBox (Ammo) → прив'язати до Profile
```

### Flow 3: Вибір / зміна Sight з ProfileCard

```
ProfileCard
  └─ "Select Sight" btn
      └─ SightSelectScreen
          ├─ My Sights list
          │   ├─ Select item → прив'язати sightId до профілю
          │   └─ Cog → Edit / Duplicate / Delete
          ├─ "Create Sight" btn → SightWizardScreen (порожній)
          │     └─ Save → зберегти в ObjectBox (Sight) → прив'язати до Profile
          └─ "From Collection" btn → SightCollectionScreen
                └─ Select → SightWizardScreen (pre-filled)
                      └─ Save → copy до ObjectBox (Sight) → прив'язати до Profile
```

### Flow 4: Edit Rifle з ProfileCard

```
ProfileCard
  └─ "Edit Rifle" btn
      └─ RifleWizardScreen (pre-filled, caliberDiameter readonly)
          └─ Save → оновити rifle embedded у ShotProfile
```

### Flow 5: Duplicate Profile

```
ProfilesScreen
  └─ FAB → "Duplicate"
      └─ Enter new profile name dialog
          └─ Копія поточного профілю з новим UUID
             (rifle копіюється embedded, cartridgeId/sightId — ті самі references)
```

---

## Shared UI Components

### Tile поведінка

```
ItemListView (generic, reusable)
  └─ CartridgeTile  ← reusable tile для Cartridge/Bullet
  └─ SightTile      ← reusable tile для Sight
```

- Якщо `builtin: true` → **без cog btn**, є кнопка **Select**
- Якщо `builtin: false` (user data) → є **cog btn** (⚙️) для Edit / Duplicate / Delete, є кнопка **Select**
- Tap на tile → нічого (тільки кнопка Select виконує дію)

---

## Картка профілю (ProfileCard layout)

```
┌──────────────────────────────────────┐
│                                      │
│   [Placeholder / фото гвинтівки]     │  ← ~160px, назва профілю по краях
│                                      │
├──────────────────────────────────────┤
│  🔫 Cartridge   [назва патрону  ›]   │  ← tap → CartridgeSelectScreen
│  🔭 Sight       [назва прицілу  ›]   │  ← tap → SightSelectScreen
├──────────────────────────────────────┤
│  ── Rifle ─────────────────────      │
│  Caliber        .338"                │
│  Sight height   8.5 mm               │
│  Twist          1:10 inch            │
│                     [Edit Rifle ›]   │  ← → Flow 4
├──────────────────────────────────────┤
│  ── Cartridge ─────────────────      │
│  MV             888 m/s              │
│  Bullet         250 gr · .338"       │
│  Drag model     G7 · BC 0.314        │
│  Zero dist      100 m                │
│              [Edit Cartridge ›]      │  ← → CartridgeWizardScreen
├──────────────────────────────────────┤
│  ── Sight ──────────────────────     │
│  [назва або "Not selected"]          │
│                  [Edit Sight ›]      │  ← → SightWizardScreen
├──────────────────────────────────────┤
│              [  Select  ]            │  ← тільки якщо не активний
└──────────────────────────────────────┘
```

Якщо cartridge або sight не вибрано → показуємо "Not selected" + кнопку вибору.
Активний профіль: кнопка "Select" → `✓ Active` + підсвічування картки.

---

## IncompleteBanner

Показується на Home / Conditions / Tables якщо `!profile.isReadyForCalculation`:

```
⚠ Profile incomplete — cartridge not selected.
  [Go to Profiles]
```

Розрахунок не запускається поки профіль не повний.

---

## Route Architecture

```
ProfilesScreen  (/home/profiles)
│  PageView — кожна сторінка = один профіль
│
├── ProfileAddScreen  (/home/profiles/profile-add)
│   ├── "From Collection" → RifleCollectionScreen  (.../rifle-collection)
│   └── "Create manually" → RifleWizardScreen      (.../rifle-create)
│
├── RifleWizardScreen  (/home/profiles/rifle-edit)   [Flow 4 — edit]
│
├── CartridgeSelectScreen  (/home/profiles/cartridge-select)
│   ├─ My Cartridges + My Bullets list
│   ├─ "Create Cartridge" → CartridgeWizardScreen   (.../cartridge-create)
│   ├─ "Create Bullet"    → CartridgeWizardScreen   (.../bullet-create)
│   └─ "From Collection"  → CartridgeCollectionScreen (.../cartridge-collection)
│         └─ Select → CartridgeWizardScreen          (.../cartridge-wizard)
│
├── CartridgeWizardScreen  (/home/profiles/cartridge-edit)  [edit flow]
│
├── SightSelectScreen  (/home/profiles/sight-select)
│   ├─ My Sights list
│   ├─ "Create Sight"    → SightWizardScreen         (.../sight-create)
│   └─ "From Collection" → SightCollectionScreen     (.../sight-collection)
│         └─ Select → SightWizardScreen              (.../sight-wizard)
│
└── SightWizardScreen  (/home/profiles/sight-edit)   [edit flow]
```

### Routes constants

| Константа                    | Шлях                                                   |
| ---------------------------- | ------------------------------------------------------ |
| `Routes.profiles`            | `/home/profiles`                                       |
| `Routes.profileAdd`          | `/home/profiles/profile-add`                           |
| `Routes.rifleCreate`         | `/home/profiles/profile-add/rifle-create`              |
| `Routes.rifleCollection`     | `/home/profiles/profile-add/rifle-collection`          |
| `Routes.rifleEdit`           | `/home/profiles/rifle-edit`                            |
| `Routes.cartridgeSelect`     | `/home/profiles/cartridge-select`                      |
| `Routes.cartridgeCreate`     | `/home/profiles/cartridge-select/cartridge-create`     |
| `Routes.bulletCreate`        | `/home/profiles/cartridge-select/bullet-create`        |
| `Routes.cartridgeCollection` | `/home/profiles/cartridge-select/cartridge-collection` |
| `Routes.cartridgeWizard`     | `/home/profiles/cartridge-select/cartridge-wizard`     |
| `Routes.cartridgeEdit`       | `/home/profiles/cartridge-edit`                        |
| `Routes.sightSelect`         | `/home/profiles/sight-select`                          |
| `Routes.sightCreate`         | `/home/profiles/sight-select/sight-create`             |
| `Routes.sightCollection`     | `/home/profiles/sight-select/sight-collection`         |
| `Routes.sightWizard`         | `/home/profiles/sight-select/sight-wizard`             |
| `Routes.sightEdit`           | `/home/profiles/sight-edit`                            |

---

## Built-in Collection Asset

Файл: `assets/json/collection.json` (зареєстрований у `pubspec.yaml`)

Структура:
```
{
  "calibers": [...],      // список калібрів (id, diameter, caliberName)
  "weapon": [...],        // built-in rifles
  "cartridges": [...],    // built-in cartridges (повна балістична модель + zeroConditions)
  "projectiles": [...],   // built-in bullets (muzzleVelocity: null — юзер заповнює у wizard)
  "sights": [...]         // built-in sights
}
```

> Секція `"units"` існує лише у dev-файлі як довідка. В остаточній колекції її не буде.

**Twist direction:** позитивне `rTwist` = правий твіст, від'ємне = лівий. Стосується всіх записів.

**Стратегія завантаження:**
1. `~/.eBalistyka/collection.json` — оновлена версія з мережі (якщо є)
2. `assets/json/collection.json` — бандл (завжди доступний, fallback)

---

## Critical Files

> Після Phase 5 рефакторингу назви класів змінились: `Rifle` → `WeaponData`/`Weapon`, `Cartridge` → `AmmoData`/`Ammo`, `ShotProfile` → `ProfileData`/`Profile`.

### DB / Storage (Phase 6 — ObjectBox Migration)

| Файл | Статус | Опис |
|---|---|---|
| `packages/ebalistyka_db/lib/src/entities.dart` | 🔧 Phase 6 | Додати `ShootingConditions` entity, `sortOrder` до `Profile` |
| `packages/ebalistyka_db/lib/ebalistyka_db.dart` | 🔧 Phase 6 | Fix store init (повернути Store, прийняти directory) |
| `lib/core/providers/store_provider.dart` | 🆕 Phase 6 | storeProvider + ownerProvider |
| `lib/core/extensions/weapon_extensions.dart` | 🆕 Phase 6 | `extension WeaponData on Weapon` |
| `lib/core/extensions/ammo_extensions.dart` | 🆕 Phase 6 | `extension AmmoData on Ammo` |
| `lib/core/extensions/sight_extensions.dart` | 🆕 Phase 6 | `extension SightData on Sight` |
| `lib/core/extensions/profile_extensions.dart` | 🆕 Phase 6 | `extension ProfileData on Profile` |
| `lib/core/extensions/conditions_extensions.dart` | 🆕 Phase 6 | `extension ConditionsData on ShootingConditions` |
| `lib/core/extensions/settings_extensions.dart` | 🆕 Phase 6 | `extension AppSettings on GeneralSettings`, `extension AppUnitSettings on UnitSettings` |
| `lib/core/providers/app_state_provider.dart` | 🔧 Phase 6 | Замінити JsonFileStorage на ObjectBox |
| `lib/core/providers/shot_profile_provider.dart` | 🔧 Phase 6 | Спростити — прибрати `_resolve()`, OB relations вирішуються автоматично |
| `lib/core/providers/shot_conditions_provider.dart` | 🔧 Phase 6 | Читати `ShootingConditions` entity |
| `lib/core/providers/settings_provider.dart` | 🔧 Phase 6 | Читати `GeneralSettings`/`UnitSettings` |
| `lib/core/storage/json_file_storage.dart` | 🗑 Phase 6 | Видалити після міграції |
| `lib/core/storage/app_storage.dart` | 🗑 Phase 6 | Видалити після міграції |
| `lib/core/providers/storage_provider.dart` | 🗑 Phase 6 | Видалити після міграції |
| `lib/core/models/weapon_data.dart` | 🗑 Phase 6 | Замінити extension on Weapon |
| `lib/core/models/ammo_data.dart` | 🗑 Phase 6 | Замінити extension on Ammo |
| `lib/core/models/sight_data.dart` | 🗑 Phase 6 | Замінити extension on Sight |
| `lib/core/models/profile_data.dart` | 🗑 Phase 6 | Замінити extension on Profile |
| `lib/core/models/app_settings.dart` | 🗑 Phase 6 | Замінити extension on GeneralSettings |
| `lib/core/models/conditions_data.dart` | 🗑 Phase 6 | Замінити extension on ShootingConditions |

### App / UI

| Файл | Статус | Опис |
|---|---|---|
| `lib/main.dart` | 🔧 Phase 6 | ObjectBox init before runApp |
| `lib/core/models/seed_data.dart` | 🔧 Phase 6 | Оновити seed під ObjectBox entities |
| `lib/core/services/ballistics_service_impl.dart` | 🔧 | Zero дані з `ammo.target`, не з `profile` |
| `lib/core/a7p/a7p_parser.dart` | 🔧 | Zero дані → `Ammo` entity |
| `lib/core/collection/collection_parser.dart` | 🔧 | Парсити у OB entities або AmmoData extension |
| `lib/core/providers/builtin_collection_provider.dart` | ✅ | assets → fallback |
| `lib/features/home/sub_screens/profiles/profiles_vm.dart` | 🔧 | `ProfileCardData` під нову структуру |
| `lib/features/home/sub_screens/profiles_screen.dart` | ✅ | PageView, FAB |
| `lib/features/home/sub_screens/profiles/widgets/profile_card.dart` | 🔧 | Навігація через callbacks |
| `lib/features/home/sub_screens/rifle_wizard_screen.dart` | ✅ | Реалізований (використовує WeaponData) |
| `lib/features/home/sub_screens/home_sub_screens.dart` | 🔲 stubs | Всі під-екрани — `StubScreen` |
| `lib/router.dart` | 🔧 | Routes константи |
| `assets/json/collection.json` | ✅ | Вбудована колекція |

---

## Phases — Що залишилось

### Phase 5 — Рефакторинг моделей і провайдерів ✅

Виконано. Основні зміни:
- `WeaponData` (ex-Rifle), `AmmoData` (ex-Cartridge), `SightData`, `ProfileData` (ex-ShotProfile) — JSON моделі
- `shotProfileProvider`: resolve cartridge/sight, broken ref handling
- `ballistics_service_impl.dart`: zero дані з `ammo`, не з `profile`
- `isReadyForCalculation` у `ProfileData`

---

### Phase 6 — ObjectBox Migration 🔧

**Мета:** замінити JSON file storage на ObjectBox, усунути рейс кондішни.
Деталі в `docs/OBJECTBOX_MIGRATION.md`.

Кроки:
1. `ShootingConditions` entity + `sortOrder` у `Profile` → codegen
2. `storeProvider` + `ownerProvider`
3. Extension files (WeaponData/AmmoData/SightData/ProfileData/ConditionsData on OB entities)
4. Rewrite `AppStateNotifier` — ObjectBox замість `JsonFileStorage`
5. Simplify `ShotProfileNotifier` — прибрати `_resolve()`
6. Delete: `JsonFileStorage`, `AppStorage`, старі model класи

---

### Phase 7 — Profile Add Screen + Rifle Selection

**`ProfileAddScreen`** — вибір джерела rifle:
- "From Collection" btn → `RifleCollectionScreen`
- "Create manually" btn → `RifleWizardScreen` (порожній, всі поля редагуються)

**`RifleCollectionScreen`** — список builtin rifle (з 🔒 і кнопкою Select):
- Select → `RifleWizardScreen` (pre-filled, caliberDiameter readonly)
- Save → rifle embedded у новий `ShotProfile`

**Shared components:**
- `RifleTile` widget (reusable, кнопка Select, без cog для builtin)

---

### Phase 8 — CartridgeSelectScreen + CartridgeWizardScreen

- `CartridgeSelectScreen`: My Cartridges + My Bullets в одному списку (або tabs), filtered by `CartridgeType`
- `CartridgeCollectionScreen`: builtin cartridges + projectiles (з 🔒)
- `CartridgeWizardScreen`: повна реалізація з секціями Ballistics / MV / Zero; параметр `CartridgeType`
- `CartridgeTile` (reusable, cog для user data, Select btn)
- Після Save → ObjectBox (Ammo) → прив'язати до Profile (`profile.ammo.target`)

---

### Phase 9 — SightSelectScreen + SightWizardScreen

- Аналогічно Phase 7 для Sight
- `SightTile` (reusable)
- Після Save → ObjectBox (Sight) → прив'язати до Profile (`profile.sight.target`)

---

### Phase 10 — IncompleteBanner + ProfileCard навігація

- `IncompleteBanner` widget на Home / Conditions / Tables
- `RecalcCoordinator` блокує перерахунок якщо `!isReadyForCalculation`
- `ProfileCard`: навігація через callbacks у `ProfilesScreen`, не `context.go` у widget
- `ProfileCardData`: оновити під нову структуру (cartridge name, sight name або "Not selected")

---

### Phase 11 — Duplicate Profile + FAB меню

- "Duplicate" у FAB меню `ProfilesScreen`
- Dialog для введення нової назви
- Копія профілю з новим UUID; rifle копіюється embedded; `cartridgeId`/`sightId` — ті самі references

---

### Phase 12 — Edit Flows (Flow 4)

- "Edit Rifle ›" у ProfileCard → `RifleWizardScreen` з поточними даними (caliberDiameter readonly)
- "Edit Cartridge ›" → `CartridgeWizardScreen` з поточними даними
- "Edit Sight ›" → `SightWizardScreen` з поточними даними

---

### Phase 13 — Built-in Collection Update (майбутнє)

Колекція — офлайн за замовчуванням (assets). Оновлення в додатку:
1. Перевірити останній тег `a7p-lib`
2. Порівняти з локально збереженим
3. Запропонувати оновлення (або тихо у фоні)
4. Нові builtin **додаються**, наявні — **не перезаписуються**

---

## Verification Checklist

| #   | Перевірка                                                                               | Статус |
| --- | --------------------------------------------------------------------------------------- | ------ |
| 1   | Імпорт `.a7p` → zero дані зберігаються в `Cartridge`                                    | 🔲      |
| 2   | Вибір профілю → Home показує rifle/cartridge/sight обраного профілю                     | ✅      |
| 3   | Зміна conditions/winds → відновлюється при поверненні до профілю                        | ✅      |
| 4   | Conditions screen не перезаписує zero conditions                                        | ✅      |
| 5   | Балістичний розрахунок: zero дані беруться з `cartridge`, не з `profile`                | 🔲      |
| 6   | Видалення профілю → бібліотека оновлюється                                              | ✅      |
| 7   | Select профілю → `moveToFirst` → наступного разу активний перший                        | ✅      |
| 8   | Фліккер при PageView scroll — виправлено унікальними `heroTag`                          | ✅      |
| 9   | `collection.json` парситься у `BuiltinCollection`                                       | ✅      |
| 10  | `builtinCollectionProvider`: пріоритет `~/.eBalistyka/collection.json`, fallback assets | ✅      |
| 11  | `Rifle.caliberDiameter` — зберігається/відновлюється, backward-compat                   | ✅      |
| 12  | `Rifle.barrelLength` — optional, backward-compat                                        | ✅      |
| 13  | `Rifle.isRightHandTwist` — getter від знаку `twist.raw`                                 | ✅      |
| 14  | Broken ref cartridgeId → обнулення + toast                                              | 🔲      |
| 15  | Broken ref sightId → обнулення + toast                                                  | 🔲      |
| 16  | `isReadyForCalculation` — блокує розрахунок, показує `IncompleteBanner`                 | 🔲      |
| 17  | Flow 1: новий профіль → rifle wizard → профіль без cartridge/sight                      | 🔲      |
| 18  | Flow 2: вибір cartridge → прив'язується до профілю                                      | 🔲      |
| 19  | Flow 3: вибір sight → прив'язується до профілю                                          | 🔲      |
| 20  | Flow 4: edit rifle → оновлюється embedded у профілі                                     | 🔲      |
| 21  | Flow 5: duplicate profile → новий UUID, rifle копіюється, ids ті самі                   | 🔲      |
| 22  | Bullet `type: bullet` → MV required у wizard                                            | 🔲      |
| 23  | Cartridge list фільтрується по `caliberDiameter` rifle (optional)                       | 🔲      |

---

## Reusable Patterns

- `showUnitEditDialog()` / `UnitValueField` — для wizard
- `BaseScreen` + `ScreenTopBar` — для wizard як route
- Display model pattern (`ProfileCardData`) — форматування у ViewModel, widget лише відображає
- `ItemListView<T>` + typed Tile widgets — для всіх списків (My Items + Collection Browser)
- `IncompleteBanner` — shared widget для Home / Conditions / Tables