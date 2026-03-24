# eBallistica — Master Project Document

**Version:** 1.1
**Status:** Working Document
**Stack:** Flutter · Dart · Riverpod · FFI (bclibc C++)

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
| **Home**       | → Rifle Selection → (Sight / Cartridge / Library / Create) |
| **Home**       | → Projectile Selection → (Library / Create)                |
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
│   ├── /home/rifle-select
│   │   ├── /home/rifle-select/rifle-edit
│   │   ├── /home/rifle-select/sight-select
│   │   └── /home/rifle-select/cartridge
│   │       └── /home/rifle-select/cartridge/edit
│   ├── /home/projectile-select
│   │   └── /home/projectile-select/edit
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
| Rifle selection button      | Opens Rifle Selection screen (stack push)      |
| Projectile selection button | Opens Projectile Selection screen (stack push) |

**Navigation buttons:**

| Element             | Action                                          |
| ------------------- | ----------------------------------------------- |
| Shot details button | Pushes Info screen                              |
| New note button     | Creates a note for the shot (stub → Phase 12)   |
| Help button         | Shows all-in-one help overlay (stub → Phase 12) |
| More button         | Pushes Tools screen (stub → Phase 12)           |

**Read-only indicators** (values from Conditions screen):

| Element          | Value               |
| ---------------- | ------------------- |
| Temperature sign | Current temperature |
| Altitude sign    | Current altitude    |
| Humidity sign    | Current humidity    |
| Pressure sign    | Current pressure    |

**Wind Direction Wheel:** Interactive element for selecting wind direction. Displays current direction. Double-tap resets to 0°.

**Quick action buttons** (each opens a ruler-like selector overlay):

| Button          | Parameter              |
| --------------- | ---------------------- |
| Wind speed      | Wind velocity          |
| Look angle      | Shot inclination angle |
| Target distance | Distance to target     |

#### 4.1.2 Block: Current Shot Data — 3 Pages

Switched by swipe.

**Page 1: Reticle + Adjustments**

```
┌──────────────────────────────────────┐
│  [reticle placeholder]  │  ↑ 2.34   │
│                         │  MIL      │
│                         │  0.98 MOA │
│                         │  ─────────│
│                         │  → 0.12   │
│                         │  MIL      │
└──────────────────────────────────────┘
```

- Left half: rounded square placeholder for future reticle widget
- Right half: two rows (drop / windage), each showing adjustment value in multiple units (cm/100m, in/100yd, MOA, MIL, MRAD) based on Adjustment Display settings
- Data source: `calculationProvider` → `HitResult.getAtDistance(targetDistance)` → `dropAngle`, `windageAngle`

**Page 2: Adjustment Tables**

Vertically scrollable set of compact tables. Each table: header row with distances (target ± 2 steps), value row. Tables:

| Table         | Unit               |
| ------------- | ------------------ |
| Height        | `units.drop`       |
| Slant Height  | `units.drop`       |
| Drop angle    | `units.adjustment` |
| Windage angle | `units.adjustment` |
| Velocity      | `units.velocity`   |
| Energy        | `units.energy`     |
| Time          | seconds            |

**Page 3: Trajectory Chart**

- Above chart: info grid with currently selected point values
  - Left column: Trajectory label, Velocity, Energy, Time
  - Right column: Height, Drop, Windage, Distance
- Chart: trajectory curve + velocity curve only (no barrel/sight lines)
- Default selected point: start of trajectory
- Pan on chart → highlights nearest point, updates info grid above
- Axis labels removed; numeric tick labels only, right-aligned to chart edges
---

### 4.2 Conditions Screen

> **Purpose:** Input and editing of environmental parameters.

**Input fields** (units from `unitSettingsProvider`):

Layout per field: `[−]  value  unit  [+]` — the +/− buttons are adjacent to the value, not at the edges of the row. Tapping the value itself opens a keyboard dialog for direct numeric entry.

| Parameter   | Unit                |
| ----------- | ------------------- |
| Temperature | `units.temperature` |
| Altitude    | `units.distance`    |
| Humidity    | %                   |
| Pressure    | `units.pressure`    |

**Switches** (read/write `AppSettings` via `SettingsNotifier`):

| Switch                                        | Note                                                            |
| --------------------------------------------- | --------------------------------------------------------------- |
| Coriolis effect                               |                                                                 |
| Powder temperature sensitivity                | When ON — reveals sub-switch + readonly fields (see below)      |
| ↳ Use different powder temperature            | Sub-switch; when ON — shows editable `Powder temperature` field |
| ↳ *(readonly)* Muzzle velocity at powder temp | Calculated via `Ammo.getVelocityForTemp(currentPowderTemp)`     |
| ↳ *(readonly)* Powder sensitivity             | `Cartridge.tempModifier` formatted as `%/15°C`                  |
| Derivation                                    |                                                                 |
| Aerodynamic jump                              | Always ON, control disabled (engine limitation)                 |
| Pressure depends on altitude                  | Always ON, control disabled (engine limitation)                 |

Powder temperature field appears in the **switch section** (not atmospheric fields), below the sub-switch, only when `useDifferentPowderTemperature` is ON.

---

### 4.3 Tables Screen

> **Purpose:** Full trajectory table for the current shot.

Layout (top to bottom):

| Element                   | Description                                                                |
| ------------------------- | -------------------------------------------------------------------------- |
| **Header**                | Back button, "Tables" title, Configure + Export buttons                    |
| **Spoiler / accordion**   | Collapsible panel: rifle, cartridge, sight, atmospheric conditions summary |
| **Zero crossing table**   | Small table showing zero-crossing points (from `HitResult.zeros`)          |
| **Full trajectory table** | Complete trajectory for all distances; zero-distance row highlighted       |
| **Configure button**      | Pushes `/tables/configure`                                                 |
| **Export / Share button** | Exports table via share sheet (PDF or HTML, TBD)                           |

All values that has no overloads in table configuration - FC-based
Should use a behaviour from it's configuration for step start/end, not from app settings 

---

### 4.4 Convertors Screen

> **Purpose:** Collection of unit converters. Sub-screens are placeholders for now.

**Layout:** Responsive scrollable grid — tile count per row adapts to screen width (`SliverGrid.extent` with `maxCrossAxisExtent ≈ 160 dp`). Each tile — square card with rounded corners, large icon, name below.

**Converters (8 total):**

| #   | Route type        | Name                  |
| --- | ----------------- | --------------------- |
| 1   | `target-distance` | Target Distance       |
| 2   | `velocity`        | Velocity              |
| 3   | `length`          | Length                |
| 4   | `weight`          | Weight                |
| 5   | `pressure`        | Pressure              |
| 6   | `temperature`     | Temperature           |
| 7   | `mil-moa`         | MIL / MOA at Distance |
| 8   | `torque`          | Torque                |

---

### 4.5 Settings Screen

