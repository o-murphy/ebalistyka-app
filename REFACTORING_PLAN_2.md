# REFACTORING_PLAN_2.md — Post-Refactoring Improvements

**Status:** Draft
**Prerequisite:** REFACTORING_PLAN.md (phases 0–5) — completed

---

## Table of Contents

1. [Feature-First Directory Restructure](#1-feature-first-directory-restructure)
2. [ShotDetailsViewModel — Legacy Provider Elimination](#2-shotdetailsviewmodel--legacy-provider-elimination)
3. [FFI Enum Wrappers](#3-ffi-enum-wrappers)
4. [ffigen Update](#4-ffigen-update)
5. [Execution Order](#5-execution-order)

---

## 1. Feature-First Directory Restructure

### 1.1 Problem

Current layout is **layer-first**: all screens in `screens/`, all widgets in `widgets/`, all providers in `providers/`. When working on a feature (e.g. Tables), files are scattered across 4+ directories. Feature-first groups related code together.

### 1.2 Current Structure

```
lib/
├── domain/                    # 1 file
├── formatting/                # 2 files
├── helpers/                   # 1 file
├── providers/                 # 8 files
├── screens/                   # 12 files
├── services/                  # 1 file
├── src/                       # models, solver, proto, a7p
├── storage/                   # 2 files
├── viewmodels/                # 3 VMs + shared/
├── widgets/                   # 14 files
├── main.dart
└── router.dart
```

### 1.3 Target Structure

```
lib/
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── home_vm.dart
│   │   ├── widgets/
│   │   │   ├── home_chart_page.dart
│   │   │   ├── home_reticle_page.dart
│   │   │   ├── home_table_page.dart
│   │   │   ├── quick_actions_panel.dart
│   │   │   ├── side_control_block.dart
│   │   │   ├── trajectory_chart.dart
│   │   │   └── wind_indicator.dart
│   │   └── sub_screens/
│   │       ├── home_sub_screens.dart     # rifle/cart/sight stubs
│   │       └── shot_details_screen.dart
│   │
│   ├── conditions/
│   │   ├── conditions_screen.dart
│   │   ├── conditions_vm.dart
│   │   └── widgets/
│   │       ├── temperature_control.dart
│   │       └── unit_value_field.dart      # shared — see note below
│   │
│   ├── tables/
│   │   ├── tables_screen.dart
│   │   ├── tables_vm.dart
│   │   ├── tables_config_screen.dart      # was tables_sub_screens.dart
│   │   └── widgets/
│   │       └── trajectory_table.dart
│   │
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── settings_units_screen.dart
│   │   ├── settings_adjustment_screen.dart
│   │   └── widgets/
│   │       └── settings_helpers.dart
│   │
│   └── convertors/
│       └── convertor_screen.dart
│
├── shared/
│   ├── widgets/
│   │   ├── icon_value_button.dart
│   │   ├── section_header.dart
│   │   └── unit_value_field.dart          # used by conditions + home
│   ├── models/
│   │   ├── adjustment_data.dart           # was viewmodels/shared/
│   │   ├── chart_point.dart
│   │   └── formatted_row.dart
│   └── helpers/
│       └── is_desktop.dart
│
├── core/
│   ├── domain/
│   │   └── ballistics_service.dart
│   ├── services/
│   │   └── ballistics_service_impl.dart
│   ├── formatting/
│   │   ├── unit_formatter.dart
│   │   └── unit_formatter_impl.dart
│   ├── providers/
│   │   ├── formatter_provider.dart
│   │   ├── home_calculation_provider.dart  # legacy, until ShotDetailsVM
│   │   ├── library_provider.dart
│   │   ├── recalc_coordinator.dart
│   │   ├── service_providers.dart
│   │   ├── settings_provider.dart
│   │   ├── shot_profile_provider.dart
│   │   └── storage_provider.dart
│   ├── storage/
│   │   ├── app_storage.dart
│   │   └── json_file_storage.dart
│   ├── models/                            # was src/models/
│   │   ├── _dim.dart
│   │   ├── app_settings.dart
│   │   ├── cartridge.dart
│   │   ├── field_constraints.dart
│   │   ├── projectile.dart
│   │   ├── rifle.dart
│   │   ├── seed_data.dart
│   │   ├── shot_profile.dart
│   │   ├── sight.dart
│   │   ├── table_config.dart
│   │   └── unit_settings.dart
│   ├── solver/                            # was src/solver/
│   │   ├── calculator.dart
│   │   ├── conditions.dart
│   │   ├── constants.dart
│   │   ├── drag_model.dart
│   │   ├── drag_tables.dart
│   │   ├── munition.dart
│   │   ├── shot.dart
│   │   ├── trajectory_data.dart
│   │   ├── unit.dart
│   │   ├── vector.dart
│   │   └── ffi/
│   │       ├── bclibc_bindings.g.dart
│   │       ├── bclibc_ffi.dart
│   │       └── bc_enums.dart              # Phase 3 — new
│   ├── a7p/                               # was src/a7p/
│   │   ├── a7p_parser.dart
│   │   └── a7p_validator.dart
│   └── proto/                             # was src/proto/ — auto-generated
│       ├── profedit.pb.dart
│       ├── profedit.pbenum.dart
│       └── profedit.pbjson.dart
│
├── main.dart
└── router.dart
```

### 1.4 Shared Widget Strategy

`unit_value_field.dart` is used by both `conditions_screen` and `home_screen` (via `quick_actions_panel`). Move to `shared/widgets/`. Same for `icon_value_button.dart` and `section_header.dart`.

`temperature_control.dart` is only used by `conditions_screen` — stays in `features/conditions/widgets/`.

### 1.5 Migration Rules

- Move files one feature at a time
- Update all imports after each feature move
- `flutter analyze` must pass after each move
- No logic changes — pure file moves + import updates
- Tests move in parallel: `test/viewmodels/home_vm_test.dart` → `test/features/home/home_vm_test.dart`

### 1.6 Migration Order

1. Create directory skeleton (`features/`, `shared/`, `core/`)
2. Move `src/models/` → `core/models/` (most imported, fix imports everywhere first)
3. Move `src/solver/` → `core/solver/`
4. Move `src/a7p/` → `core/a7p/`, `src/proto/` → `core/proto/`
5. Delete empty `src/`
6. Move `shared/` widgets + models (viewmodels/shared/ → shared/models/)
7. Move `core/` upper layers (providers, services, formatting, storage)
8. Move `features/settings/` (simplest feature, no VM)
9. Move `features/convertors/` (single file, no VM)
10. Move `features/conditions/`
11. Move `features/tables/`
12. Move `features/home/` (largest, move last)
13. Clean up empty old directories
14. Verify: `flutter analyze`, all tests pass

> **Note:** steps 2–5 (`src/` → `core/`) affect the most imports (~50+ files import from `src/`). Do these first so later moves don't need double-fixup. Use `git mv` + global find-replace on import paths.

---

## 2. ShotDetailsViewModel — Legacy Provider Elimination

### 2.1 Problem

`homeCalculationProvider` (`HomeCalculationNotifier`) exists only because `shot_details_screen.dart` reads raw `HitResult` and does inline unit conversions. This is the last screen not using the ViewModel pattern.

### 2.2 Solution

Create `ShotDetailsViewModel` following the same pattern as other VMs:
- Reads `shotProfileProvider`, `settingsProvider`, `ballisticsServiceProvider`, `unitFormatterProvider`
- Produces `ShotDetailsUiState` sealed class with formatted strings
- Screen becomes pure UI consumer

### 2.3 ShotDetailsUiState

```dart
sealed class ShotDetailsUiState {}
class ShotDetailsLoading extends ShotDetailsUiState {}
class ShotDetailsError extends ShotDetailsUiState { final String message; }
class ShotDetailsReady extends ShotDetailsUiState {
  // Velocity section
  final String currentMv;
  final String zeroMv;
  final String speedOfSound;
  final String velocityAtTarget;
  // Energy section
  final String energyAtMuzzle;
  final String energyAtTarget;
  // Stability section
  final String gyroscopicStability;  // "1.45" or "—"
  // Trajectory section
  final String shotDistance;
  final String heightAtTarget;
  final String maxHeightDistance;
  final String windage;
  final String timeToTarget;
}
```

### 2.4 After Completion

- Delete `lib/core/providers/home_calculation_provider.dart`
- Remove `homeCalculationProvider` from `recalc_coordinator.dart`
- Remove `homeCalculationProvider` override from `recalc_coordinator_test.dart`

---

## 3. FFI Enum Wrappers

### 3.1 Problem

FFI enums in `bclibc_bindings.g.dart` are raw `int` constants (e.g. `BCLIBCFFI_OK = 0`, `BC_TRAJ_FLAG_MACH = 4`). The Dart-side wrappers in `bclibc_ffi.dart` use strings and ad-hoc parsing. No type-safe Dart enums exist.

### 3.2 Current State

`bclibc_ffi.dart` defines value classes (`BcConfig`, `BcAtmosphere`, etc.) that map between Dart types and FFI structs. Error codes, trajectory flags, termination reasons, and interpolation keys are used as raw ints.

### 3.3 Proposal

Create typed Dart enums that wrap the generated int constants:

```dart
// lib/src/solver/ffi/bc_enums.dart

enum BcStatus {
  ok(BCLIBCFFI_OK),
  errSolverRuntime(BCLIBCFFI_ERR_SOLVER_RUNTIME),
  errOutOfRange(BCLIBCFFI_ERR_OUT_OF_RANGE),
  errZeroFinding(BCLIBCFFI_ERR_ZERO_FINDING),
  errInterception(BCLIBCFFI_ERR_INTERCEPTION),
  errGeneric(BCLIBCFFI_ERR_GENERIC);

  const BcStatus(this.value);
  final int value;

  static BcStatus fromValue(int v) =>
    values.firstWhere((e) => e.value == v, orElse: () => errGeneric);
}

enum BcTrajFlag {
  none(BC_TRAJ_FLAG_NONE),
  zeroUp(BC_TRAJ_FLAG_ZERO_UP),
  zeroDown(BC_TRAJ_FLAG_ZERO_DOWN),
  zero(BC_TRAJ_FLAG_ZERO),
  mach(BC_TRAJ_FLAG_MACH),
  range(BC_TRAJ_FLAG_RANGE),
  apex(BC_TRAJ_FLAG_APEX),
  all(BC_TRAJ_FLAG_ALL),
  mrt(BC_TRAJ_FLAG_MRT);

  const BcTrajFlag(this.value);
  final int value;
}

enum BcTerminationReason {
  noTerminate(BC_TERM_NO_TERMINATE),
  targetRangeReached(BC_TERM_TARGET_RANGE_REACHED),
  minimumVelocityReached(BC_TERM_MINIMUM_VELOCITY_REACHED),
  maximumDropReached(BC_TERM_MAXIMUM_DROP_REACHED),
  minimumAltitudeReached(BC_TERM_MINIMUM_ALTITUDE_REACHED),
  handlerRequestedStop(BC_TERM_HANDLER_REQUESTED_STOP);

  const BcTerminationReason(this.value);
  final int value;

  static BcTerminationReason fromValue(int v) =>
    values.firstWhere((e) => e.value == v, orElse: () => noTerminate);
}

enum BcInterpKey {
  time(BC_INTERP_KEY_TIME),
  mach(BC_INTERP_KEY_MACH),
  posX(BC_INTERP_KEY_POS_X),
  posY(BC_INTERP_KEY_POS_Y),
  posZ(BC_INTERP_KEY_POS_Z),
  velX(BC_INTERP_KEY_VEL_X),
  velY(BC_INTERP_KEY_VEL_Y),
  velZ(BC_INTERP_KEY_VEL_Z);

  const BcInterpKey(this.value);
  final int value;
}

enum BcIntegrationMethod {
  rk4(BC_INTEGRATION_RK4),
  euler(BC_INTEGRATION_EULER);

  const BcIntegrationMethod(this.value);
  final int value;
}
```

### 3.4 Migration

- Create `lib/core/solver/ffi/bc_enums.dart` (after Phase 1 moves `src/` → `core/`)
- Update `bclibc_ffi.dart` to use enums instead of raw ints
- Update `BcException` to use `BcStatus`
- Update `BcHitResult.terminationReason` to `BcTerminationReason`
- No external API changes — enums are internal to FFI layer

### 3.5 Note on Unit Generic

The `Unit` enum and `Dimension` generic system (`Velocity extends Dimension`, etc.) works well and is extensively tested. The generic approach provides type safety for unit conversions. **Do not remove generics from the unit system** — the current design is correct and well-tested.

If specific issues are identified with the generic approach (e.g. unnecessary complexity in `Measurable`), those should be evaluated case-by-case rather than as a blanket removal.

---

## 4. ffigen Update

### 4.1 Current State

`ffigen: ^12.0.0` in `pubspec.yaml`. Current bindings (`bclibc_bindings.g.dart`) work correctly.

### 4.2 Target

`ffigen: ^20.0.0` — latest version with improved generation.

### 4.3 Known Issues

- ffigen ^20 has problems with `typedef enum` — generated as opaque types instead of `int`
- This affects all FFI enum constants (`BCLIBCFFIStatus`, `BCTrajFlag`, `BCTerminationReason`, etc.)
- Workaround: may need manual patching of generated file or config overrides

### 4.4 Strategy

1. Update `ffigen` to `^20.0.0` in `pubspec.yaml`
2. Regenerate bindings: `dart run ffigen`
3. Check if enum constants are still `int` — if not, apply workaround:
   - Option A: `ffigen` config `type-map` to force enum → int
   - Option B: Post-generation script to fix typedefs
   - Option C: Stay on ^12 until upstream fix
4. Verify all FFI tests pass
5. Verify `flutter analyze` passes

### 4.5 Risk

Low priority. Current ^12 works. Only update when the enum issue has an upstream fix or a clean workaround.

---

## 5. Execution Order

```
Phase   Task                                        Depends on   Risk
─────   ──────────────────────────────────────────   ──────────   ────
  1     Feature-first directory restructure          —            Low (pure moves)
  2     ShotDetailsViewModel                         1 (paths)    Low
  3     FFI enum wrappers (bc_enums.dart)            —            Low
  4     ffigen update to ^20                         3            Medium (enum issue)
```

### Phase 1 — Feature-first restructure

**Estimated scope:** ~74 file moves + import updates
**Verification:** `flutter analyze` + all tests after each feature batch
**Risk:** Low — no logic changes, purely structural

### Phase 2 — ShotDetailsViewModel

**Estimated scope:** 1 new file (VM) + 1 new test file + edit 2 existing files
**Verification:** `flutter test` + `flutter analyze`
**Risk:** Low — follows established pattern from REFACTORING_PLAN phases 2-4

### Phase 3 — FFI enum wrappers

**Estimated scope:** 1 new file + edit 1 file
**Verification:** `dart test test/ffi_test.dart` + `flutter analyze`
**Risk:** Low — internal to FFI layer, no external API changes

### Phase 4 — ffigen update

**Estimated scope:** 1 config change + regenerate 1 file
**Verification:** Full test suite
**Risk:** Medium — may require workaround or rollback

---

## Notes

- Each phase should be a separate commit/PR
- No new features during restructure
- `src/` merges into `core/` — all domain code lives under one roof
- `router.dart` stays at `lib/` root — it references all feature screens
- `main.dart` stays at `lib/` root
- After Phase 1, all imports use `package:eballistica/core/...` and `package:eballistica/features/...` prefixes — no more `src/`
