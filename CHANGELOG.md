# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---


## [Unreleased]


## [0.1.7] - 2026-04-30

### Fixed
- **AmmoWizardScreen Hotfix** - AmmoWizardScreen arguments and it's `state.extra` atributes

### Changed
- **Improved ReticleView Holdovers Highlight** — much more readable holdovers overlays
- **Optimized Reticles generator** — uses `stroke-dasharray` for dashed lines instead of Path's
- **Reticle/Target picker screen layout** — uses grid layout with wrap for high-dpi devices


## [0.1.6] - 2026-04-30

### Added

- **Wind indicator — tap-to-set animation** — tapping anywhere on the ring animates the marker along the shorter arc to the tapped position (`easeOutCubic`, 380 ms) then commits; drag continues to follow the finger instantly; double-tap resets to North (0°); uses `Listener.onPointerDown` for zero-latency response (avoids GestureDetector disambiguation delay)
- **`UnitDialogInputField.autofocus` parameter** — exposes autofocus as an optional parameter (default `true`); `UnitHybridPicker` passes `autofocus: isDesktop` so the keyboard does not auto-open on mobile when the hybrid picker dialog is shown
- **`isDesktop` helper** — migrated from `dart:io` `Platform` checks to `defaultTargetPlatform` (no native-platform dependency, works in tests)
- **Quick-action long-press reset** — long-pressing the Wind Speed or Look Angle button in `QuickActionsPanel` resets the value to 0 and shows a snackbar confirmation; `windSpeedWasReset` / `lookAngleWasReset` l10n keys added (EN + UA)
- **Filter panel** — `My Ammo`, `My Weapon`, and `My Sight` screens now have a working filter button; bottom sheet with `ExpansionTile` sections per category; vendor multi-select with item-count badges; caliber multi-select (ammo); focal-plane toggle (sight); weight range via `UnitConstrainedInputField` (ammo min/max); filter badge shows active state; filter state persisted in `AmmoFilterNotifier` / `SightFilterNotifier` / `WeaponFilterNotifier`; same filter panel wired to collection screens

### Fixed

- **Collection update checker** — on startup checks the cached collection SHA against the latest GitHub commit (throttled to once per 24 h); Settings → Collection shows current SHA (7 chars) and a manual "Update collection" button; downloaded collection is cached to disk alongside the ObjectBox files; `builtinCollectionProvider` prefers the cached file, falls back to the bundled asset on load failure
- **Caliber mismatch action sheet** — when selecting or editing ammo whose caliber differs from the active weapon, an action sheet blocks the operation and offers two choices: update ammo caliber to match the weapon, or update the weapon caliber to match the ammo; dismissing without choosing leaves both unchanged and does not apply the ammo
- **Collection update error propagation** — `_fetchLatestCollectionCommit` now throws on non-200 HTTP status instead of silently returning `null` (previously treated as "up to date"); manual check in Settings now shows the actual network error in a snackbar
- **Caliber mismatch not triggered on ammo select** — `onSelect` in `MyAmmoScreen` previously had no caliber check at all; mismatch action sheet is now shown before the ammo is applied
- **Caliber mismatch not triggered on ammo edit** — `onEdit` previously passed the ammo's own caliber as the weapon reference caliber, so the mismatch check always exited early; now correctly passes the weapon's caliber
- **Filter state `copyWith`** — `AmmoFilterState`, `SightFilterState`, and `WeaponFilterState` now expose `copyWith`; notifier mutation methods use it instead of repeating all fields
- **Filter sheet `draftIsDefault` check** — caliber comparison now uses `setEquals` instead of `==` so `Set<double>` equality is correctly detected

### Changed

- **Seed profile data** — default profile updated: weapon → Cadex Defence Kraken CDX-MC (.338 LM, 9.5″ twist, 26″ barrel), ammo → Hornady 285 GR ELD-M (G7 BC 0.397, MV 827 m/s), sight → Nightforce ATACR 7-35×56 F1 (0.1 MIL clicks)


## [0.1.5] - 2026-04-29

### Added

- **In-app update checker** — on startup checks GitHub Releases (at most once per 24 h); shows a bottom sheet with "View" button if a newer version is available; manual check available in Settings → About; `INTERNET` permission added to `AndroidManifest.xml`

### Fixed

- **CI — version not passed to `flutter build apk`** — `--build-name` and `--build-number` flags now explicitly passed; `flutter pub get` moved after `pubspec.yaml` version patch in all workflows (`build.yml`, `build-apk.yml`) so Flutter sees the correct version before dependency resolution
- **CI — build number consistency** — `git rev-list --count` changed to `--first-parent` across all workflows to exclude merge commits from feature branches

### Removed

- **`desktop_updater` dependency** — removed; package does not support GitHub Releases artifacts (MSIX / tar.gz / AppImage / APK)

