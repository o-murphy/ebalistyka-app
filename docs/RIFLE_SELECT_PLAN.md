# Profiles & Selection Architecture

> Об'єднаний документ (замінює `RIFLE_SELECT_PLAN.md` і `plan_profile_select_architecture.md`)

---

## Поточний стан

### Реалізовано (Phase 1–4)
- Phase 1 ✅ — Powder sensitivity: `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`, `useDiffPowderTemp` у `ShotProfile`; `useDifferentPowderTemp` видалено з `Cartridge`
- Phase 2 ✅ — Data ownership: межі відповідальності між ballistic / runtime / global даними
- Phase 3 ✅ — Profile Library Provider + Storage refactor: `profiles.json` як `{activeProfileId, profiles:[...]}`, `moveToFirst`, backward-compat
- Phase 4 ✅ — Profiles Screen: `ProfilesVm`, `ProfilesScreen`, `ProfileCardData`, `profile_card.dart`
- `rifle_wizard_screen.dart` ✅ — базова структура (скелет)
- `home_sub_screens.dart` ✅ — всі суб-екрани як заглушки (`StubScreen`)

---

## Storage Architecture

### `~/.eBalistyka/profiles.json`

```json
{
  "activeProfileId": "some-uuid",
  "profiles": [
    {
      "id": "...",
      "name": "...",
      "rifle": { "id": "...", ... },
      "cartridge": { "id": "...", ... },
      "sight": { "id": "...", ... },
      "conditions": { ... },
      "winds": [...],
      "lookAngle": 0.0,
      "targetDistance": 100.0,
      "zeroConditions": { ... }
    }
  ]
}
```

Backward-compat: plain array `[...]` (старий формат) — читається без `activeProfileId`.

### Глобальні файли

```
~/.eBalistyka/
  profiles.json          ← бібліотека профілів (активний ID + список)
  rifles.json            ← "My Rifles" юзера
  cartridges.json        ← "My Cartridges" юзера
  bullets.json           ← "My Bullets" юзера (окрема колекція)
  sights.json            ← "My Sights" юзера
  settings.json          ← AppSettings (одиниці, теми)
  table_settings.json    ← TableSettings
```

---

## Data Ownership

| Дані | Належить | Редагується де |
|---|---|---|
| name, rifle, cartridge, sight | `ShotProfile` | Profile wizard / Edit screens |
| zeroDistance, zeroConditions | `ShotProfile` | Profile wizard / Edit Zero |
| zeroUsePowderSensitivity, zeroUseDiffPowderTemp | `ShotProfile` | Edit Zero |
| conditions (Atmo) | `ShotProfile` (runtime, per-profile) | Conditions screen |
| useDiffPowderTemp | `ShotProfile` (runtimeu, per-profile) | Conditions screen |
| winds, lookAngle, targetDistance | `ShotProfile` (runtime, per-profile) | Home screen |
| Rifle (вся модель) | `rifles.json` | Rifle Wizard |
| Cartridge (вся модель) | `cartridges.json` | Cartridge/Bullet Wizard |
| Sight (вся модель) | `sights.json` | Sight Wizard |
| AppSettings, TableSettings | Global | Settings screen |

---

## Вбудована vs Користувацька колекції

### Дві точки доступу

**Вбудована колекція** (`builtin: true`) — поставляється з додатком (assets або тег git).
Ніде не відображається у основних екранах. Доступна виключно через "From Collection" →
`CollectionBrowserScreen`. При виборі — запис **копіюється** у бібліотеку юзера (новий UUID, `builtin: false`).

**Бібліотека юзера** (`builtin: false`) — все що юзер створив, імпортував, або скопіював
з вбудованої колекції. Саме ця бібліотека відображається скрізь.

```
My Rifles / My Cartridges / My Sights       Built-in Collection (hidden)
─────────────────────────────               ──────────────────────────────
 [My .338LM UKROP]  ←copy──────────────────  🔒 .338LM UKROP 250GR SMK
 [Hornady 285 copy] ←copy──────────────────  🔒 Hornady 285GR ELD-M
 [Imported from .a7p]                        🔒 ...

  "From Collection" btn ─────────────────►  CollectionBrowserScreen
```

