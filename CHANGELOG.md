# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---


## [Unreleased]

### Changed

#### UI
- **Navigation bar labels** — applied `NavigationBarTheme` with `fontSize: 11` and `TextOverflow.ellipsis` so long localized labels truncate gracefully instead of overflowing

### Refactored

#### Code Quality — UI constants & divider widgets (#7.1, priority 9)
- Created `lib/shared/constants/ui_dimensions.dart` — `kHorizontalPadding`, `kDefaultVerticalPadding`, `kTileDividerHeight`, `kSectionDividerHeight`, `kMultiBcRowCount`, `kDragTableRowCount`
- Created `TileDivider` + `SectionDivider` widgets (`lib/shared/widgets/dividers.dart`)
- Replaced 43 × `Divider(height: 1)` and 4 × `Divider(height: 24)` across 19 files
- Moved `_kMultiBcRowCount` / `_kDragTableRowCount` from local to shared constants

### Fixed

#### Export / Import
- **A7P zero offset export** — `setPayloadOffsets` now correctly converts the ammo angular offset to cm/100m via `Angular(...).in_(Unit.cmPer100m)` before dividing by click size; previously multiplied instead of divided, producing wrong click counts
- **A7P zero offset import** — removed erroneous `getPayloadOffsets` call on import; a7p stores offsets as dimensionless click counts with no click-size metadata, so the angular offset cannot be reconstructed at import time and is intentionally left at default
- **Built-in collection** - fix sight heights
- **Settings screen sight height unit** - fix sight height unit picker

### Refactored

#### Code Quality — Table editor generalization (#7.1, priority 3)
- Extracted `TwoColumnTableEditorScreen` widget (`lib/shared/widgets/two_column_table_editor.dart`) — generic two-column numeric table with `col1Signed`, `col1RequirePositive`, `readOnly`, `headerChild` (live preview slot), `onRowsParsed` (change callback), `footerText`
- `multi_bc_editor_screen.dart`: removed internal `_TwoColumnTableEditorScreen` + all sub-widgets; 400 → 110 lines
- `powder_sens_table_editor_screen.dart`: replaced `_PowderSensEditorScreen` with `TwoColumnTableEditorScreen`; converted to `ConsumerStatefulWidget` for live preview state; 450 → 195 lines
- ~545 LOC removed across two files

#### Code Quality — Wizard screens deduplication (#7.1, priority 4)
- Extracted `WizardActionBar` widget (`lib/shared/widgets/wizard_action_bar.dart`) — replaces three identical private `_ActionBar` classes in weapon, sight, and ammo wizard screens
- Extracted `WizardNameField` widget (`lib/shared/widgets/wizard_name_field.dart`) — padded `TextField` with empty-name error styling, replaces inline pattern repeated in all three wizards
- Introduced `WizardFormMixin<W>` (`lib/shared/mixins/wizard_form_mixin.dart`) — mixin on `ConsumerState<W>` covering: `nameCtrl` / `vendorCtrl` lifecycle (init + dispose), `isNameValid` getter, `wizardTitle()`, `onNameChanged()`, `onDiscard()`, `commitSave()`
- Applied to all three wizard screens (`weapon_wizard_screen`, `sight_wizard_screen`, `ammo_wizard_screen`); ~155 LOC removed

#### Code Quality — Converter generalization (#7.1, priorities 1–2)
- Introduced `SimpleConvertorVm` abstract base class (Template Method pattern) in `lib/features/convertors/simple_convertor_vm.dart`:
  - Shared `build()`, `updateRawValue()`, `changeInputUnit()`, `fieldFor()`, `_fmt()` — no longer duplicated across VMs
  - Shared state types: `SimpleConvertorUiState`, `ConvertorSection`
- Applied to 5 simple VMs: `length`, `weight`, `pressure`, `temperature`, `torque` — each reduced to ~55 lines of VM-specific config; ~600 LOC removed
- Introduced `SimpleConvertorScreen` stateless widget in `lib/features/convertors/sub_screens/simple_convertor_screen.dart` — generic layout (input picker → sections → info tiles)
- Applied to 5 simple screens — each reduced to ~25-line `ConsumerWidget` wrapper; ~270 LOC removed
- Velocity, angular, and target-distance converters untouched (unique layouts)
- All provider names unchanged — zero impact on call sites

#### Unit picker
- `UnitPickerTile` and `UnitPickerButton` share reusable `showUnitPicker`