> **Purpose:** Global app settings.

| Section        | Element                                              | Status         |
| -------------- | ---------------------------------------------------- | -------------- |
| **Language**   | Tap → AlertDialog radio uk/en, calls `setLanguage()` | ✅              |
| **Appearance** | Theme — SegmentedButton (System/Light/Dark)          | ✅              |
| **Appearance** | Units of Measurement → `/settings/units`             | ✅              |
| **Ballistics** | Adjustment Display → `/settings/adjustment`          | ✅              |
| **Ballistics** | Subsonic transition switch                           | ✅              |
| **Ballistics** | Table distance step (dialog)                         | ✅              | Affects Home bottom block Page 2 only. Tables screen will have its own per-screen step setting. |
| **Ballistics** | Chart distance step (dialog)                         | ✅              |
| **Data**       | Export / Import buttons                              | ⏳ stub         |
| **About**      | Version, links (GitHub, Privacy, Terms, Changelog)   | ✅ (links stub) |

---

## 5. Additional Screens & Components

---

### 5.1 Info Screen

> Opened from **Shot details** button on Home.

Full read-only list of all current shot parameters (`ShotProfile`). No editing.

---

### 5.2 Reticle Screen

> Opened from the small reticle preview on Home → Page 1.

Full-screen display of the scope reticle with calculated adjustments overlaid. Details TBD.

---

### 5.3 Tools Screen

> Opened from **More** button on Home.

Contains at minimum three ruler-like selectors:

| Tool                     | Description                             |
| ------------------------ | --------------------------------------- |
| Wind speed selector      | Ruler-based wind speed selection        |
| Look angle selector      | Ruler-based inclination angle selection |
| Target distance selector | Ruler-based target distance selection   |

---

### 5.4 Help Overlay

> Opened from **Help** button on Home.

All-in-one overlay that **simultaneously highlights all** key UI elements with short labels. Not a step-by-step tour — everything shown at once.

Implementation: `Stack` + positioned coach mark widgets over `HomeScreen`.

---

### 5.5 Value Input Widgets (reusable)

Two reusable input patterns:

**Ruler Selector** (`lib/widgets/ruler_selector.dart`):
- Modal dialog/popup with vertical layout
- Float/int input field with POS-terminal-style behavior (digits enter from right)
- Touchable vertical ruler with tick marks; center tick = selected value
- Touch drag + keyboard input

**Spin Box Selector** (`lib/widgets/spin_box_selector.dart`):
- Modal dialog/popup
- Float/int input with POS-terminal-style behavior
- Up/Down buttons flanking the input field, change value by configured step

Reference implementations (TypeScript originals):
- `doubleSpinBox.tsx`, `valueDialog.tsx`, `ruler.tsx`, `numericField.tsx` in `ebalistyka-web`

Input accuracy logic follows the referenced components.

Used for: wind speed, look angle, target distance, conditions fields.

---

### 5.6 Units Screen (`/settings/units`)

> Opened from **Settings → Units of Measurement**.

List of unit categories, each with an inline chip/dropdown selector.

| Category             | Options                               |
| -------------------- | ------------------------------------- |
| Velocity             | fps / m/s                             |
| Distance             | meters / yards / feet                 |
| Sight height         | inches / cm                           |
| Pressure             | mmHg / inHg / hPa / PSI               |
| Temperature          | Celsius / Fahrenheit                  |
| Drop / Windage       | meters / feet / cm / inches           |
| Drop / Windage angle | MIL / MOA / MRAD / cm/100m / in/100yd |
| Energy               | joules / foot-pounds                  |
| Bullet weight        | grams / grains                        |
| OGW                  | pounds / kg                           |
| Bullet length        | mm / cm / inches                      |

---

### 5.7 Adjustment Display Screen (`/settings/adjustment`)

> Opened from **Settings → Adjustment Display**.

| Setting             | Options                           |
| ------------------- | --------------------------------- |
| Adjustment format   | Arrows ↑↓ / Signs +− / Letters UD |
| Show MRAD           | switch                            |
| Show MOA            | switch                            |
| Show MIL            | switch                            |
| Show cm/100m        | switch                            |
| Show in/100yd       | switch                            |
| Table distance step | (later)                           |
| Chart distance step | (later)                           |

Stored as flat fields directly in `AppSettings` (no nested model).

---

### 5.8 Rifle Selection Screen

> Opened from **Rifle selection** button on Home.

| Element                | Description                            |
| ---------------------- | -------------------------------------- |
| Library list           | Select existing rifle                  |
| Create manually button | Pushes Rifle Edit screen               |
| Sight selection        | Select or create a sight for the rifle |
| Cartridge button       | Pushes Cartridge screen                |

---

### 5.9 Projectile Selection Screen

> Opened from **Projectile selection** button on Home.

| Element                | Description                   |
| ---------------------- | ----------------------------- |
| Library list           | Select existing projectile    |
| Create manually button | Pushes Projectile Edit screen |

---

### 5.10 Cartridge Screen

Three actions on one screen:

| Element                    | Description                                   |
| -------------------------- | --------------------------------------------- |
| Select from library        | Replace current cartridge                     |
| Create manually            | Push Cartridge Edit screen                    |
| Current cartridge settings | Edit parameters of already selected cartridge |

---

### 5.11 Table Configuration Screen (`/tables/configure`)

> Opened from **Configure** button on Tables screen.

Configure visible columns and distance step for the trajectory table. Saved in `AppSettings`.

All values that has no overloads in table configuration - FC-based

* Start distance
* End distance
* Distance step
* Display two zeros switch - enables additional small table with 2 zero crossing points
* Details spoiler settings (check what to display):
    * Rifle section switch
      * Caliber switch
      * Twist switch
      * Twist direction switch
    * Projectile switch
      * Drag-Model type switch
      * BC switch
      * Zero Muzzle Velocity
      * Curr Muzzle Velocity
      * Zero Distance
      * Bullet len
      * Bullet diameter
      * Bullet Weight
      * Gyrostability
    * Sight section switch - for now adding to document not implementing
      * Scope? x1-x20????
      * Focal plane: FFC SFC LWIR switch
      * Reticle name switch
      * Hor click switch
      * Ver click switch
      * Hor click units switch
      * Ver click units switch
    * Atmosphere section switch
      * Curr Temperature
      * Curr Humidity
      * Curr Pressure
      * Wind speed
      * Wind direction

* Table columns section (switches check what to display):
    * Time
    * Range
    * Velocity
    * Height
    * Drop
    * Drop Adjustment
    * Windage
    * Windage Drop Adjustment
    * Display adjustment in current units or in all adjusment units checked? - will display column for each selected
    * Drop / Windage units (uses this, and not global)
    * Mach
    * Drag
    * Energy


---

### 5.12 Convertor Screen (`/convertors/:type`)

> Opened from any tile on Convertors screen.

