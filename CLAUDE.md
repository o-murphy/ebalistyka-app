# Project conventions for AI agents

## Entity fields — always use extension getters/setters

**Never** read or write raw storage fields on ObjectBox entities directly (e.g. `velocityValueMps`, `velocityAtmoTemperatureC`, `lengthValueInch`).

Always go through the typed extension getters/setters defined in `lib/core/extensions/`:

```dart
// WRONG
s.velocityAtmoTemperatureC = 15.0;
final t = s.velocityAtmoTemperatureC;

// CORRECT
s.velocityAtmoTemperature = Temperature.celsius(15.0);
final t = s.velocityAtmoTemperature; // returns Temperature
```

**Rule:** whenever you add new fields to an entity, immediately add the corresponding typed getter/setter to the appropriate `*_extensions.dart` file **before** using the field anywhere else.

Relevant extension files:
- `lib/core/extensions/convertors_extensions.dart` — `ConvertorsState`
- `lib/core/extensions/settings_extensions.dart` — `UnitSettings` / `AppSettings`
- `lib/core/extensions/ammo_extensions.dart` — `Ammo`

---

## Widget naming conventions

### Private widgets: standalone classes, not builder methods

**Never** add private builder methods (`_buildXxx(...)`) to a `State` or widget class when the result can be a standalone `StatelessWidget` or `ConsumerWidget`.

```dart
// WRONG — builder method on state
Widget _buildDragModel(AppLocalizations l10n, AmmoWizardState st) { ... }
List<Widget> _buildBcSection({required ..., ...}) { ... }

// CORRECT — standalone private widget class
class _DragModelSection extends StatelessWidget { ... }
class _BcSection extends StatelessWidget { ... }
```

**Rule:** extract reusable or logically distinct UI blocks as private widget classes (`_PascalCase`). Builder methods are only acceptable for one-liners that are too trivial to warrant a class.

### File-level widget section

Place all private widget classes at the bottom of the file, separated from the screen class by:

```dart
// ── Widgets ───────────────────────────────────────────────────────────────────
```

### Class naming

| Kind | Convention | Example |
|---|---|---|
| Screen / page | `PascalCaseScreen` | `AmmoWizardScreen` |
| Sub-widget (public) | `PascalCaseSection` / `PascalCaseTile` / `PascalCasePanel` | `PowderSensSection` |
| Sub-widget (private) | `_PascalCase` | `_DragModelSection`, `_BcSection` |
| ViewModel notifier | `PascalCaseNotifier` / `PascalCaseVm` | `AmmoWizardNotifier` |
| Provider | `camelCaseProvider` | `ammoWizardProvider` |
| State class (frozen) | `PascalCaseState` | `AmmoWizardState` |

### Localization

**Never** hard-code user-visible strings. Always use `AppLocalizations.of(context)!` (or the `l10n` local variable) for all labels, subtitles, and messages.

```dart
// WRONG
Text('No profiles. Tap + to add one.')

// CORRECT
Text(l10n.noProfiles)
```

Unit symbols and labels must use the `localizedSymbol(l10n)` / `localizedLabel(l10n)` extension from `lib/core/extensions/unit_label_extensions.dart`.
