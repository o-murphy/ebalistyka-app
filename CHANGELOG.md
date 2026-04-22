# Changelog

## [0.1.0+7] — 2026-04-22

### Architecture
- **Removed recalc_coordinator** - the widgets now listens objectbox streams with provider

### Changed
- **Complete UI for CRUD** - allows to create and manage user's ballistics data
- **A7P as local package** - a7p serializer moved to `packages/a7p`
  
### Add
- **Reticle generator CLI** - creates compatible reticles and target SVG image
- **App launcher icons and splashscreen**

### Features
- **Export/Import** - allows export user's data in native or .A7P format
- **Screen for Reticles** - retilcle view and screen to display and manage adjustments
- **Unit convertors** - fully implemented all convertors

### Fixes
- **Twist and wind direction**

### Docs
- **Backlog** - updated backlog docs
- **Docs timeline** - updated docs with time-based numeration


## [0.1.0-alpha] — 2026-04-12

Initial alpha release. First functional build of the ballistic trajectory calculator.

### Architecture

- **ObjectBox migration** — full replacement of JSON file storage with ObjectBox reactive database; entities, relations, and streams for all domain models (Weapon, Ammo, Sight, Profile, Settings, Conditions)
- **bclibc as local package** — C++ ballistic solver extracted to `packages/bclibc_ffi`; bumped to v1.0.3
- **Reactive providers** — all settings and conditions providers rebuilt on ObjectBox watch streams; any DB write triggers automatic UI update
- **Zero key caching** — zero phase skipped when zero-relevant inputs are unchanged
- **Get/set extensions** — raw entity fields replaced with typed extensions across the codebase

### Features

- **Profiles screen** — PageView with per-profile cards; create, rename, duplicate, remove; active profile pinned first
- **Profile card** — weapon / ammo / sight sections with inline edit; `IncompleteBanner` when ammo or sight not selected
- **Weapon wizard** — create / edit weapon with caliber, twist, barrel length; pre-fill from built-in collection
- **Sight wizard** — full form: name, optics (FFP/SFP/LWIR), mounting height/offset, click values, magnification range; create / edit / pre-fill from collection
- **Ammo & sight selection screens** — per-profile pick from existing items or create new
- **Built-in collection** — `collection.json` with calibers, weapons, cartridges, projectiles, sights; collection provider wired
- **Unit converters** — 6 of 8 implemented: length, weight, pressure, temperature, torque, angular
- **Generic convertor field** — reusable two-field real-time conversion widget
- **Dimension factory constructors** — typed constructors for all unit dimensions

### Fixes

- Profiles paging reorder logic (active profile always first)
- Filter and sort order in ammo selection screen
- Tables settings changes now apply immediately
- Duplicate profile / ammo / sight logic; seed weapons deduplication
- Coriolis force applied to current conditions correctly
- Home screen results accuracy (holdover, windage)
- Home table hold value bug
- Wizard reusable form validation (touched-flag pattern)
- Twist direction icon display
- Shot details table values

### CI / Build

- GitHub Actions workflows: Linux AppImage and Windows EXE builds on PR
- Reusable `build.yml` with platform/arch/build-type matrix
- Pre-build setup step (submodule init, FFI bindings generation)

### Docs

- `README.md` with badges, screenshots, feature overview, build instructions, dependency table
- `LICENSE` — GPL-3.0
- `OBJECTBOX_MIGRATION.md` — migration notes