Two input fields with keyboard + unit labels. Real-time recalculation using the existing `Unit`/`Dimension` system.

---

### 5.13

The wind direction wheel and value input should use step from the FC
So create special wind_direction FC role 

### 5.14

Shot details screen - add GSF (gyrostability) ✅

### 5.15

Home screen - Page 1 - add GSF to title after dragmodel ✅

## 6. State Architecture

### 6.1 Layer Diagram

```
┌─────────────────────────────────────────┐
│           UI (screens / widgets)         │
│    reads UnitSettings via Riverpod       │
│    passes explicit Unit to domain        │
├─────────────────────────────────────────┤
│           Riverpod providers             │
│  ShotProfileNotifier · SettingsNotifier  │
│  LibraryNotifier · CalculationNotifier   │
├─────────────────────────────────────────┤
│           Domain models                  │
│  Rifle · Sight · Cartridge · Projectile  │
│  Shot · Atmo · Wind · HitResult          │
│  (NO global unit state — explicit Unit)  │
├─────────────────────────────────────────┤
│           Infrastructure                 │
│  JsonFileStorage · ProfileSerializer     │
│  Calculator (FFI mapper)                 │
├─────────────────────────────────────────┤
│              FFI / C++                   │
│         bclibc ballistics engine         │
└─────────────────────────────────────────┘
```

### 6.2 Unit System

`PreferredUnits` removed from domain. Domain classes use explicit `Unit` parameters. UI reads units via `unitSettingsProvider`.

### 6.3 Domain Models

#### `UnitSettings` — `lib/src/models/unit_settings.dart`

```dart
class UnitSettings {
  final Unit velocity;      // fps / mps
  final Unit distance;      // meter / yard / foot
  final Unit sightHeight;   // inch / centimeter
  final Unit pressure;      // mmHg / inHg / hPa / psi
  final Unit temperature;   // celsius / fahrenheit
  final Unit drop;          // meter / foot / centimeter / inch
  final Unit adjustment;    // mil / moa / mrad / cmPer100m / inPer100yd
  final Unit energy;        // joule / footPound
  final Unit weight;        // gram / grain
  final Unit ogw;           // pound / kilogram
  final Unit length;        // millimeter / centimeter / inch
  // internal / less-visible
  final Unit angular;       // degree / radian / mil / moa
  final Unit diameter;      // inch
  final Unit twist;         // inch
  final Unit time;          // second
}
```

#### `AppSettings` — `lib/src/models/app_settings.dart`

Adjustment display fields added directly (no nested model):

```dart
enum AdjustmentFormat { arrows, signs, letters }

class AppSettings {
  final UnitSettings units;
  final String     languageCode;
  final ThemeMode  themeMode;
  final double     tableDistanceStep;
  final double     chartDistanceStep;
  final bool       showSubsonicTransition;
  final bool       enableCoriolis;
  final bool       enablePowderSensitivity;         // UI toggle — show/use powder sens
  final bool       useDifferentPowderTemperature;   // Use separate powder temp vs atmo temp
  final bool       enableDerivation;
  final bool       enableAerodynamicJump;
  final bool       pressureDependsOnAltitude;
  // Adjustment display (Phase 10.3)
  final AdjustmentFormat adjustmentFormat;  // ↑↓ / +− / UD
  final bool showMrad;
  final bool showMoa;
  final bool showMil;
  final bool showCmPer100m;
  final bool showInPer100yd;
}
```

#### `Cartridge` — `lib/src/models/cartridge.dart`

Stores ammunition + powder sensitivity data:

```dart
class Cartridge {
  final dynamic mv;                   // Velocity — reference MV (at powderTemp)
  final dynamic powderTemp;           // Temperature — reference powder temp for mv
  final double  tempModifier;         // Powder sensitivity coefficient (%/15°C)
  final bool    usePowderSensitivity; // Whether engine uses powder sensitivity
  // ...
}
```

`mv` is always the MV measured at `powderTemp`. To get MV at another temperature, use `Ammo.getVelocityForTemp(currentTemp)`.

#### `ShotProfile` — `lib/src/models/shot_profile.dart`

```dart
class ShotProfile {
  final String     id;
  final String     name;
  final Rifle      rifle;
  final Sight      sight;
  final Cartridge  cartridge;
  final Atmo       conditions;      // Current atmospheric conditions
  final Atmo?      zeroConditions;  // Atmo at time of zeroing; null → use conditions
  final Distance   zeroDistance;    // Distance at which zero was set (default 100 m)
  final Distance   targetDistance;  // Current target range (used by QuickActionsPanel)
  final List<Wind> winds;
  final Angular    lookAngle;
  final double?    latitudeDeg;
  final double?    azimuthDeg;

  Shot toShot();
}
```

`zeroConditions` is optional (null = use current `conditions`). `zeroDistance` is used by `calculation_provider.dart` instead of the previous hardcoded 100 m. `targetDistance` is the quick-action target range (default 300 m).

### 6.4 Riverpod Providers

| Provider                   | Type                                                          | Purpose                                                                        |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `settingsProvider`         | `AsyncNotifierProvider<SettingsNotifier, AppSettings>`        | All app settings                                                               |
| `unitSettingsProvider`     | `Provider<UnitSettings>`                                      | Sync unit access                                                               |
| `themeModeProvider`        | `Provider<ThemeMode>`                                         | Sync theme access                                                              |
| `shotProfileProvider`      | `AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>`     | Current shot profile                                                           |
| `tableCalculationProvider` | `AsyncNotifierProvider<TableCalculationNotifier, HitResult?>` | Lazy — zeroed at zeroDistance, full 2000 m, used by Tables screen              |
| `homeCalculationProvider`  | `AsyncNotifierProvider<HomeCalculationNotifier, HitResult?>`  | Lazy — shootTheTarget pattern, up to targetDist+chartStep, used by Home screen |
| `rifleLibraryProvider`     | `AsyncNotifierProvider`                                       | Rifle CRUD                                                                     |
| `cartridgeLibraryProvider` | `AsyncNotifierProvider`                                       | Cartridge CRUD                                                                 |
| `sightLibraryProvider`     | `AsyncNotifierProvider`                                       | Sight CRUD                                                                     |
| `appStorageProvider`       | `Provider<AppStorage>`                                        | Storage singleton                                                              |

**Calculation architecture:** Two separate lazy notifiers with `_dirty` flag. `build()` returns null immediately. `markDirty()` called on both from `_ScaffoldWithNavState` via `ref.listen(shotProfileProvider)` and `ref.listen(settingsProvider)`. `recalculateIfNeeded()` triggered on tab activation (Tables = tab 2, Home = tab 0). Both run in isolate via `compute()`.

**Two-phase calculation flow:**