### Added

#### Localization
- **Setup flutter_localizations** - added `flutter_localizations` dependency
- **Settings screen (UA)** - Settings screen and it's subscreens localization
- **Convertors screen (UA)** - Convertors screen and all convertors subscreens localization


## [0.1.2] - 2026-04-26

### Added

#### Android
- Initial Android support — application builds and runs on Android
- CI integration for Android builds, including FFI and submodules
- File import support via `file_picker` with Android fallback (`FileType.any`)
- FileProvider configuration for `share_plus`
- `<queries>` configuration for `file_picker` and `url_launcher` (Android 11+)

#### CI / Build
- Reusable `build-apk.yml` workflow:
  - supports `workflow_call`
  - accepts `build_name`, `build_type`, `retention_days`
  - supports signing via secrets
- `scripts/build-android.sh`:
  - sets app version from CI
  - decodes keystore from `ANDROID_KEYSTORE_BASE64`
  - builds split-per-ABI APKs
  - outputs artifacts to `artifacts/`
- `scripts/generate-android-keystore.sh`:
  - generates JKS keystore
  - creates `android/key.properties`
  - exports base64 + metadata to `certs/`

### Changed

#### Android
- Impeller renderer disabled (`EnableImpeller=false`) due to incorrect SVG circle tessellation (temporary workaround until upstream fix)
- `AndroidManifest.xml` updated:
  - added storage permissions (`READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`)
  - enabled `requestLegacyExternalStorage`
  - added URL visibility queries (`http`, `https`)

#### CI / Build
- `release.yml` now uses reusable `build-apk.yml` instead of inline Android job
- APK files (`*.apk`) are now included as release assets
- `build.gradle.kts`:
  - reads signing config from `android/key.properties`
  - falls back to debug signing if missing
- Reusable `pr-summary.yml` workflow — posts/updates per-platform build result comment on PRs; replaces duplicated inline scripts in `build-apk.yml`, `build-exe.yml`, `build-appimage.yml`
- PR artifact links now use `upload-artifact@v4` direct URL instead of a generic run page link
- Version resolution unified across all workflows via `.github/actions/version`:
  - tag builds → version from tag
  - PR / `workflow_dispatch` → base version from `pubspec.yaml` (no suffix)
- `build-apk.yml`: added `prepare-version` job for direct PR and dispatch triggers (previously fell back to hardcoded `0.1.0-dev`)
- MSIX version revision set to `0` for release tags (`v*.*.*`, `v*.*.*-*`) per Microsoft Store requirement; non-release builds keep `run_number` as revision

#### Reticle gen
- Updated reticles generator

### Fixed

#### UI
- Window scaling now respects system scale on startup
- Fixed `RenderFlex` overflow on Home screen
- Fixed `PageDotsIndicator` overflow (tap target size mismatch)
- `AdjustmentDisplay` now correctly applies zero offsets and adjustments

#### SVG / Rendering
- Fixed SVG circles rendered as polygons:
  - `reticle_gen` now uses `<circle>` instead of arc `<path>`
  - regenerated all reticle and target assets

#### Navigation
- Fixed missing `await` in `HomeScreen → AmmoWizard` route

#### Code Quality
- Enabled `discarded_futures: true`
- Fixed all related lint issues

### Reliability
- Improved database resilience:
  - ObjectBox open failure is now handled
  - corrupted `data.mdb` / `lock.mdb` are deleted automatically
  - store is reinitialized safely
  - user is notified via SnackBar only if data previously existed

### Docs
- README updated:
  - added **Android notes** section
  - documented Impeller workaround
  - documented file import limitations on Android


## [0.1.1] - 2026-04-23

