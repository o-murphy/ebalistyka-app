# eBalistyka — Master Project Document

**Version:** 3.0
**Status:** Living Document — updated 2026-04-20
**Stack:** Flutter · Dart · Riverpod · ObjectBox · FFI (bclibc C++)
**Package:** `ebalistyka` · Bundle ID: `com.ballistics.ebalistyka`

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Global UI Rules](#2-global-ui-rules)
3. [Navigation Model](#3-navigation-model)
4. [Primary Screens](#4-primary-screens)
5. [Additional Screens & Components](#5-additional-screens--components)
6. [State Architecture](#6-state-architecture)
7. [Open Questions](#7-open-questions)
8. [Current Codebase Status](#8-current-codebase-status)
9. [Implementation Phases](#9-implementation-phases)
10. [Dependencies](#10-dependencies)
11. [Execution Order](#11-execution-order)

---

## 1. Product Overview

Mobile application for ballistic calculations. Provides a shooter with tools to calculate trajectory, scope adjustments, ballistic tables, and unit conversions.

All state is stored **locally** — no cloud synchronization planned.

---

## 2. Global UI Rules

### 2.1 Units of Measurement

All value displays and input fields use the units selected by the user in **Settings**. No hardcoded units anywhere in the UI.

### 2.2 Value Input

| Input type                                                | Method                             |
| --------------------------------------------------------- | ---------------------------------- |
| Ruler selectors (wind speed, look angle, target distance) | Touch drag **and** keyboard (both) |
| All other value selectors                                 | Keyboard only via dialog           |

### 2.3 Screen Headers

All screens **except Home** have a top header with:
- Screen title centered
- Back button (←) on the left
- Optional action buttons on the right

**Home** has no header.

---

## 3. Navigation Model

### 3.1 Primary Navigation

The app has **5 primary screens** switched via a **Bottom Navigation Bar**:

| #   | ID           | Name       | Description                   |
| --- | ------------ | ---------- | ----------------------------- |
| 1   | `home`       | Home       | Current shot                  |
| 2   | `conditions` | Conditions | Environmental conditions      |
| 3   | `tables`     | Tables     | Current shot trajectory table |
| 4   | `convertors` | Convertors | Unit converters               |
| 5   | `settings`   | Settings   | App settings                  |

### 3.2 Stack Model

Each primary screen has its **own independent navigation stack**. Sub-screens are pushed onto the stack of the screen that opened them.

**The Bottom Navigation Bar is always visible** — including inside any sub-screen. Tapping a nav bar item:
- Clears the entire current stack
- Navigates to the selected primary screen (or returns to it if already active)

### 3.3 Stacks per Screen

| Primary screen | Sub-screen stack                                           |
| -------------- | ---------------------------------------------------------- |
| **Home**       | → Profiles (PageView) → Weapon/Ammo/Sight wizards          |
| **Home**       | → Shot Details (Info screen)                               |
| **Settings**   | → Units of Measurement                                     |
| **Settings**   | → Adjustment Display                                       |
| **Tables**     | → Table Configuration                                      |
| **Convertors** | → Convertor Screen (individual converter)                  |

### 3.4 Back Button Behavior

| Situation                      | Action                                                     |
| ------------------------------ | ---------------------------------------------------------- |
| Inside a sub-screen            | Pop stack → previous screen                                |
| On a primary screen (not Home) | Navigate to **Home**                                       |
| Tap on nav bar                 | Clears entire stack → navigates to selected primary screen |

### 3.5 GoRouter Route Map

```
/ (ShellRoute — bottom nav always visible)
├── /home
│   ├── /home/profiles
│   │   ├── /home/profiles/weapon-create
│   │   ├── /home/profiles/weapon-collection
│   │   │     └── /home/profiles/weapon-wizard
│   │   ├── /home/profiles/weapon-edit
│   │   ├── /home/profiles/ammo-select
│   │   │   ├── .../ammo-create
│   │   │   ├── .../cartridge-collection → .../ammo-wizard
│   │   │   └── .../bullet-collection → .../ammo-wizard
│   │   ├── /home/profiles/ammo-edit
│   │   │   ├── .../multi-bc-g1 / multi-bc-g7
│   │   │   ├── .../drag-table
│   │   │   └── .../powder-sensitivity
│   │   ├── /home/profiles/sight-select
│   │   │   ├── .../sight-create
│   │   │   └── .../sight-collection → .../sight-wizard
│   │   └── /home/profiles/sight-edit
│   └── /home/shot-details
├── /conditions
├── /tables
│   └── /tables/configure
├── /convertors
│   └── /convertors/:type
└── /settings
    ├── /settings/units
    └── /settings/adjustment
```

---

## 4. Primary Screens

---

### 4.1 Home Screen

> **Purpose:** Main working screen. Displays current shot parameters and calculated data.

The screen is split vertically into **two blocks**:

```
┌──────────────────────────┐
│   Current Shot Props     │  (top ~55%)
├──────────────────────────┤
│   Current Shot Data      │  (bottom, 3 pages)
└──────────────────────────┘
```

#### 4.1.1 Block: Current Shot Props

Control panel for shot parameters.

**Selectors:**

| Element                     | Action                                         |
| --------------------------- | ---------------------------------------------- |
| Rifle/Profile selection button | Opens ProfilesScreen (stack push)           |
| Projectile (Ammo) display      | Info-only, edit via ProfilesScreen          |

**Navigation buttons:**

| Element             | Action                                          |
| ------------------- | ----------------------------------------------- |
| Shot details button | Pushes Shot Details screen ✅                    |
| New note button     | `showNotAvailableSnackBar` stub (→ Phase 12)    |
| Help button         | `showNotAvailableSnackBar` stub (→ Phase 12)    |
| More button         | `showNotAvailableSnackBar` stub (→ Phase 12)    |

**Read-only indicators** (values from Conditions screen):

| Element          | Value               |
| ---------------- | ------------------- |
| Temperature sign | Current temperature |
| Altitude sign    | Current altitude    |
| Humidity sign    | Current humidity    |
| Pressure sign    | Current pressure    |

**Wind Direction Wheel:** Interactive element for selecting wind direction. Displays current direction. Double-tap resets to 0°. ✅

**Quick action buttons** (each opens a spin-box dialog):

| Button          | Parameter              |
| --------------- | ---------------------- |
| Wind speed      | Wind velocity          |
| Look angle      | Shot inclination angle |
| Target distance | Distance to target     |

#### 4.1.2 Block: Current Shot Data — 3 Pages

Switched by swipe.

**Page 1: Reticle + Adjustments** ✅

```
┌──────────────────────────────────────┐
│  [SVG reticle + correction dot] │ ↑ 2.34   │
│                                 │ MIL      │
│                                 │ 0.98 MOA │
│                                 │ ─────────│
│                                 │ → 0.12   │
│                                 │ MIL      │
└──────────────────────────────────────┘
```

- Left: SVG reticle via `reticleSvgProvider`, color roles resolved, correction indicator overlaid
- Right: Drop/Windage in enabled adjustment units; `AdjustmentFormat` (arrows/signs/letters)

**Page 2: Adjustment Tables** ✅

Vertically scrollable set of compact tables (target ± 2 steps, 11 rows).

**Page 3: Trajectory Chart** ✅

- Info grid with selected point values (trajectory + velocity curves)
- Pan → nearest point; axis numeric labels only

---

### 4.2 Conditions Screen ✅

> **Purpose:** Input and editing of environmental parameters.

| Parameter   | Unit                |
| ----------- | ------------------- |
| Temperature | `units.temperature` |
| Altitude    | `units.distance`    |
| Humidity    | %                   |
| Pressure    | `units.pressure`    |

**Switches:** Coriolis, Powder temperature sensitivity (with sub-switch + powder temp field + readonly MV/sensitivity), Derivation, Aerodynamic jump (always ON, disabled), Pressure depends on altitude (always ON, disabled).

---

### 4.3 Tables Screen ✅

> **Purpose:** Full trajectory table for the current shot.

| Element                   | Description                                                                |
| ------------------------- | -------------------------------------------------------------------------- |
| **Header**                | Back button, "Tables" title, Configure + Export buttons                    |
| **Spoiler / accordion**   | Collapsible panel: rifle, cartridge, sight, atmospheric conditions summary |
| **Zero crossing table**   | Small table showing zero-crossing points                                   |
| **Full trajectory table** | Complete trajectory; zero-distance row highlighted                         |
| **Configure button**      | Pushes `/tables/configure`                                                 |
| **Export button**         | HTML export via `table_html_exporter.dart` ✅                               |

---

### 4.4 Convertors Screen

> **Purpose:** Collection of unit converters.

**Layout:** Responsive scrollable grid (`SliverGrid.extent`, `maxCrossAxisExtent ≈ 160 dp`). ✅

**Converters (8 total):**

| #   | Route type        | Name                  | Status |
| --- | ----------------- | --------------------- | ------ |
| 1   | `target-distance` | Target Distance       | ⏳ stub |
| 2   | `velocity`        | Velocity              | ✅      |
| 3   | `length`          | Length                | ✅      |
| 4   | `weight`          | Weight                | ✅      |
| 5   | `pressure`        | Pressure              | ✅      |
| 6   | `temperature`     | Temperature           | ✅      |
| 7   | `mil-moa`         | MIL / MOA at Distance | ✅      |
| 8   | `torque`          | Torque                | ✅      |

---

### 4.5 Settings Screen

> **Purpose:** Global app settings.

| Section        | Element                                              | Status         |
| -------------- | ---------------------------------------------------- | -------------- |
| **Language**   | AlertDialog radio uk/en                              | ✅              |
| **Appearance** | Theme — SegmentedButton (System/Light/Dark)          | ✅              |
| **Appearance** | Units of Measurement → `/settings/units`             | ✅              |
| **Ballistics** | Adjustment Display → `/settings/adjustment`          | ✅              |
| **Ballistics** | Subsonic transition switch                           | ✅              |
| **Ballistics** | Table distance step (dialog)                         | ✅              |
| **Ballistics** | Chart distance step (dialog)                         | ✅              |
| **Data**       | Export backup / Import backup (.ebcp, full data)     | ✅              |
| **About**      | Version, GitHub link                                 | ✅              |
| **About**      | Privacy Policy / Terms of Use / Changelog links      | ⏳ stub         |

---

## 5. Additional Screens & Components

---

### 5.1 Shot Details Screen ✅

> Opened from **Shot details** button on Home.

Full read-only list of current shot parameters. Sections: Velocity, Energy, Stability (Miller Sg), Trajectory. All values unit-aware via `ShotDetailsViewModel`.

---

### 5.2 Reticle Fullscreen Screen ⏳

> Opened from the small reticle preview on Home → Page 1.

Full-screen display of the scope reticle with calculated adjustments. Details TBD. Depends on `RETICLES_AND_IMAGES.md`.

---

### 5.3 Tools Screen ⏳

> Opened from **More** button on Home. Currently `showNotAvailableSnackBar`.

Post-Alpha. Composition TBD.

---

### 5.4 Help Overlay ⏳

> Opened from **Help** button on Home.

All-in-one overlay that simultaneously highlights all key UI elements. Post-Alpha.

---

### 5.5 Value Input Widgets ✅

**SpinBox Selector** (`showUnitEditDialog`): `[−] field [+]` modal dialog. POS-terminal digit input. Used by `UnitValueField`, `QuickActionsPanel`, `TempControl`. ✅

**RulerSelector** ⏳ (Post-Alpha): touch-drag ruler for QuickActionsPanel replacement.

---

### 5.6 Units Screen ✅ (`/settings/units`)

11 unit categories, each with inline chip selector. Full list in `UnitSettings`.

---

### 5.7 Adjustment Display Screen ✅ (`/settings/adjustment`)

`AdjustmentFormat` SegmentedButton + 5 unit switches (MRAD/MOA/MIL/cm/in).

---

### 5.8 Profiles Screen ✅ (`/home/profiles`)

`PageView` of `ProfileCard` widgets. FAB → Add flow (new / from collection / import). Per-card: Duplicate, Export (.ebcp/.a7p), Rename, Remove. Active profile is page 0.

**ProfileCard layout:**
- `_ProfileControlTile`: sight FAB (top-left) + ammo FAB (bottom-right)
- Weapon section (tap → WeaponWizardScreen)
- Ammo section (tap → AmmoWizardScreen, if selected)
- Sight section (tap → SightWizardScreen, if selected)
- Select / Go to calc button (if ammo + sight selected)

---

### 5.9 Wizard Screens ✅

| Screen                  | File                              | Notes |
| ----------------------- | --------------------------------- | ----- |
| `WeaponWizardScreen`    | `weapon_wizard_screen.dart`       | name, caliber, twist, barrelLength; caliber readonly from collection |
| `AmmoWizardScreen`      | `ammo_wizard_screen.dart`         | Full: drag model, BC table, MV, powder sens, zero conditions, coriolis |
| `SightWizardScreen`     | `sight_wizard_screen.dart`        | name, height, clicks, magnification, focal plane |
| `MultiBcEditorScreen`   | `multi_bc_editor_screen.dart`     | G1/G7 table (5 rows, sort desc by V) |
| `CustomDragTableEditor` | `multi_bc_editor_screen.dart`     | 100 rows, readOnly default |
| `PowderSensTableEditor` | `powder_sens_table_editor_screen` | T→V table (5 rows), auto-calc coefficient |

---

### 5.10 Collection Screens ✅

`WeaponCollectionScreen`, `AmmoCollectionScreen` (cartridge/bullet, caliber filter), `SightCollectionScreen`.

---

### 5.11 Table Configuration Screen ✅ (`/tables/configure`)

Range, step, showZeros, spoiler section switches (20+ toggles), column visibility (11 columns), drop/adj unit overrides, start < end validation.

---

### 5.12 Convertor Screens

Each convertor screen shows multiple output fields simultaneously with real-time recalculation. Input unit is selectable via chip/segment. State persisted per-convertor in `ConvertorsState` (ObjectBox).

**VelocityConvertorScreen:** mps / km·h / fps / mph / Mach input; Mach uses ICAO or custom atmosphere (temperature, pressure, humidity, altitude). ✅

**DistanceConvertorScreen:** ⏳ stub — to be implemented.

**Other screens** (Length, Weight, Pressure, Temperature, MIL/MOA, Torque): ✅ implemented.

---

### 5.13 Wind Direction Wheel ✅

Step from FC `windDirection` role. Pan + tap + double-tap reset.

### 5.14 Shot Details — Gyrostability ✅

GSF shown in Shot Details screen and as info row on Home Page 1.

---

## 6. State Architecture

### 6.1 Layer Diagram

```
┌─────────────────────────────────────────┐
│           UI (screens / widgets)         │
│    ref.watch(xxxVmProvider)              │
├─────────────────────────────────────────┤
│           ViewModels                     │
│  HomeViewModel · ConditionsViewModel     │
│  TablesViewModel · ShotDetailsViewModel  │
│  (sealed UiState classes, formatted)     │
├─────────────────────────────────────────┤
│        Formatting                        │
│  UnitFormatter · UnitFormatterImpl       │
│  (Dimension/double → String)             │
├─────────────────────────────────────────┤
│           Riverpod providers             │
│  AppStateNotifier · SettingsNotifier     │
│  ShotConditionsNotifier · RecalcCoord.   │
│  ConvertorsNotifier                      │
├─────────────────────────────────────────┤
│         Domain / Services                │
│  BallisticsService (interface)           │
│  BallisticsServiceImpl (FFI bridge)      │
│  EbcpService · A7pService               │
├─────────────────────────────────────────┤
│           ObjectBox Entities             │
│  Owner · Profile · Weapon · Ammo · Sight │
│  GeneralSettings · UnitSettings          │
│  TablesSettings · ShootingConditions     │
│  ConvertorsState                         │
├─────────────────────────────────────────┤
│     Extension Getters/Setters            │
│  lib/core/extensions/*.dart              │
│  (typed access over raw DB fields)       │
├─────────────────────────────────────────┤
│              FFI / C++                   │
│         bclibc ballistics engine         │
└─────────────────────────────────────────┘
```

### 6.2 Unit System

`packages/bclibc_ffi` provides: per-dimension enums (`DistanceUnit`, `VelocityUnit`, `TemperatureUnit`, etc.), `Dimension<T,U>` base class, concrete `Distance`, `Velocity`, `Temperature`, `Pressure`, `Angular`, `Weight`, `Energy`, `Ratio`, `Atmo` classes. FFI enums are proper Dart enums (generated by ffigen ^20).

`Unit` enum (in `unit.dart`) maps all units with conversion factors; `Unit.mach` included (ICAO constant). Atmosphere-aware mach conversions via `VelocityMachExtension` in `conditions.dart`.

### 6.3 ObjectBox Entities

All persisted data lives in `packages/ebalistyka_db`. Entities:

```
Owner (singleton, token="local")
  ├── Weapon[]         caliber, twist, barrelLength, zeroElevation, image
  ├── Ammo[]           mv, mvTemperature, BC/drag, powder sensitivity, zero conditions
  ├── Sight[]          height, clicks, focal plane, reticleImage, magnification
  ├── Profile[]        ToOne<Weapon>, ToOne<Ammo>, ToOne<Sight>, sortOrder
  ├── GeneralSettings  theme, language, adjustment display, dist/chart steps
  ├── UnitSettings     11 unit categories
  ├── TablesSettings   range, step, visible columns, spoiler sections
  ├── ShootingConditions  atmo, wind, powder temp, coriolis, target distance
  └── ConvertorsState  per-convertor value + unit + mach atmo state
```

**Extension files** (typed getters/setters — never access raw DB fields directly):
- `lib/core/extensions/weapon_extensions.dart`
- `lib/core/extensions/ammo_extensions.dart`
- `lib/core/extensions/sight_extensions.dart`
- `lib/core/extensions/profile_extensions.dart`
- `lib/core/extensions/conditions_extensions.dart`
- `lib/core/extensions/settings_extensions.dart`
- `lib/core/extensions/convertors_extensions.dart`

### 6.4 Riverpod Providers

#### Core / storage

| Provider                    | Purpose                                              |
| --------------------------- | ---------------------------------------------------- |
| `storeProvider`             | ObjectBox Store singleton                            |
| `ownerProvider`             | Owner entity (token="local"), creates if missing     |
| `appStateProvider`          | Main aggregate: all entities; OB stream; seed        |
| `cartridgesProvider`        | selector → `List<Ammo>`                              |
| `sightsProvider`            | selector → `List<Sight>`                             |
| `weaponsProvider`           | selector → `List<Weapon>`                            |

#### Settings & conditions

| Provider                    | Purpose                                              |
| --------------------------- | ---------------------------------------------------- |
| `settingsProvider`          | `GeneralSettings` (OB stream)                        |
| `unitSettingsProvider`      | `UnitSettings` (sync selector)                       |
| `themeModeProvider`         | `ThemeMode` (sync selector)                          |
| `tablesSettingsProvider`    | `TablesSettings` (OB stream)                         |
| `shotConditionsProvider`    | `ShootingConditions` (OB stream)                     |

#### Profiles

| Provider                    | Purpose                                              |
| --------------------------- | ---------------------------------------------------- |
| `profilesPagingProvider`    | Sync — ordered IDs + activeId; paging only           |
| `profileCardProvider(id)`   | Family — card data (fingerprints); rebuild per card  |
| `profilesActionsProvider`   | Actions: select/create/rename/duplicate/remove       |

#### Shot context & calculation

| Provider                    | Purpose                                              |
| --------------------------- | ---------------------------------------------------- |
| `shotContextProvider`       | `ShotContext { profile, conditions }` — for VMs      |
| `recalcCoordinatorProvider` | Centralises recalc triggers (profile/settings/tabs)  |
| `homeVmProvider`            | `HomeUiState` (sealed: Loading/Ready/Error)          |
| `conditionsVmProvider`      | `ConditionsUiState`                                  |
| `tablesVmProvider`          | `TablesUiState` (sealed)                             |
| `shotDetailsVmProvider`     | `ShotDetailsUiState` (sealed)                        |
| `ballisticsServiceProvider` | FFI-backed `BallisticsService`                       |
| `unitFormatterProvider`     | `UnitFormatter` (depends on `unitSettingsProvider`)  |

#### Convertors

| Provider                    | Purpose                                              |
| --------------------------- | ---------------------------------------------------- |
| `convertorsProvider`        | `ConvertorsState` (OB stream)                        |
| `convertorStateProvider`    | Sync selector (defaults while loading)               |
| `velocityConvertorVmProvider` etc. | Per-convertor ViewModels                     |

#### SVG / Assets

| Provider                    | Purpose                                              |
| --------------------------- | ---------------------------------------------------- |
| `reticleSvgProvider(id)`    | Loads SVG from `assets/svg/reticles/`                |
| `weaponSvgProvider(id)`     | Loads SVG from `assets/svg/weapon/`                  |
| `ammoSvgProvider(id)`       | Loads SVG from `assets/svg/ammo/`                    |
| `reticleListProvider`       | All reticle IDs from asset manifest                  |
| `builtinCollectionProvider` | Lazy-loaded `collection.json`                        |

### 6.5 Storage

ObjectBox database at `~/.eBalistyka/objectbox/`. Single transaction for all CRUD. No JsonFileStorage.

**Export formats:**
- `.ebcp` — JSON + CBOR archive (native). `EbcpService` in `lib/core/services/ebcp_service.dart`.
- `.a7p` — Protobuf (Archer / A-TACS compatible). `A7pService` in `lib/core/services/a7p_service.dart`. Library: `packages/a7p`.

---

## 7. Open Questions

| #   | Question                                                         | Status            |
| --- | ---------------------------------------------------------------- | ----------------- |
| 1   | Table export format: PDF or HTML?                                | ✅ HTML (implemented) |
| 2   | Reticle fullscreen — static or interactive?                      | ⏳ TBD             |
| 3   | Localizations: UK + EN only or more?                             | ⏳ UK + EN for now |
| 4   | Weapon/Sight/Ammo `image` field format (entity images)           | ⏳ TBD (file / base64 / asset) |
| 5   | `DistanceConvertorScreen` — same multi-field pattern as others?  | ⏳ TBD             |

---

## 8. Current Codebase Status

### 8.1 Implemented ✅

#### Infrastructure & packages

| Area | Notes |
| ---- | ----- |
| **App name / Bundle ID** | `eBalistyka` · `com.ballistics.ebalistyka` — all platforms |
| **bclibc submodule** | `external/bclibc`; FFI via `packages/bclibc_ffi` |
| **bclibc_ffi package** | Per-dimension enums, `Dimension<T,U>`, `Atmo`, `Unit.mach`, mach extensions; ffigen ^20 |
| **ebalistyka_db package** | ObjectBox entities + codegen; `EbcpFile` + export DTOs; `json_serializable` |
| **a7p package** | `A7pFile`, `A7pConverter`, `A7pValidator`; proto schema |
| **reticle_gen package** | CLI SVG generator; `CanvasInterface`, `SVGCanvas`, `MilReticleCanvas`; partial |
| **ObjectBox storage** | Single `Store`; stream-based reactive updates; `storeProvider` + `ownerProvider` |
| **Feature-first structure** | `lib/features/`, `lib/core/`, `lib/shared/`, `lib/main.dart`, `lib/router.dart` |
| **Navigation** | GoRouter + StatefulShellRoute; all routes; tab switch resets branch stack |
| **BallisticsService** | Interface + FFI-backed impl; zero-elevation caching (`_buildZeroKey`) |
| **UnitFormatter** | Pure-Dart formatter; 57+ tests |

#### Screens

| Screen | Status | Notes |
| ------ | ------ | ----- |
| Home (top block) | ✅ | Profile selector FAB, wind wheel, side controls, quick actions |
| Home — Page 1 (Reticle) | ✅ | SVG reticle + color roles + correction dot + AdjPanel |
| Home — Page 2 (Table) | ✅ | 5-col compact table, 11 rows, FC-based accuracy |
| Home — Page 3 (Chart) | ✅ | Dual-curve chart, tap/pan snap, info grid |
| Conditions | ✅ | All fields, all switches, powder sensitivity full flow |
| Tables | ✅ | Frozen header, zero-crossings, detail dialog, spoiler, HTML export |
| Tables → Configure | ✅ | Range/step, 20+ toggles, 11 columns, unit overrides |
| Settings | ✅ | Theme, language, steps, export/import backup |
| Settings → Units | ✅ | 11 categories |
| Settings → Adjustment Display | ✅ | Format + 5 switches |
| Convertors grid | ✅ | 8-tile responsive grid |
| Convertors → Velocity | ✅ | mps/kmh/fps/mph/Mach; custom atmosphere for Mach |
| Convertors → Length | ✅ | |
| Convertors → Weight | ✅ | |
| Convertors → Pressure | ✅ | |
| Convertors → Temperature | ✅ | |
| Convertors → MIL/MOA | ✅ | |
| Convertors → Torque | ✅ | |
| Convertors → Distance | ⏳ | stub |
| Shot Details | ✅ | 4 sections via `ShotDetailsViewModel` |
| ProfilesScreen | ✅ | PageView, paging, FAB, per-card callbacks, export/import |
| WeaponWizardScreen | ✅ | Caliber readonly from collection; required highlighting |
| AmmoWizardScreen | ✅ | Full: drag model, BC/custom table, MV, powder sens, zero cond, coriolis |
| SightWizardScreen | ✅ | height, clicks, focal plane, magnification |
| MultiBcEditorScreen | ✅ | G1/G7 (5 rows, sort desc by V) + CustomDragTable (100 rows) |
| PowderSensTableEditorScreen | ✅ | T→V (5 rows), pairwise algorithm, auto-fills row 0 from wizard |
| WeaponCollectionScreen | ✅ | |
| AmmoCollectionScreen | ✅ | cartridge/bullet filter + caliber filter (tolerance 0.001") |
| SightCollectionScreen | ✅ | |
| MyAmmoScreen | ✅ | |
| MySightsScreen | ✅ | |

#### Widgets & services

| Item | Status |
| ---- | ------ |
| `TrajectoryTable` | ✅ Sticky header, h-scroll sync, FC accuracy, subsonic highlight |
| `TrajectoryChart` | ✅ CustomPainter, dual axis, subsonic line, tap/pan snap |
| `WindIndicator` | ✅ Pan + tap + double-tap reset |
| `QuickActionsPanel` | ✅ Wind speed, look angle, target distance |
| `SvgAssetView` | ✅ Color role resolution, `AsyncValue<String>` |
| `WeaponSvgView` / `AmmoSvgView` | ✅ |
| `ProfileCard` | ✅ fingerprint-based rebuild, ammo/sight FABs |
| `PowderSensSection` | ✅ Reusable (wizard + conditions modes) |
| `CoriolisSection` | ✅ |
| `EbcpService` | ✅ share, pick, buildFullExport, restoreFromExport |
| `A7pService` | ✅ share, pick, auto-detect format |
| `table_html_exporter` | ✅ |

#### A7P

| Item | Status |
| ---- | ------ |
| `packages/a7p` | ✅ `A7pFile`, `A7pConverter`, `A7pValidator` |
| Proto schema | ✅ `packages/a7p/proto/profedit.proto` |
| A7P import UI | ✅ FilePicker → auto-detect → import |
| A7P export UI | ✅ Per-profile export sheet (.ebcp / .a7p) |

---

### 8.2 Pending ⚠️

#### 🔴 Alpha blocker

| Area | Notes |
| ---- | ----- |
| **DistanceConvertorScreen** | Currently stub; implement per ALPHA_UX.md |

#### 🟠 Post-Alpha medium

| Area | Notes |
| ---- | ----- |
| Reticle fullscreen view | Opens from Home Page 1 reticle tap; spec TBD |
| Tools Screen | Opened from Home "More" button; composition TBD |
| Help Overlay | Coach marks; library TBD |
| RulerSelector widget | Touch-drag ruler for QuickActionsPanel |

#### 🔵 Post-Alpha lower

| Area | Notes |
| ---- | ----- |
| Localization uk/en | ARB + flutter_localizations |
| Settings → Legal links | Privacy Policy, Terms of Use, Changelog |
| Remaining SVG reticles | Generate all IDs via `reticle_gen` |
| Entity images (Weapon/Sight/Ammo) | Format TBD (file / base64 / asset) |
| iOS C++ library bundling | `.a` static lib in Xcode |

---

## 9. Implementation Phases

### Phases 1–5 ✅ — Foundation

Domain models, storage, providers, navigation. **Done.**

---

### Architecture Refactoring ✅ (REFACTORING_PLAN.md — Doc #1)

Full MVVM + service layer (5 phases):
- Phase 0: `UnitFormatter` interface + impl (57 tests)
- Phase 1: `BallisticsService` + FFI impl
- Phase 2: `HomeVM`, `ConditionsVM`, `TablesVM` (70 tests)
- Phase 3: `RecalcCoordinator` (18 tests)
- Phase 4: Screens wired to ViewModels
- Phase 5: Cleanup — deleted `dimension_converter.dart`, `calculation_provider.dart`

---

### Post-Refactoring Improvements ✅ (REFACTORING_PLAN_2.md — Doc #2)

- Phase 1: Feature-first directory restructure (72 files moved, 244 tests pass)
- Phase 2: `ShotDetailsViewModel` — legacy provider eliminated
- Phase 3: FFI enum wrappers — resolved by Phase 4
- Phase 4: ffigen ^20 update — proper Dart enums generated
- Phase 5: Strict dimension typing — per-dimension enums, `Dimension<T,U>` parameterized

---

### ObjectBox Migration ✅ (OBJECTBOX_MIGRATION.md — Doc #3)

All steps complete. ObjectBox is sole storage layer. `JsonFileStorage` deleted.

---

### Profiles CRUD ✅ (PROFILES_CRUD_PLAN.md — Doc #4)

All wizard screens, collection screens, selection flows, export/import (ebcp + a7p), full backup, reactive paging with fingerprint-based card rebuilds. **Done.**

---

### Phase 5.5 — Value Input Widgets ✅

`showUnitEditDialog()` (`[−] field [+]` + validation). `SpinBoxSelector` = this dialog. RulerSelector pending (Post-Alpha).

---

### Phase 6 ✅ — Home Screen Bottom Block

All three pages. Extracted to `home_reticle_page.dart`, `home_table_page.dart`, `home_chart_page.dart`.

---

### Phase 7 ✅ — Conditions Screen

All fields + switches + powder sensitivity full flow.

---

### Phase 8 ✅ — Tables Screen

Frozen header, zero-crossings, row detail dialog, details spoiler, `TableConfig` screen. HTML export connected.

---

### Phase 9 — Convertors ✅ (7/8)

Grid ✅. 7 individual convertor screens ✅. `DistanceConvertorScreen` ⏳ — last alpha blocker.

---

### Phase 10 ✅ — Settings Screen

Theme, language, steps, units (11 categories), Adjustment Display, export/import backup, GitHub link.

---

### Phase 11 ✅ — Rifle / Cartridge / Sight Selection

All 7 screens implemented. Weapon, Ammo (with all sub-editors), Sight wizards + collection screens.

---

### Phase A7P ✅ — .a7p File Support

`packages/a7p` complete. Import/export UI done. `A7pService` wired.

---

### Reticles & Images 🔄 (RETICLES_AND_IMAGES.md — Doc #5)

SVG display, color-role resolution, correction dot injection: ✅  
`reticle_gen` CLI: partial (default + MIL-XT done).  
Fullscreen reticle view: pending.

---

### Alpha UX 🔄 (ALPHA_UX.md — Doc #6)

One remaining item: `DistanceConvertorScreen`.

---

### Phase 12 — Home Note / Help / More buttons ⏳

After alpha. All three stubs.

---

### Phase 13 — Post-Alpha Polish ⏳

- Localization uk/en
- Legal links (Privacy, Terms, Changelog)
- RulerSelector widget
- Reticle fullscreen view
- Help Overlay
- Tools Screen
- iOS C++ bundling

---

## 10. Dependencies

### In use

```yaml
flutter_riverpod:
go_router:
ffi:
objectbox: ^4.0.0
objectbox_flutter_libs: ^4.0.0
protobuf: ^6.0.0
uuid: ^4.0.0
path_provider: ^2.1.0
window_manager:
sticky_headers:
crypto: ^3.0.3
file_picker:
share_plus:
archive:
flutter_svg:
json_serializable:
json_annotation:
build_runner:              # dev
objectbox_generator:       # dev
ffigen: ^20.0.0            # dev (packages/bclibc_ffi)
```

### Internal packages

```
packages/bclibc_ffi    — FFI wrapper + Unit/Dimension system
packages/ebalistyka_db — ObjectBox entities + export DTOs
packages/a7p           — A7P format (encode/decode/validate/convert)
packages/reticle_gen   — SVG reticle generator CLI
```

### protoc toolchain (dev)

```bash
dart pub global activate protoc_plugin
# then: protoc --dart_out=packages/a7p/lib/src/proto packages/a7p/proto/profedit.proto
# or: make proto-a7p
```

---

## 11. Execution Order

```
Phase 1–5       ✅  Foundation
Phase 10        ✅  Settings
Phase 7         ✅  Conditions Screen
Phase 8         ✅  Tables Screen + Configure
Phase 5.5       ✅  QuickActionsPanel MVP (showUnitEditDialog)
Phase 6         ✅  Home Screen bottom block (3 pages)
Refactor        ✅  REFACTORING_PLAN (Phases 0–5): MVVM + UnitFormatter + BallisticsService
Refactor 2      ✅  REFACTORING_PLAN_2 (Phases 1–5): feature-first, ShotDetailsVM, FFI enums, dim typing
ObjectBox       ✅  OBJECTBOX_MIGRATION: JsonFileStorage → ObjectBox; all extensions
Phase A7P       ✅  packages/a7p + A7pService + import/export UI
Phase 11        ✅  All wizard screens (Weapon/Ammo/Sight) + collection screens + ProfilesScreen
Reticles        ✅  SVG display + color roles + correction dot (HomeReticlePage)
Convertors      ✅  7/8 individual convertor screens implemented

─── Alpha Blockers ───
DistanceConvtr  ⏳  DistanceConvertorScreen — implement (6.ALPHA_UX.md)

─── Post-Alpha ───
Phase 9.last    ⏳  DistanceConvertorScreen → marks alpha complete
Phase 12        ⏳  Home Note / Help / More buttons
Reticles cont.  ⏳  Fullscreen reticle view; remaining SVG reticles via reticle_gen
Phase 13        ⏳  Localization, RulerSelector, Help overlay, Tools screen, Legal links, iOS bundling
```