*makeShot (tableCalculationProvider):*
```
Phase 1 — Zero
  atmo     = profile.zeroConditions ?? profile.conditions
  zeroShot = Shot(weapon, baseAmmo, lookAngle, atmo, winds=[])
  calc.setWeaponZero(zeroShot, profile.zeroDistance)
    → stores barrelElevationForTarget(zeroShot, zeroDistance) in weapon.zeroElevation
    → resets zeroShot.relativeAngle = 0

Phase 2 — Shot
  shot = Shot(weapon, shotAmmo, lookAngle, currentConditions, winds)
  // weapon.zeroElevation already set → shot.barrelElevation = zero angle
  hitResult = calc.fire(shot, 2000 m, tableStep)
```

*shootTheTarget (homeCalculationProvider):*
```
Phase 1 — Zero (same as above)
  calc.setWeaponZero(zeroShot, profile.zeroDistance)

Phase 2 — Hold
  newShot = Shot(weapon, shotAmmo, lookAngle, currentConditions, winds)
  targetElev = calc.barrelElevationForTarget(newShot, targetDistance)
  hold = targetElev - weapon.zeroElevation
  newShot.relativeAngle = hold

Phase 3 — Fire
  hitResult = calc.fire(newShot, targetDist + chartStep, chartStep)
  // trajectory arc crosses 0 at targetDistance
```

> Note: `zeroConditions` defaults to null in the seed (= use `conditions`). A dedicated Zero Conditions UI screen is pending (Phase 8.8 follow-up).

### 6.5 Storage

**Interface:** `lib/storage/app_storage.dart`
**Implementation:** `JsonFileStorage` — JSON files in app documents directory.

Export archive:
```
eballistica_backup.zip
├── settings.json
├── profile.json
├── rifles.json
├── cartridges.json
└── sights.json
```

---

## 7. Open Questions

| #   | Question                                                         | Status            |
| --- | ---------------------------------------------------------------- | ----------------- |
| 1   | Table export format: PDF or HTML?                                | ⏳ TBD             |
| 2   | Reticle screen — static or interactive?                          | ⏳ TBD             |
| 3   | Localizations: UK + EN only or more?                             | ⏳ UK + EN for now |
| 4   | cm/100m and in/100yd — are these `Unit` enum values or computed? | ⏳ TBD             |

---

## 8. Current Codebase Status

### 8.1 Implemented ✅