### CI / Build
- **Release workflow** — single `release.yml` triggers on `v*.*.*` tags; builds all platforms in parallel, publishes GitHub Release with all assets; manual dispatch supported for dry-run asset listing
- **Reusable `version` action** — `.github/actions/version` extracts semver from tag or returns default; replaces duplicated `prepare-version` logic across all workflows
- **Consistent artifact naming** — all distributables follow `ebalistyka_<platform>_<arch>.<ext>` without version or build number in the filename (predictable URLs for auto-update)
- **Version propagation** — CI writes `version: X.Y.Z+<run_number>` into `pubspec.yaml` before build; app settings and MSIX version stay in sync automatically
- **MSIX signing** — self-signed certificate stored as `CERTIFICATE_BASE64` / `CERTIFICATE_PASSWORD` repo secrets; imported non-interactively before packaging; `install_certificate: false` in pubspec suppresses msix tool prompt
- **MSIX auto-update** — `.appinstaller` generated alongside `.msix`; points to `releases/latest/download/` so Windows checks for updates on each launch
- **Linux AppImage zsync** — `--updateinformation` embedded in AppImage; `.AppImage.zsync` generated via `zsyncmake`; enables AppImageUpdate / zsync2 delta updates from GitHub Releases
- **Portable archives** — Linux bundle → `artifacts/portable/*.tar.gz`; Windows bundle → `artifacts/portable/*.zip`; AppImage → `artifacts/appimage/`; MSIX → `artifacts/msix/`


## [0.1.0+9] - 2026-04-23

### Fixed
- **Settings notifier** now works immediatelly
- **Adjustment display panel** sizing and placing, text size clamp
- **Conditions screen icon**
- **Reticle view display ratio**

### Changed
- **Max window size** limitations are disabled 

### Features
- **Improve home screen** condition indicators got text labels 
- **Improve home paging** pages got text labels 
- **Display adjustments in current clicks** on home screen, tables screen, html report and reticle view screen


## [0.1.0+8] - 2026-04-23

### Fixed
- **Hotfix:** corrected twist rate validation — the field now accepts `0` as a valid value.


## [0.1.0+7] - 2026-04-22

### Architecture
- **Removed `recalc_coordinator`:** widgets now listen directly to ObjectBox streams via providers

### Changed
- **Complete CRUD UI:** users can now create and manage ballistic data
- **A7P as a local package:** serializer moved to `packages/a7p`
  
### Added
- **Reticle generator CLI:** generates compatible reticles and target SVG images
- **App launcher icons and splash screen**

### Features
- **Export / Import:** supports native and `.A7P` formats
- **Reticles screen:** reticle view and adjustment management
- **Unit converters:** fully implemented across all supported dimensions

### Fixed
- **Twist and wind direction handling**

### Docs
- **Backlog:** updated documentation
- **Timeline docs:** updated with time-based versioning


## [0.1.0-alpha] - 2026-04-12

Initial alpha release — first functional build of the ballistic trajectory calculator.

### Architecture
- **ObjectBox migration:** full replacement of JSON storage with a reactive ObjectBox database (entities, relations, streams)
- **`bclibc` as a local package:** C++ ballistic solver moved to `packages/bclibc_ffi` (v1.0.3)
- **Reactive providers:** rebuilt on ObjectBox watch streams; DB updates trigger automatic UI refresh
- **Zero key caching:** zeroing phase skipped when inputs remain unchanged
- **Typed extensions:** raw entity fields replaced with type-safe accessors

### Features
- **Profiles screen:** PageView with profile cards; create, rename, duplicate, delete; active profile pinned first
- **Profile card:** weapon / ammo / sight sections with inline editing; `IncompleteBanner` for missing data
- **Weapon wizard:** create/edit weapons with caliber, twist, barrel length; supports presets
- **Sight wizard:** full configuration (FFP/SFP/LWIR, mount parameters, click values, magnification range)
- **Ammo & sight selection:** per-profile selection or creation
- **Built-in collection:** calibers, weapons, cartridges, projectiles, sights (`collection.json`)
- **Unit converters:** implemented — length, weight, pressure, temperature, torque, angular
- **Generic converter field:** reusable real-time dual-input conversion widget
- **Dimension factory constructors:** type-safe constructors for all unit dimensions

### Fixed
- Profile ordering (active profile always first)
- Ammo selection filtering and sorting
- Immediate application of table settings
- Duplication logic for profiles, ammo, and sights; weapon seed deduplication
- Correct Coriolis force application
- Improved home screen accuracy (holdover, windage)
- Home table hold value issue
- Wizard form validation (touched-flag pattern)
- Twist direction icon display
- Shot details table values

### CI / Build
- GitHub Actions: Linux AppImage and Windows EXE builds on PR
- Reusable `build.yml` with platform/arch/build-type matrix
- Pre-build setup: submodule initialization and FFI bindings generation

### Docs
- `README.md`: badges, screenshots, feature overview, build instructions, dependencies
- `LICENSE`: GPL-3.0
- `OBJECTBOX_MIGRATION.md`: migration details