| Дія | Вбудована | Юзерська |
|---|---|---|
| Відображення у My Items | ❌ | ✅ |
| Відображення у Collection Browser | ✅ (з 🔒) | ❌ |
| "From Collection" | → копія до юзера | — |
| Видалити | ❌ (read-only) | ✅ (з обмеженнями) |
| Редагувати | ❌ | ✅ |

---

## Спільні використані об'єкти (Reference Sharing)

Профіль зберігає **посилання** на об'єкт (по `id`) у відповідній бібліотеці (`rifles.json` тощо).
Один і той самий Rifle / Cartridge / Sight може бути використаний кількома профілями одночасно.

**Наслідки:**
- Якщо юзер редагує Rifle в одному профілі → зміни відображаються у всіх профілях, що використовують цей Rifle.
- Якщо Rifle видаляється — профілі, що його використовують, втрачають цей запис (broken ref).
- **Не можна видалити** Rifle/Cartridge/Sight, якщо він у використанні хоч одним профілем.
- Якщо юзер хоче незалежну копію — використовує "Duplicate" → новий UUID, зміни ізольовані.
- При спробі редагувати або видалити об'єкт, що використовується кількома профілями → **попередження** з переліком профілів.

---

## Wizard Screen — Концепція (Повторно використовуваний)

`RifleWizardScreen` — це **тимчасова форма вводу**, що перевикористовується у кількох flow.
Аналогічна логіка застосовується для `CartridgeWizardScreen` (= Bullet) та `SightWizardScreen`.