| Area                                            | File(s)                                                                                          | Notes                                                                                                                                                                                                    |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Solver**                                      | `src/solver/`                                                                                    | Full unit system, conditions, munition, drag tables, shot, trajectory, calculator, FFI                                                                                                                   |
| **Domain models**                               | `src/models/`                                                                                    | Rifle, Sight, Projectile, Cartridge, ShotProfile, AppSettings, UnitSettings, seed data                                                                                                                   |
| **Storage**                                     | `storage/`                                                                                       | AppStorage interface + JsonFileStorage                                                                                                                                                                   |
| **Providers**                                   | `providers/`                                                                                     | Settings, ShotProfile, Library, Calculation, Storage                                                                                                                                                     |
| **Navigation**                                  | `router.dart`                                                                                    | GoRouter with StatefulShellRoute, all routes; tab switch resets branch stack                                                                                                                             |
| **Main**                                        | `main.dart`                                                                                      | ProviderScope, MaterialApp.router, static ThemeData, themeModeProvider                                                                                                                                   |
| **Home screen — top block**                     | `screens/home_screen.dart`                                                                       | FAB selectors, wind wheel, SideControlBlock, QuickActionsPanel; min-height + SingleChildScrollView for small windows ✅                                                                                   |
| **Home screen — Page 1**                        | `screens/home_screen.dart`                                                                       | Reticle placeholder (CustomPainter) + Drop/Windage panel: section headers with direction indicator, values per enabled unit from AdjustmentDisplay settings; bullet/MV/drag info row at top ✅            |
| **Home screen — Page 2**                        | `screens/home_screen.dart`                                                                       | Compact single table: 7 rows (Height, Slant Ht, Drop, Windage, Velocity, Energy, Time) × 5 distance columns (target ± 2 steps); target column highlighted; FC-based accuracy; negative distances → '—' ✅ |
| **Home screen — Page 3**                        | `screens/home_screen.dart`                                                                       | Chart + info grid + tap/drag-to-select + page persistence ✅                                                                                                                                              |
| **Page dots indicator**                         | `screens/home_screen.dart`                                                                       | Animated pill dots below PageView ✅                                                                                                                                                                      |
| **Tables screen**                               | `screens/tables_screen.dart`                                                                     | Connected to `calculationProvider`, spinner, topbar, zero-row highlight                                                                                                                                  |
| **TrajectoryTable**                             | `widgets/trajectory_table.dart`                                                                  | `ConsumerWidget`; unit-aware columns via `UnitSettings`; FC-based accuracy for all columns ✅                                                                                                             |
| **TrajectoryChart**                             | `widgets/trajectory_chart.dart`                                                                  | CustomPainter, domain types                                                                                                                                                                              |
| **Settings screen**                             | `screens/settings_screen.dart`                                                                   | Theme, distance steps (unit-aware), language dialog; subsonic switch disabled (not implemented) ✅                                                                                                        |
| **`SectionHeader` widget**                      | `widgets/section_header.dart`                                                                    | Extracted reusable all-caps section header; used in Settings ✅                                                                                                                                           |
| **Settings → Units**                            | `screens/settings_sub_screens.dart`                                                              | All 10 categories, dialog picker, wired to `SettingsNotifier` ✅                                                                                                                                          |
| **Settings → Adjustment Display**               | `screens/settings_sub_screens.dart`                                                              | Format SegmentedButton + 5 switches, wired ✅                                                                                                                                                             |
| **`AppSettings`**                               | `src/models/app_settings.dart`                                                                   | `AdjustmentFormat` enum + 6 adjustment display fields ✅                                                                                                                                                  |
| **Wind indicator**                              | `widgets/wind_indicator.dart`                                                                    | Pan + tap + double-tap reset; commits on gesture end                                                                                                                                                     |
| **Conditions screen**                           | `screens/conditions_screen.dart`                                                                 | All fields connected to `ShotProfileNotifier`; `UnitValueField` for alt/humid/press; switches → `SettingsNotifier`; powder sens flow ✅                                                                   |
| **`UnitValueField`**                            | `widgets/unit_value_field.dart`                                                                  | `[icon label  value ✎]` tappable row; dialog delegated to `showUnitEditDialog()`; raw↔display via `Unit.call().in_()` ✅                                                                                  |
| **`showUnitEditDialog()`**                      | `widgets/unit_value_field.dart`                                                                  | Top-level function — reusable `[−] field [+]` dialog; used by `UnitValueField` and `QuickActionsPanel` ✅                                                                                                 |
| **`FieldConstraints` / `FC`**                   | `src/models/field_constraints.dart`                                                              | Per-role constraints (rawUnit, min, max, step, accuracy) for all physical quantities ✅                                                                                                                   |
| **`FC` display constraints**                    | `src/models/field_constraints.dart`                                                              | Added `drop`, `windage`, `adjustment`, `velocity`, `energy`, `distance` display-only entries ✅                                                                                                           |
| **`FieldConstraints.accuracyFor(Unit)`**        | `src/models/field_constraints.dart`                                                              | Computes decimal places dynamically from `stepRaw` converted to display unit — same logic as `UnitValueField` ✅                                                                                          |
| **`Weapon.zeroElevation` mutable**              | `src/solver/munition.dart`                                                                       | Changed from `final` to `var`; `setWeaponZero` now stores computed elevation in `weapon.zeroElevation` and resets `relativeAngle=0` — matches JS library behaviour ✅                                     |
| **`shootTheTarget` pattern**                    | `providers/calculation_provider.dart`                                                            | `_runHomeCalculation` uses `barrelElevationForTarget` + hold to produce arc crossing 0 at targetDistance ✅                                                                                               |
| **Two separate calculation providers**          | `providers/calculation_provider.dart`                                                            | `tableCalculationProvider` (zeroed at zeroDistance, full 2000 m) and `homeCalculationProvider` (shootTheTarget, up to targetDist + chartStep) ✅                                                          |
| **Chart improvements**                          | `widgets/trajectory_chart.dart`                                                                  | Axis labels removed; margins tightened; velocity axis scaled to actual min/max; `snapDistM` parameter for tap snapping; `rightAlign` text option ✅                                                       |
| **Drop/Windage supports meters**                | `screens/settings_sub_screens.dart`                                                              | `Unit.meter` added to Drop/Windage options in Settings → Units ✅                                                                                                                                         |
| **Settings change listener**                    | `router.dart`                                                                                    | Recalculates when `enablePowderSensitivity`, `useDifferentPowderTemperature`, or `chartDistanceStep` changes ✅                                                                                           |
| **`AppSettings.useDifferentPowderTemperature`** | `src/models/app_settings.dart`                                                                   | New field + serialization ✅                                                                                                                                                                              |
| **Powder sensitivity in calc**                  | `providers/calculation_provider.dart`                                                            | MV adjusted via `getVelocityForTemp()` based on settings ✅                                                                                                                                               |
| **`Atmo.powderTemp` bug fix**                   | `src/solver/conditions.dart`                                                                     | `powderTemperature` param was ignored; now correctly stored ✅                                                                                                                                            |
| **Phase 8.8 — `ShotProfile` zero fields**       | `src/models/shot_profile.dart`                                                                   | Added `zeroDistance`, `zeroConditions?`, `targetDistance`; full `copyWith`/`toJson`/`fromJson` ✅                                                                                                         |
| **Hardcoded 100 m removed**                     | `providers/calculation_provider.dart`                                                            | `setWeaponZero` now uses `profile.zeroDistance` ✅                                                                                                                                                        |
| **`ShotProfileNotifier` — new methods**         | `providers/shot_profile_provider.dart`                                                           | `updateZeroDistance`, `updateZeroConditions`, `updateTargetDistance` (fixed), `updateWindSpeed` ✅                                                                                                        |
| **Phase 5.5 MVP — QuickActionsPanel**           | `widgets/quick_actions_panel.dart`                                                               | `ConsumerWidget`; reads wind speed, look angle, target distance from providers; tap → `showUnitEditDialog()` ✅                                                                                           |
| **Hardcoded units — Home screen**               | `screens/home_screen.dart`                                                                       | temp/alt/press use `unitSettingsProvider` + dynamic symbol ✅                                                                                                                                             |
| **FC accuracy everywhere**                      | `widgets/quick_actions_panel.dart`, `trajectory_table.dart`                                      | All display values now use `FC.accuracyFor(unit)` — no hardcoded decimal places ✅                                                                                                                        |
| **`DragModelType` enum**                        | `src/models/projectile.dart`                                                                     | `g1 / g7 / custom` field on `Projectile`; serialized; seed data set to `g7` ✅                                                                                                                            |
| **Global scroll behavior**                      | `main.dart`                                                                                      | `_AppScrollBehavior` enables mouse/trackpad drag on all scrollables ✅                                                                                                                                    |
| **`showSubsonicTransition` disabled**           | `screens/settings_screen.dart`, `app_settings.dart`                                              | Switch shown as disabled + "Not yet implemented" subtitle; default changed to `false` ✅                                                                                                                  |
| **Subsonic transition implemented**             | `widgets/trajectory_table.dart`, `widgets/trajectory_chart.dart`, `screens/settings_screen.dart` | Table: first mach<1 row highlighted with tertiaryContainer; chart: vertical dashed tertiary line; setting switch wired ✅                                                                                 |
| **Powder sensitivity double-adjustment fix**    | `providers/calculation_provider.dart`                                                            | Removed pre-adjustment of MV; engine handles it via `getVelocityForTemp(atmo.powderTemp)` internally; pre-adjustment caused double correction ✅                                                          |
| **`_AdjPanel` overflow fix**                    | `screens/home_screen.dart`                                                                       | Wrapped Column in `FittedBox(fit: BoxFit.scaleDown)` + `mainAxisSize: min` to prevent 3.5 px bottom overflow ✅                                                                                           |
| **Home screen recalc spinner**                  | `screens/home_screen.dart`                                                                       | Dimmed overlay (`Colors.black α=90`) with centered `CircularProgressIndicator`; fades in → holds → fades out (~1 s) via `AnimationController` + `TweenSequence`; triggered by `ref.listen` on `homeCalculationProvider` loading→done transition; page position never reset ✅ |
| **`FC.distance` removed**                       | `src/models/field_constraints.dart`, all consumers                                               | Redundant `FC.distance` (0–5000 m) deleted; all 6 usages replaced with `FC.targetDistance` (10–3000 m) ✅                                                                                                |
| **TableConfig distance cross-validation**       | `screens/tables_sub_screens.dart`                                                                | Start distance capped at current `endM`; end distance floored at current `startM`; error message shows effective allowed range in display unit; both tiles use `FC.targetDistance` ✅                    |

### 8.2 Pending ⚠️

#### 🔴 Critical

| Area               | Status                                                              | Phase         |
| ------------------ | ------------------------------------------------------------------- | ------------- |
| Zero Conditions UI | `zeroConditions` field exists in model but no screen to edit it yet | 8.8 follow-up |

#### 🟡 Home Screen — Bottom Block

| Area                                       | Status                                                         | Phase |
| ------------------------------------------ | -------------------------------------------------------------- | ----- |
| Page 1 — Reticle placeholder               | ✅ Done — `_ReticleView` CustomPainter                          | 6     |
| Page 1 — Drop/Windage panel                | ✅ Done — `_AdjPanel` with direction indicators per unit        | 6     |
| Page 2 — Compact adjustment tables         | ✅ Done — `_PageTable` single table, FittedBox adaptive columns | 6     |
| Page 3 — Info grid above chart             | ✅ Done                                                         | 6     |
| Page 3 — Tap/drag-to-select point on chart | ✅ Done                                                         | 6     |

