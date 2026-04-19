# Post-Alpha UX Features

Features that are not alpha release blockers. Architecture and approach for each is TBD.

---

## Localization uk/en

- ARB + ​​`flutter_localizations`
- Languages: Ukrainian (main) + English
- Covers all UI lines, including unit names, validation errors, labels

---

## RulerSelector

Touch-drag ruler for `QuickActionsPanel` on HomeScreen.
Replaces or complements current quick access buttons.
Interaction details TBD.

---

## Reticle Fullscreen

Opens from Home Page 1 (HomeReticlePage).
Full-screen view of the reticle with corrections.
Depends on the reticle display implementation - see [RETICLES_AND_IMAGES.md](RETICLES_AND_IMAGES.md).

---

## Help Overlay / Coach Marks

Hints on first run or upon user request.
TBD library (e.g. `tutorial_coach_mark`).

---

## Tools Screen

Opened from the "More" button on the HomeScreen (currently `showNotAvailableSnackBar`).
Utility set — composition TBD.

---

## Settings — Legal / Info Links

- Privacy Policy
- Terms of Use
- Changelog
- GitHub link (minimum for alpha — may move to Alpha TODO)

---

## Implemented (carried over from Post-Alpha)

- [x] **.a7p import/export** — `packages/a7p` (A7pFile, A7pConverter, A7pValidator, proto-scheme); `A7pService` у `lib/core/services/`
- [x] **Profile export** — bottom sheet with format selection: .ebcp / .a7p
- [x] **Profile import** — single FilePicker (.ebcp + .a7p), auto-detect by extension
- [x] **Full backup** — Settings → "Export backup" / "Import backup" (.ebcp)