---

## [0.1.4] - 2026-04-28

### Fixed

- **Unit symbols — full audit** — all remaining `unit.symbol`/`unit.label` call sites replaced with `localizedSymbol(l10n)`/`localizedLabel(l10n)` across 22+ files; new ARB keys: `unitSecondSym` (`s`/`с`), `sgAbbr` (`Sg`/`ФГС`), `nClicks` (ICU plural: `click`/`clicks`, `клік`/`кліка`/`кліків`)
- **`AdjustmentDisplayPanel`** — click values pluralized via `nClicks(count)`; Sg abbreviation localized
- **`AdjustmentInputWithClicks`** — click suffix pluralizes reactively on keystroke
- **Ukrainian `unitCmPer100mSym`** — `"cm/100m"` → `"см/100м"`
- **Android keyboard overlap** — `resizeToAvoidBottomInset: false` on `_ScaffoldWithNav`; keyboard overlays shell content instead of shrinking it; sub-screens (`BaseScreen`) retain default `true`
- **Desktop window size** — removed erroneous `* devicePixelRatio` multiplication; `window_manager` takes logical pixels, not physical; window now opens at correct `375×812` logical size


## [0.1.3] - 2026-04-28

### Added

- **Localization (EN/UA) — full pass** — ARB pipeline; ~375 keys, EN = UK in sync; all screens covered: settings, convertors, conditions, tables, home, shot details, profiles, ammo/weapon/sight wizards, collection tiles, reticle view screen, unit pickers; `Unit.localizedLabel/Symbol(l10n)` extension + 34 `unitXxxSym` ARB keys; `UnitFormatterImpl` takes `AppLocalizations`; all formatted values and unit symbols localized

### Changed

- **Navigation bar labels** — `NavigationBarTheme` with `fontSize: 11` + `TextOverflow.ellipsis` for long localized labels
- **Home screen** — condition indicators, page labels, wind direction display prettified

### Fixed

- **A7P zero offset export** — offset now correctly converted to cm/100m before dividing by click size (previously multiplied)
- **A7P zero offset import** — removed erroneous offset reconstruction; a7p click counts carry no click-size metadata
- **Wheel picker `-0.0`** — `formatDisplayValue` normalises IEEE 754 negative zero before `toStringAsFixed`
- **Built-in collection** — fix sight heights
- **Settings screen** — fix sight height unit picker

### Refactored

- **Code quality — converter generalization** (#7.1 #1–2) — `SimpleConvertorVm` base + `SimpleConvertorScreen`; 5 VMs + 5 screens unified; ~870 LOC removed
- **Code quality — table editor generalization** (#7.1 #3) — `TwoColumnTableEditorScreen` generic widget; multi-BC + powder sens editors unified; ~545 LOC removed
- **Code quality — wizard deduplication** (#7.1 #4) — `WizardActionBar`, `WizardNameField`, `WizardFormMixin`; applied to all 3 wizard screens; ~155 LOC removed
- **Code quality — `home_vm.dart` split** (#7.1 #5) — `home_ui_state.dart` + `home_builders.dart` extracted; notifier reduced to orchestration only
- **Code quality — `ammo_wizard_screen.dart` split** (#7.1 #6) — `ammo_wizard_parsers.dart` + `AmmoWizardNotifier`; 30 `setState` removed; 77 new tests
- **Code quality — `profile_card.dart` split** (#7.1 #7) — `ProfileControlTile`, `ProfileWeaponSection`, `ProfileAmmoSection`, `ProfileSightSection` extracted; 504 → 145 lines
- **Code quality — dialog/snackbar helpers** (#7.1 #8) — `showFeedback()` helper; 4 inline `showSnackBar` calls replaced
- **Code quality — UI constants + dividers** (#7.1 #9) — `ui_dimensions.dart`; `TileDivider`/`SectionDivider` widgets; 47 inline `Divider` calls replaced
- **Code quality — asset picker generalization** (#7.1 #10) — `SvgAssetPickerScreen<T>` generic; pickers as 22-line wrappers
- **Code quality — wizard notifiers** (#7.1 #11) — `WeaponWizardNotifier` + `SightWizardNotifier`; all `setState` removed from both screens
- **Code quality — `AdjustmentsDisplayPanel` disabled state** (#7.1 #12) — `_buildEmpty` implemented; test updated
- **Code quality — standalone widget extraction** (#7.1 #13) — `_BcSection` + `_DragModelSection` replace builder methods in `ammo_wizard_screen.dart`
- **Code quality — naming conventions** (#7.1 #14) — widget/class/provider naming rules + localization rule documented in `CLAUDE.md`
- **Unit picker** — `UnitPickerTile` and `UnitPickerButton` share reusable `showUnitPicker`


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