#### 🟡 Tables Screen

| Area                    | Status          | Phase |
| ----------------------- | --------------- | ----- |
| Frozen header           | ✅ Done         | 8.1   |
| Zero crossing table     | ✅ Done         | 8.2   |
| Row tap → detail dialog | ✅ Done         | 8.3   |
| Details spoiler         | ✅ Done         | 8.4   |
| Configure button        | ✅ Done         | 8.6   |
| Export button           | Stub            | 8.7   |

#### 🟠 Value Input Widgets

| Area              | Status                                                           | Phase |
| ----------------- | ---------------------------------------------------------------- | ----- |
| `RulerSelector`   | Not created (QuickActionsPanel uses `showUnitEditDialog` as MVP) | 5.5   |
| `SpinBoxSelector` | Not created                                                      | 5.5   |

#### 🟠 Convertors Screen

| Area                         | Status          | Phase |
| ---------------------------- | --------------- | ----- |
| 8-tile grid                  | Stub            | 9     |
| Individual converter screens | Not implemented | 9     |

#### 🔵 Rifle / Cartridge / Sight Selection

| Area                        | Status | Phase |
| --------------------------- | ------ | ----- |
| `RifleSelectionScreen`      | Stub   | 11    |
| `RifleEditScreen`           | Stub   | 11    |
| `SightSelectionScreen`      | Stub   | 11    |
| `CartridgeScreen`           | Stub   | 11    |
| `ProjectileSelectionScreen` | Stub   | 11    |
| `CartridgeEditScreen`       | Stub   | 11    |

#### 🔵 Additional Screens

| Area                | Status          | Phase |
| ------------------- | --------------- | ----- |
| `InfoScreen`        | Stub            | 12    |
| `ReticleScreen`     | TBD             | 12    |
| `TableConfigScreen` | Stub            | 12    |
| Help Overlay        | Not implemented | 12    |
| Tools Screen        | Not implemented | 12    |

#### ⚪ Polish & Export

| Area                                             | Status          | Phase |
| ------------------------------------------------ | --------------- | ----- |
| Localization uk/en (ARB + flutter_localizations) | Not implemented | 13    |
| Table export (PDF/HTML + share sheet)            | Not implemented | 13    |
| Profile import (`file_picker`)                   | Not implemented | 13    |
| iOS C++ bundling                                 | Not implemented | 13    |

---

## 9. Implementation Phases

---

### Phase 1–5 ✅ — Foundation

Domain models, storage, providers, navigation. **Done.**

---

### Phase 5.5 — Value Input Widgets

**MVP ✅:** `showUnitEditDialog()` in `unit_value_field.dart` — reusable `[−] field [+]` dialog used by both `UnitValueField` rows and `QuickActionsPanel` buttons. Quick Actions Panel is fully wired.

**Remaining:**

**Ruler Selector** (`lib/widgets/ruler_selector.dart`):
- Modal with vertical ruler (touch drag)
- POS-terminal digit input
- Reference: `ruler.tsx`, `valueDialog.tsx`, `numericField.tsx`
- Will replace `showUnitEditDialog` in QuickActionsPanel when implemented

**Spin Box Selector** (`lib/widgets/spin_box_selector.dart`):
- Modal with up/down step buttons + POS-terminal input
- Reference: `doubleSpinBox.tsx`

---

### Phase 6 — Home Screen Bottom Block

1. **Page 1:** Left — reticle placeholder (circle with crosshairs, non-interactive for now). Right — drop/windage in multiple units from `adjustmentDisplay` settings. ✅
2. **Page 2:** Scrollable set of compact tables (Height, Slant Height, Drop angle, Windage angle, Velocity, Energy, Time), each ±2 steps around target distance. ✅
3. **Page 3:** ✅ Done — chart (trajectory + velocity curves), info grid above, tap/drag-to-select point, page persistence across rebuilds.
4. Also: placeholder sub-screens for New Note and More buttons. ⏳

---

### Phase 7 — Conditions Screen ✅

All fields connected to `ShotProfileNotifier.updateConditions()`. `UnitValueField` used for alt/humidity/pressure. `_TempControl` for temperature (big centered widget with `[−][+]` + dialog). Switches connected to `SettingsNotifier`. Powder sensitivity full flow implemented. Aerodynamic jump + Pressure from altitude: always ON, controls visible but disabled.

---

### Phase 8 — Tables Screen

**Done:** calculationProvider connected, topbar, spinner, domain types, zero-row highlight.

**8.8 ✅** `zeroDistance` + `zeroConditions?` + `targetDistance` added to `ShotProfile`. Hardcoded 100 m removed from calculator. `ShotProfileNotifier` has `updateZeroDistance`, `updateZeroConditions`, `updateTargetDistance`, `updateWindSpeed`.

**Done:** 8.1 sticky column header (StickyHeader + bidirectional h-scroll sync). 8.2 zero crossings table with ↑/↓ direction arrows. 8.3 row tap → detail dialog. 8.4 details spoiler (ExpansionTile: rifle/projectile/atmosphere, all spoilerShow* flags wired). 8.6 Configure button → TableConfigScreen (TableConfig: range, step, showZeros, showSubsonicTransition, spoiler switches, column visibility, dropUnit/adjUnit overrides). TableConfig start/end/step applied in filtering; dropUnit/adjUnit overrides applied in column display. TableConfig distance fields use `FC.targetDistance` with cross-field start < end validation.

**Pending:**
- **8.7** Wire Export button
- **8.8 follow-up** Zero Conditions UI (screen to edit `zeroConditions` separately from current `conditions`)


---

### Phase 9 — Convertors Screen

Grid of 8 tiles → each pushes `/convertors/:type` placeholder. Individual converter screen: two input fields, real-time conversion via `Unit`/`Dimension`.

---

### Phase 10 — Settings Screen ✅

**Done:** theme, subsonic switch, distance steps, links/about, language dialog, Units screen (10 categories), Adjustment Display screen (format + 5 toggles), `AppSettings` adjustment fields, `SettingsNotifier` methods.

---

### Phase 11 — Rifle / Cartridge / Sight Selection

- `RifleSelectionScreen` — list from `rifleLibraryProvider`, FAB to create
- `RifleEditScreen` — form: name, sight height, twist, zero elevation
- `SightSelectionScreen` — list from `sightLibraryProvider`
- `CartridgeScreen` — select / create / edit current
- `ProjectileSelectionScreen` — list from `cartridgeLibraryProvider`
- `CartridgeEditScreen` — full projectile + ammo form

---

### Phase 12 — Additional Screens

