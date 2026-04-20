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