**Властивості wizard:**
- Приймає початкові дані (або порожній стан для нового запису)
- Дозволяє редагувати всі поля перед збереженням
- Валідує введення (обов'язкові поля, constraints)
- При натисканні "Save" — повертає результат у caller через `Navigator.pop(result)`
- При натисканні "Discard" — повертає `null`, зміни відкидаються

**Wizard не знає контексту виклику** — він просто редагує дані та повертає результат.
Логіка того, що робити із результатом (зберегти у my rifles, прив'язати до профілю тощо) — у caller.

---

## Flow Branches — Rifle (приклад; аналогічно для Cartridge/Sight)

### Flow 1: Новий профіль → Із колекції → Зберегти rifle у My Rifles

```
ProfilesScreen
  └─ FAB Add
      └─ Enter profile name dialog
          └─ ProfileAddScreen
              └─ My Rifles section
                  └─ "From Collection" btn
                      └─ RifleCollectionScreen (built-in browser)
                          └─ "Select" btn (on item)
                              └─ RifleWizardScreen (pre-filled з builtin даних)
                                  └─ Save
                                      ├─ copy rifle → rifles.json (My Rifles)
                                      └─ create new ShotProfile → profiles.json
```

### Flow 2: Редагування rifle поточного профілю

```
ProfilesScreen (profile card)
  └─ "Edit Rifle" btn
      └─ RifleWizardScreen (pre-filled з поточного profile.rifle)
          └─ Save
              └─ update rifle у rifles.json
              └─ update profile.rifle ref (якщо потрібно)
```

> Якщо rifle використовується іншими профілями → попередження + вибір: редагувати спільне або зробити копію.

### Flow 3: Новий профіль → Створити новий rifle

```
ProfilesScreen
  └─ FAB Add
      └─ Enter profile name dialog
          └─ ProfileAddScreen
              └─ My Rifles section
                  └─ "Create Rifle" btn
                      └─ Enter rifle name dialog
                          └─ RifleWizardScreen (порожній)
                              └─ Save
                                  ├─ save rifle → rifles.json
                                  └─ create new ShotProfile → profiles.json
```

### Flow 4: Новий профіль → Вибрати з My Rifles

```
ProfilesScreen
  └─ FAB Add
      └─ Enter profile name dialog
          └─ ProfileAddScreen
              └─ My Rifles section
                  └─ Select item (з My Rifles list)
                      └─ Enter new rifle name dialog (якщо хоче копію) — або одразу прив'язати
                          └─ RifleWizardScreen (pre-filled з вибраного)
                              └─ Save
                                  ├─ save rifle copy → rifles.json
                                  └─ create new ShotProfile → profiles.json
```

> Примітка: якщо юзер вибирає наявний rifle без "Duplicate" — профіль буде share той самий об'єкт.

---

## Shared UI Components

### Списки: My Items vs Collection Browser

**My Rifles / My Cartridges / My Sights / My Bullets** — списки юзерських об'єктів.
**RifleCollectionScreen / CartridgeCollectionScreen / ...** — браузер вбудованої колекції.

Обидва типи списків використовують **спільний набір компонентів**:

```
ItemListView (generic, reusable)
  └─ RifleTile      ← reusable tile for Rifle
  └─ CartridgeTile  ← reusable tile for Cartridge
  └─ BulletTile     ← reusable tile for Bullet
  └─ SightTile      ← reusable tile for Sight
```

**Tile поведінка:**
- Якщо `builtin: true` → **без cog btn**
- Якщо `builtin: false` (user data) → показувати **cog btn** (⚙️) для налаштувань (edit / duplicate / delete)
- Tap на tile (без cog) → вибір / копіювання в wizard

---

## Cartridge, Bullet, Sight — специфіка

### Cartridge vs Bullet
- **Cartridge** = повна модель (куля + гільза + порошок + MV + BC + ...)
- **Bullet** = тільки куля (діаметр, вага, BC, drag model) — деякі поля не заповнені або defaulted
- Обидва використовують **один і той самий `CartridgeWizardScreen`**, але з різним набором обов'язкових полів
- Зберігаються у **різних колекціях** (`cartridges.json` vs `bullets.json`)
- **Wizard детектує тип** через переданий параметр (`isProjectileOnly: bool`)

### Фільтрація по калібру
- Списки картриджів та куль (у виборі для профілю) **фільтруються по caliber поточного rifle**
- Якщо rifle не вибрано — показуються всі

### Sight
- `SightWizardScreen` — окремий wizard, спрощена структура
- Аналогічна логіка flow (select from collection / create / edit)

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
│                     [Edit Rifle ›]   │  ← → Flow 2
├──────────────────────────────────────┤
│  ── Cartridge ─────────────────      │
│  MV             888 m/s              │
│  Bullet         250 gr · .338"       │
│  Drag model     G7 · BC 0.314        │
│                  [Edit Cartridge ›]  │
├──────────────────────────────────────┤
│  ── Zero ──────────────────────      │
│  Distance       100 m                │
│  Temperature    15°C · 1000 hPa      │
│                     [Edit Zero ›]    │
├──────────────────────────────────────┤
│              [  Select  ]            │  ← тільки якщо не активний
└──────────────────────────────────────┘
```

- Активний профіль: кнопка "Select" → `✓ Active` + підсвічування картки
- PageView горизонтальний; картка скролиться вертикально всередині

---

## Route Architecture

```
ProfilesScreen  (/home/rifle-select)
│  PageView — кожна сторінка = один профіль
│
├── ProfileAddScreen  (/home/rifle-select/profile-add)        FAB → Add
│   ├── My Rifles list  (вбудований у ProfileAddScreen або окремий sub-screen)
│   │   ├── "From Collection" → RifleCollectionScreen  (.../rifle-collection)   [Flow 1]
│   │   ├── "Create Rifle"   → RifleWizardScreen       (.../rifle-create)       [Flow 3]
│   │   └── select item      → RifleWizardScreen       (.../rifle-wizard)       [Flow 4]
│   │
│   └── (аналогічно My Cartridges / My Sights після вибору rifle)
│
├── RifleWizardScreen  (/home/rifle-select/rifle-wizard)       [Flow 2 — edit]
│
├── CartridgeSelectScreen  (/home/rifle-select/cartridge-select)
│   ├── My Cartridges list
│   │   ├── "From Collection" → CartridgeCollectionScreen  (.../cartridge-collection)
│   │   ├── "Create Cartridge" → CartridgeWizardScreen     (.../cartridge-create)
│   │   └── select item        → CartridgeWizardScreen     (.../cartridge-wizard)
│   └── My Bullets list  (tab або секція)
│       ├── "From Collection" → BulletCollectionScreen      (.../bullet-collection)
│       ├── "Create Bullet"   → CartridgeWizardScreen (isProjectileOnly) (.../bullet-create)
│       └── select item       → CartridgeWizardScreen (isProjectileOnly) (.../bullet-wizard)
│
├── SightSelectScreen  (/home/rifle-select/sight-select)
│   ├── "From Collection" → SightCollectionScreen  (.../sight-collection)
│   ├── "Create Sight"    → SightWizardScreen      (.../sight-create)
│   └── select item       → SightWizardScreen      (.../sight-wizard)
│
├── CartridgeWizardScreen  (/home/rifle-select/cartridge-edit)  [edit flow]
├── SightWizardScreen      (/home/rifle-select/sight-edit)      [edit flow]
└── ZeroEditScreen         (/home/rifle-select/zero-edit)
```

### Routes constants

| Константа | Шлях |
|---|---|
| `Routes.profiles` | `/home/rifle-select` |
| `Routes.profileAdd` | `/home/rifle-select/profile-add` |
| `Routes.rifleWizard` | `/home/rifle-select/rifle-wizard` |
| `Routes.rifleCollection` | `/home/rifle-select/rifle-collection` |
| `Routes.cartridgeSelect` | `/home/rifle-select/cartridge-select` |
| `Routes.cartridgeWizard` | `/home/rifle-select/cartridge-wizard` |
| `Routes.cartridgeCollection` | `/home/rifle-select/cartridge-collection` |
| `Routes.bulletWizard` | `/home/rifle-select/bullet-wizard` |
| `Routes.bulletCollection` | `/home/rifle-select/bullet-collection` |
| `Routes.sightSelect` | `/home/rifle-select/sight-select` |
| `Routes.sightWizard` | `/home/rifle-select/sight-wizard` |
| `Routes.sightCollection` | `/home/rifle-select/sight-collection` |
| `Routes.cartridgeEdit` | `/home/rifle-select/cartridge-edit` |
| `Routes.sightEdit` | `/home/rifle-select/sight-edit` |
| `Routes.zeroEdit` | `/home/rifle-select/zero-edit` |

---

## Built-in Collection Asset

Файл: `assets/json/collection.json` (зареєстрований у `pubspec.yaml`)

Структура:
```
{
  "calibers": [...],         // список калібрів (id, diameter/caliber, caliberName)
  "weapon": [...],           // built-in rifles (vendor, name, caliberId, rTwist, extra.barrelLength)
  "cartridges": [...],       // built-in cartridges (повна балістична модель)
  "projectiles": [...],      // built-in bullets (muzzleVelocity: null — юзер заповнює)
  "sights": [...]            // built-in sights
}
```

> Секція `"units"` існує лише у dev-файлі як довідка для написання парсера.
> В остаточній колекції її не буде — одиниці захардкоджені у парсері.

**Twist direction у колекції:** `rTwist` завжди позитивний (тільки правий твіст).
Від'ємний `twist.raw` на моделі означає лівий твіст — тільки для користувацьких записів.

**Стратегія завантаження:**
1. `~/.eBalistyka/collection.json` — оновлена версія з мережі (якщо є)
2. `assets/json/collection.json` — бандл (завжди доступний, fallback)

**При копіюванні до юзера:** новий UUID, дані переносяться у відповідну модель (`Rifle`, `Cartridge`, `Projectile`, `Sight`).

---

## Critical Files

| Файл | Статус | Опис |
|---|---|---|
| `lib/core/models/shot_profile.dart` | ✅ | `zeroUsePowderSensitivity`, `zeroUseDiffPowderTemp`, `useDiffPowderTemp` |
| `lib/core/models/cartridge.dart` | ✅ | Видалено `useDifferentPowderTemp` |
| `lib/core/models/rifle.dart` | ✅ | `caliberDiameter?`, `barrelLength?`, getter `isRightHandTwist` |
| `lib/core/models/sight.dart` | ✅ | Базова модель |
| `lib/core/models/projectile.dart` | ✅ | Модель кулі |
| `lib/core/models/field_constraints.dart` | ✅ | + `FC.barrelLength` (inch, 1–36, step 0.5) |
| `lib/core/models/unit_settings.dart` | ✅ | + `barrelLength: Unit` (default inch) |
| `lib/core/models/_storage.dart` | ✅ | + `weaponBarrelLength = Unit.inch` |
| `lib/core/models/seed_data.dart` | ✅ | 3 seed-профілі у `seedShotProfiles` |
| `lib/core/formatting/unit_formatter.dart` | ✅ | + `barrelLength()`, `barrelLengthSymbol`, `InputField.barrelLength` |
| `lib/core/formatting/unit_formatter_impl.dart` | ✅ | Реалізація barrelLength |
| `lib/core/services/ballistics_service_impl.dart` | ✅ | Уніфікована логіка порошкової чутливості |
| `lib/core/a7p/a7p_parser.dart` | ✅ | `zeroUsePowderSensitivity` при імпорті |
| `lib/core/storage/app_storage.dart` | ✅ | + `loadCollectionJson()`, `saveCollectionJson()` |
| `lib/core/storage/json_file_storage.dart` | ✅ | + collection cache: `~/.eBalistyka/collection.json` |
| `lib/core/collection/collection_parser.dart` | ✅ | `CollectionParser.parse()` + `BuiltinCollection` |
| `lib/core/providers/shot_profile_provider.dart` | ✅ | `_update` → синхронізує `profileLibraryProvider` (runtime state bug fix) |
| `lib/core/providers/profile_library_provider.dart` | ✅ | CRUD + `moveToFirst` + seed |
| `lib/core/providers/builtin_collection_provider.dart` | ✅ | assets → fallback; `~/.eBalistyka/collection.json` → пріоритет |
| `lib/core/providers/library_provider.dart` | ✅ | Rifle / Cartridge / Sight бібліотеки |
| `lib/features/home/sub_screens/profiles/profiles_vm.dart` | ✅ | `ProfileCardData`, sealed state |
| `lib/features/home/sub_screens/profiles_screen.dart` | ✅ | PageView, FAB |
| `lib/features/home/sub_screens/profiles/widgets/profile_card.dart` | ✅ | Pure widget |
| `lib/features/home/sub_screens/rifle_wizard_screen.dart` | 🔧 skeleton | Потребує реалізації — Phase 5 |
| `lib/features/home/sub_screens/home_sub_screens.dart` | 🔲 stubs | Всі під-екрани — `StubScreen` |
| `lib/router.dart` | ✅ | Дерево маршрутів (потребує оновлення під нові routes) |
| `assets/json/collection.json` | ✅ | Вбудована колекція (зареєстрована у pubspec.yaml) |

---

## Phases — Що залишилось

### Phase 5 — Profile Add Screen + Rifle Selection

**`ProfileAddScreen`** — вибір джерела rifle (My Rifles список + кнопки flows 1/3/4):
- My Rifles `ListView` з `RifleTile` (cog для user data)
- "From Collection" btn → `RifleCollectionScreen`
- "Create Rifle" btn → ім'я dialog → `RifleWizardScreen` (порожній)
- Tap на tile → `RifleWizardScreen` (pre-filled)

**`RifleCollectionScreen`** — список builtin rifle (з 🔒):
- Tap "Select" → `RifleWizardScreen` (pre-filled з builtin)

**`RifleWizardScreen`** — реалізувати повністю:
- Приймає `Rifle?` (null = новий)
- Валідація полів
- Save → `Navigator.pop(rifle)`
- Discard → `Navigator.pop(null)`

**Shared components:**
- `RifleTile` widget (reusable, з cog для user data, 🔒 для builtin)
- `ItemListView` generic wrapper

---

### Phase 6 — CartridgeSelectScreen + CartridgeWizardScreen

- Аналогічно Phase 5, але для Cartridge і Bullet
- `isProjectileOnly` параметр у wizard
- Фільтрація по caliber поточного rifle
- `CartridgeTile`, `BulletTile` (reusable)

---

### Phase 7 — SightSelectScreen + SightWizardScreen

- Аналогічно Phase 5 для Sight
- `SightTile` (reusable)

---

### Phase 8 — Edit Flows (Flow 2)

- "Edit Rifle ›" у ProfileCard → `RifleWizardScreen` з поточними даними + логіка shared ref warning
- "Edit Cartridge ›" → `CartridgeWizardScreen`
- "Edit Sight ›" → `SightWizardScreen`
- "Edit Zero ›" → `ZeroEditScreen`

---

### Phase 9 — Reference Sharing Logic

- При видаленні: перевірити `usedBy` (скільки профілів використовують цей Rifle/Cartridge/Sight)
- Якщо `usedBy.length > 0` → блокувати видалення з `SnackBar` / dialog
- При редагуванні з кількох профілів → показати warning dialog з переліком профілів
- "Duplicate" action у cog меню tile → копія з новим UUID

---

### Phase 10 — Built-in Collection Update (майбутнє)

Колекція — офлайн за замовчуванням (assets). Оновлення в додатку:
1. Перевірити останній тег `a7p-lib`
2. Порівняти з локально збереженим
3. Запропонувати оновлення (або тихо у фоні)
4. Завантажити `profiles.json` / `.a7p` файли → оновити builtin локально

Нові builtin **додаються**, наявні — **не перезаписуються**.

---

## Verification Checklist

| # | Перевірка | Статус |
|---|---|---|
| 1 | Імпорт `.a7p` → `zeroUsePowderSensitivity` встановлюється коректно | ✅ |
| 2 | Вибір профілю → Home показує rifle/cartridge/sight обраного профілю | ✅ |
| 3 | Зміна conditions/winds → відновлюється при поверненні до профілю | ✅ fixed |
| 4 | Conditions screen не перезаписує zero conditions | ✅ |
| 5 | Балістичний розрахунок: уніфікована логіка порошкової чутливості | ✅ |
| 6 | Видалення профілю → бібліотека оновлюється | ✅ |
| 7 | Select профілю → `moveToFirst` → наступного разу активний перший | ✅ |
| 8 | Фліккер при PageView scroll — виправлено унікальними `heroTag` | ✅ |
| 9 | `collection.json` парситься у `BuiltinCollection` (rifles/cartridges/projectiles/sights) | ✅ |
| 10 | `builtinCollectionProvider`: пріоритет `~/.eBalistyka/collection.json`, fallback assets | ✅ |
| 11 | `Rifle.caliberDiameter` — зберігається/відновлюється, backward-compat | ✅ |
| 12 | `Rifle.barrelLength` — optional, зберігається/відновлюється, backward-compat | ✅ |
| 13 | `Rifle.isRightHandTwist` — getter від знаку `twist.raw` | ✅ |
| 14 | Flow 1: builtin rifle → wizard → новий профіль + зберігається у My Rifles | 🔲 |
| 15 | Flow 2: edit rifle → wizard → оновлюється у rifles.json | 🔲 |
| 16 | Flow 3: create rifle → wizard → новий профіль | 🔲 |
| 17 | Flow 4: select My Rifle → wizard → новий профіль | 🔲 |
| 18 | Cartridge list фільтрується по `caliberDiameter` rifle | 🔲 |
| 19 | Shared rifle — warning при редагуванні/видаленні | 🔲 |
| 20 | Bullet wizard (`isProjectileOnly`) — різні required поля | 🔲 |

---

## Відомий баг — Incomplete Profile не обробляється

### Симптом
Якщо профіль не містить достатніх даних для розрахунку (наприклад, картридж з нульовим MV або
відсутній sight) — Home, Conditions, Tables відображають некоректні/безглузді значення замість
попередження.

### Бажана поведінка
- `ShotProfile` має метод/геттер `isReadyForCalculation` → `bool`
- Якщо `false`: Home / Conditions / Tables показують мінімальну доступну інформацію
  + банер/попередження "Profile incomplete — go to profiles to finish setup"
- Розрахунок не запускається поки профіль не повний

### Що перевіряти (орієнтовно)
| Поле | Умова |
|---|---|
| `rifle.caliberDiameter` | не null, > 0 |
| `rifle.sightHeight` | >= 0 |
| `rifle.twist` | != 0 |
| `cartridge.mv` | > 0 |
| `cartridge.projectile.coefRows` | не порожній |
| `cartridge.projectile.diameter` | > 0 |
| `cartridge.projectile.weight` | > 0 |

### Де реалізовувати
- Геттер `isReadyForCalculation` у `ShotProfile`
- `shotProfileProvider` або `recalcCoordinatorProvider` — блокує перерахунок якщо `!isReady`
- Home / Conditions / Tables — показують `IncompleteBanner` якщо `!isReady`

**Пріоритет:** після підключення всіх wizard flows.

---

## Reusable Patterns

- `showUnitEditDialog()` / `UnitValueField` — для wizard
- `BaseScreen` + `ScreenTopBar` — для wizard як route
- Display model pattern (`ProfileCardData`) — форматування у ViewModel, widget лише відображає
- `ItemListView<T>` + typed Tile widgets — для всіх списків (My Items + Collection Browser)