- `InfoScreen` — read-only ShotProfile display ✅
- `ReticleScreen` — full-screen reticle (TBD)
- `TableConfigScreen` — column visibility + step
- **Help Overlay** — all-in-one coach marks
- **Tools Screen** — ruler selectors for wind/angle/distance

---

### Phase 13 — Polish & Export

- Localization (ARB, flutter_localizations, uk + en)
- Table export — PDF or HTML via share sheet
- Profile import via `file_picker`
- iOS C++ library bundling

---

## 10. Dependencies

### In use

```yaml
flutter_riverpod:
go_router:
ffi:
uuid:
path_provider:
window_manager:
sticky_headers:   # sticky section headers in trajectory table
```

### To add

```yaml
file_picker: ^8.0.0      # .a7p import + profile import
share_plus: ^9.0.0       # .a7p export + table export share sheet
archive: ^3.0.0          # ZIP backup export
flutter_localizations: sdk
intl: ^0.19.0
```

### protoc toolchain (dev, not in pubspec)

```bash
dart pub global activate protoc_plugin
# then: protoc --dart_out=lib/src/proto proto/profedit.proto
```

---

---
## Incomplete changes

[+] Extract HomeReticlePage + helpers to widgets/home_reticle_page.dart
[+] Extract HomeTablePage to widgets/home_table_page.dart
[+] Extract HomeChartPage + _ChartInfoGrid to widgets/home_chart_page.dart
[+] Slim down home_screen.dart (remove extracted code, add imports)
[+] Split settings_sub_screens.dart → settings_units_screen.dart + settings_adjustment_screen.dart + widgets/settings_helpers.dart
[+] Extract _TempControl to widgets/temperature_control.dart

---

## 11. Execution Order

```
Incomplete changes - First priority
Phase 1–5   ✅  Foundation (domain, storage, providers, navigation)
Phase 10    ✅  Settings (language, units, adjustment display)
Phase 7     ✅  Conditions Screen (all fields, switches, powder sensitivity flow)
Phase 8.8   ✅  ShotProfile.zeroDistance + zeroConditions + targetDistance; hardcoded 100 m removed
Phase 5.5   ✅  QuickActionsPanel MVP (showUnitEditDialog; wind speed, look angle, target range wired)
            ✅  Hardcoded units removed from Home screen (unitSettingsProvider used for temp/alt/press)
            ⏳  RulerSelector widget (replaces dialog MVP in QuickActionsPanel — lower priority)
Phase 6         Home Screen bottom block (pages 1 & 2, info grid, tap-select on chart)
Phase 8         Tables Screen (frozen header, zero table, spoiler, configure, export)
A7P         🔴🔴 .a7p file support (proto gen, parser, writer, file picker, FC alignment)
Zero Cond   🔴  Zero Conditions UI (edit zeroConditions separately from current conditions)
Phase 11        Rifle / Cartridge / Sight Selection screens
Phase 9         Convertors Screen (grid + individual converters)
Phase 12        Additional Screens (Info ✅, Reticle, TableConfig, Help, Tools)
Phase 13        Polish & Export (l10n, PDF export, profile import, iOS build)
```

---

---

## 12. Next Steps Plan

### Priority 0 — .a7p Profile File Support (🔴🔴 Critical — blocks everything else)

Without this, all selection screens are meaningless — the app can't import real shooter profiles.

---

#### A7P-1. Proto definition & Dart code generation

The `.a7p` format is: **16-byte MD5 hash** (of the payload) + **serialized protobuf** `Payload`.

