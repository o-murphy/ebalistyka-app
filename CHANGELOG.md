# Changelog


## [Unreleased]

### Android
- **Initial Android support** — app runs on Android; submodule and FFI build integrated into CI
- **Impeller disabled** — Flutter's Impeller renderer tessellates SVG circles as polygons; forced Skia via `EnableImpeller=false` in `AndroidManifest.xml` until upstream fix
- **AndroidManifest** — added storage permissions (`READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`), `requestLegacyExternalStorage`, FileProvider for `share_plus`, `<queries>` for `file_picker` and `url_launcher`
- **File import** — `file_picker` falls back to `FileType.any` on Android (custom extensions unsupported by Android MIME resolver); extension validated after selection with user-visible error on mismatch
- **URL launch** — `_launchUrl` now falls back to `LaunchMode.platformDefault` if `externalApplication` fails; `https`/`http` queries added to manifest for Android 11+ package visibility

### Fixed
- **Window scaling** — uses system scale for initial app window size
- **AdjustmentDisplay** — takes into account zeroOffsets and adjustments
- **SVG circles rendered as polygons** — `dotLine` / `dotGrid` in `reticle_gen` now emit `<circle>` SVG elements instead of `<path>` arc commands; all reticle and target SVGs regenerated
- **RenderFlex overflow on home screen** — removed hardcoded `SizedBox(height: 8)` spacer; `Column` now uses `mainAxisAlignment: MainAxisAlignment.center`
- **PageDotsIndicator overflow** — `IconButton` tap target forced to `MaterialTapTargetSize.shrinkWrap` so actual height matches the declared 32 px constraint
- **Bug in HomeScreen -> AmmoWizard route** — await new state form route
- **Add analysis rule** - discarded_futures: true, fixed all relative issues

### CI / Build
- **`build-apk.yml` reusable** — workflow now supports `workflow_call` (same pattern as `build.yml`); accepts `build_name`, `build_type`, `retention_days` inputs and signing secrets; PR trigger and summary comment preserved
- **`release.yml`** — inline Android job replaced with `uses: build-apk.yml`; `*.apk` added to release asset collection
- **Android APK signing** — `build.gradle.kts` reads `android/key.properties` and configures a `release` signing config; falls back to debug key when file is absent
- **`scripts/build-android.sh`** — new script: sets pubspec version, decodes keystore from `ANDROID_KEYSTORE_BASE64` env var, builds split-per-ABI APKs, packages to `artifacts/`
- **`scripts/generate-android-keystore.sh`** — generates JKS keystore via `keytool`, writes `android/key.properties` for local builds, copies keystore + base64 + secrets summary to `certs/`

### Reliability
- **Database resilience** — `_openStore` in `main.dart` catches ObjectBox open failures; deletes `data.mdb` / `lock.mdb` and re-initialises a fresh store; shows a SnackBar warning only when prior data existed (skipped on first install)

### Docs
- **README** — added `## Android notes` section documenting Impeller workaround and file import behaviour


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