Create `proto/profedit.proto` — simplified copy of the upstream proto without `buf/validate` annotations (Dart `protoc_plugin` doesn't need them):

```protobuf
syntax = "proto3";
package profedit;

message Payload  { Profile profile = 1; }
message CoefRow  { float mv = 1; float bc_cd = 2; }
message SwPos    { float zoom = 1; float distance = 2; float position = 3; }

enum DType   { DISTANCE_VALUE = 0; DISTANCE_INDEX = 1; }
enum GType   { G1 = 0; G7 = 1; CUSTOM = 2; }
enum TwistDir{ RIGHT = 0; LEFT = 1; }

message Profile {
  string   profile_name        = 1;
  string   cartridge_name      = 2;
  string   bullet_name         = 3;
  string   short_name_top      = 4;
  string   short_name_bot      = 5;
  string   short_name_mid      = 6;
  string   caliber             = 7;
  int32    zero_x              = 8;   // h-clicks × -1000
  int32    zero_y              = 9;   // v-clicks × 1000
  repeated int32  distances    = 10;  // metres × 100
  repeated SwPos  switches     = 11;
  int32    sc_height           = 12;  // mm
  int32    r_twist             = 13;  // inch × 100
  TwistDir twist_dir           = 14;
  int32    c_muzzle_velocity   = 15;  // mps × 10
  int32    c_zero_temperature  = 16;  // °C (powder temp at zero)
  int32    c_t_coeff           = 17;  // %/15°C × 1000
  int32    c_zero_air_pressure = 18;  // hPa × 10
  int32    c_zero_air_humidity = 19;  // %
  int32    b_diameter          = 20;  // inch × 1000
  int32    b_weight            = 21;  // grain × 10
  int32    b_length            = 22;  // inch × 1000
  GType    bc_type             = 23;
  repeated CoefRow coef_rows   = 24;
  string   uuid                = 25;
  DType    distance_from       = 26;
  int32    c_zero_distance_idx = 27;  // index × 10 into distances table
  int32    c_zero_air_temperature = 28;  // °C (air temp at zero)
  int32    c_zero_p_temperature   = 29;  // °C (powder temp at zero, same as c_zero_temperature)
  int32    c_zero_w_pitch         = 30;  // degrees (zeroing look angle)
}
```

Generate Dart classes:
```bash
dart pub global activate protoc_plugin
protoc --dart_out=lib/src/proto proto/profedit.proto
```

Check generated files into the repo (`profedit.pb.dart`, `profedit.pbenum.dart`, etc.).

---

#### A7P-2. Parser — `lib/src/a7p/a7p_parser.dart`

```
File bytes layout:
  [0..15]  = MD5 of payload bytes
  [16..]   = protobuf Payload.SerializeToString()
```

Steps:
1. `md5(bytes.sublist(16)) == bytes.sublist(0, 16)` — verify checksum (`crypto` package already in pubspec)
2. `Payload.fromBuffer(bytes.sublist(16))` — decode protobuf
3. Convert raw integers → domain types using multipliers (see table below)
4. Build and return `ShotProfile`

**Multiplier table (raw → real value):**

| Proto field              | Stored unit     | ÷ by   | Real unit  | Maps to                           |
|--------------------------|-----------------|--------|------------|-----------------------------------|
| `sc_height`              | mm              | 1      | mm         | `Rifle.weapon.sightHeight` (mm)   |
| `r_twist`                | inch × 100      | 100    | inch       | `Rifle.weapon.twist` (inch)       |
| `twist_dir`              | RIGHT/LEFT      | —      | —          | `Rifle.weapon.twistDir`           |
| `c_muzzle_velocity`      | mps × 10        | 10     | mps        | `Cartridge.mv` (mps)              |
| `c_zero_temperature`     | °C              | 1      | °C         | `Cartridge.powderTemp` (°C)       |
| `c_t_coeff`              | %/15°C × 1000   | 1000   | %/15°C     | `Cartridge.tempModifier`          |
| `c_zero_air_temperature` | °C              | 1      | °C         | `ShotProfile.zeroConditions.temp` |
| `c_zero_air_pressure`    | hPa × 10        | 10     | hPa        | `ShotProfile.zeroConditions.pressure` |
| `c_zero_air_humidity`    | %               | 1      | %          | `ShotProfile.zeroConditions.humidity` |
| `c_zero_p_temperature`   | °C              | 1      | °C         | `ShotProfile.zeroConditions.powderTemp` |
| `c_zero_w_pitch`         | deg             | 1      | deg        | `ShotProfile.lookAngle`           |
| `b_diameter`             | inch × 1000     | 1000   | inch       | `Projectile.diameter` (inch)      |
| `b_weight`               | grain × 10      | 10     | grain      | `Projectile.weight` (grain)       |
| `b_length`               | inch × 1000     | 1000   | inch       | `Projectile.length` (inch)        |
| `bc_type`                | G1/G7/CUSTOM    | —      | —          | `Projectile.dragModelType`        |
| `coef_rows.bc_cd` (G1/G7)| BC × 10000      | 10000  | BC         | `DragTable` BC values             |
| `coef_rows.mv` (G1/G7)   | mps × 10        | 10     | mps        | `DragTable` MV values             |
| `coef_rows.bc_cd` (CUSTOM)| Cd × 10000     | 10000  | Cd         | `DragTable` Cd values             |
| `coef_rows.mv` (CUSTOM)  | mach × 10       | 10     | mach       | `DragTable` mach values           |
| `distances`              | m × 100         | 100    | m          | table `distances` array           |
| `c_zero_distance_idx`    | index × 10      | 10     | index      | index into `distances[]` → `zeroDistance` |
| `zero_x`                 | clicks × -1000  | -1000  | clicks     | `ShotProfile.zeroX` (h-click)     |
| `zero_y`                 | clicks × 1000   | 1000   | clicks     | `ShotProfile.zeroY` (v-click)     |

`zeroDistance = Unit.meter(distances[c_zero_distance_idx ~/ 10] / 100)`

---

#### A7P-3. Writer — `lib/src/a7p/a7p_writer.dart`

Reverse of parser: `ShotProfile` → `Profile` → apply multipliers (× by each factor, round to int) → serialize → prepend MD5.

---

#### A7P-4. File picker integration

Add to `pubspec.yaml`:
```yaml
file_picker: ^8.0.0
```

Entry points:
- **Import** — Settings → Data → "Import .a7p profile": `FilePicker.platform.pickFiles(allowedExtensions: ['a7p'])`, parse, save to `ShotProfile` storage
- **Export** — Settings → Data → "Export as .a7p": write current `ShotProfile` → `.a7p` file, share via `share_plus`

---

#### A7P-5. FieldConstraints alignment with yupy_schema

Ranges to update after verifying against actual proto validation:

| FC key              | Current min/max      | Yupy schema         | Action needed         |
|---------------------|----------------------|---------------------|-----------------------|
| `pressure`          | 300–1500 hPa         | 300–1050 hPa        | Lower max → 1050      |
| `muzzleVelocity`    | 100–1800 mps         | verify raw range    | Verify & align        |
| `bulletDiameter`    | 1–30 mm              | 0.1–100 inch×1000   | Verify real-unit range|
| `bulletWeight`      | 1–800 grain          | 0.1–10000 grain×10  | Raise max if needed   |
| `twistRate`         | 1–30 inch            | min 1 (×100)        | Verify                |

⚠️ The yupy schema values may be for raw stored integers — verify against actual proto before changing FC.

---

### Priority 1 — Zero Conditions UI (🔴 Critical, 8.8 follow-up)

`zeroConditions` exists in `ShotProfile` but is always `null` (= use current conditions).
Need a screen/panel to edit it independently.

- Add `/home/shot-details/zero-conditions` route (or a dedicated sub-section in Shot Details screen)
- Reuse `UnitValueField` + same layout as Conditions screen
- Fields: temperature, altitude, humidity, pressure (same as Conditions but for zero scenario)
- Save via `ShotProfileNotifier.updateZeroConditions()`
- Clear button → sets `zeroConditions = null` (revert to "use current")

---

### Priority 2 — Phase 11: Rifle / Cartridge / Sight Selection

Core app functionality — currently all screens are stubs; user works only with seed data.

**Order:**

1. **`RifleSelectionScreen`** (`/home/rifle-select`)
   - List from `rifleLibraryProvider`; tap → select & pop
   - FAB / button → push `RifleEditScreen` (create new)

2. **`RifleEditScreen`** (`/home/rifle-select/rifle-edit`)
   - Fields: name, caliber (sight height, twist rate, twist direction, zero elevation)
   - Save via `rifleLibraryProvider` + auto-select

3. **`SightSelectionScreen`** (`/home/rifle-select/sight-select`)
   - List from `sightLibraryProvider`; tap → attach to rifle
   - Create new inline

4. **`CartridgeScreen`** (`/home/rifle-select/cartridge`)
   - Sub-screen: select from library or edit current cartridge params
   - Edit: MV, powder temp, powder sensitivity, `usePowderSensitivity`

5. **`ProjectileSelectionScreen`** (`/home/projectile-select`)
   - List from `cartridgeLibraryProvider`; tap → select
   - `ProjectileEditScreen`: drag model, BC, weight, length, diameter

6. **`CartridgeEditScreen`** (`/home/rifle-select/cartridge/edit`)
   - Full form: projectile params + ammo params + sensitivity

---

### Priority 3 — Phase 9: Convertors Screen

- 8-tile `SliverGrid` responsive layout
- Each tile → `/convertors/:type` sub-screen
- Sub-screen: two `UnitValueField`-style inputs, real-time conversion via `Unit`/`Dimension`
- Types: target-distance, velocity, length, weight, pressure, temperature, mil-moa, torque

---

### Priority 4 — Phase 8.7: Export button

- Share table as plain text (CSV or formatted text) via `share_plus`
- PDF generation (TBD — use `printing` package or custom HTML)

---

### Priority 5 — Phase 13: Polish

- Localization uk/en (ARB + `flutter_localizations`)
- Profile import via `file_picker`
- iOS C++ bundling

---

*Document updated as implementation progresses.*
