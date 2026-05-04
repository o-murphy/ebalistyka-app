# Ballistics Sign Conventions

> **Doc #8 — Status: REFERENCE 📖**  
> Explains sign conventions for twist, wind direction, windage display. Read before touching physics/FFI code.

This document explains the sign conventions used throughout the app for twist
direction, wind direction, and windage display. These conventions are
non-obvious because the C library (`bclibc`) and the app's UI use different
coordinate frames that must be reconciled in Dart.

---

## Twist Direction

### Storage (`Weapon.twistInch`)

| Value | Meaning |
|-------|---------|
| positive | Right-hand (RH) twist |
| negative | Left-hand (LH) twist |

Defined by `WeaponExtension.isRightHandTwist` in
`lib/core/extensions/weapon_extensions.dart`:
```dart
bool get isRightHandTwist => twistInch >= 0.0;
```

The weapon wizard writes `_rightHand ? _twistRaw : -_twistRaw`, so the sign is
set correctly at entry time.

### C library (`bclibc`) — same convention

`bclibc` receives `twist_inch` with the same sign. Inside `spin_drift()`:
```cpp
if (this->twist > 0) sign = 1.0;   // RH → rightward drift
else                 sign = -1.0;  // LH → leftward drift
```
Positive `twist_inch` → positive `spin_drift` → positive `windage_angle_rad`
(bullet displaced **right**). No sign inversion is needed between Dart and C.

### a7p import

`A7pParser` reads `p.twistDir` (proto enum `RIGHT = 0`, `LEFT = 1`) and stores
a negative value for left-hand twist:
```dart
..twist = Distance.inch(
  p.twistDir == proto.TwistDir.LEFT ? -(p.rTwist / 100.0) : p.rTwist / 100.0,
)
```

---

## Wind Direction

### UI storage (`ShootingConditions.windDirectionDeg`)

The wind indicator (`WindIndicator`) is a clock face.  
**Convention: the stored angle is the direction the wind is blowing FROM.**

| Clock position | Degrees | Meaning |
|---------------|---------|---------|
| 12 o'clock | 0° | wind from 12 o'clock (from ahead / headwind) |
| 3 o'clock | 90° | wind from the right → bullet pushed **left** |
| 6 o'clock | 180° | wind from behind (tailwind) |
| 9 o'clock | 270° | wind from the left → bullet pushed **right** |

### C library — opposite convention

`bclibc`'s wind formula is:
```cpp
z = vel * sin(direction_from_rad)   // positive z = air moves RIGHT
x = vel * cos(direction_from_rad)
```

For `direction = 90°` this gives `z = +vel`, meaning the **air mass moves
right**, which pushes the bullet **right**. But the UI stores 90° as "wind
*from* the right", which should push the bullet **left** — the opposite.

### Fix in `conditions_extensions.dart`

`toWind()` adds π before passing the angle to the C library, converting the
"from" direction into the "to" direction:
```dart
directionFrom: Angular.radian(windDirection.in_(Unit.radian) + pi),
```

This makes the physics correct without changing how the angle is stored or
displayed to the user.

---

## Windage Display (`windageAngle`)

### C library output

`windage_angle_rad` is the **lateral displacement angle of the bullet**:

| Sign | Meaning |
|------|---------|
| positive | bullet displaced to the **right** |
| negative | bullet displaced to the **left** |

Both wind and spin drift contribute to this single field:
```cpp
windage_ft = adjusted_range.z + spin_drift(time);
windage_angle_rad = atan(windage_ft / distance);
```

### Display convention in the app

`windageAngle` is shown **without negation** — positive = bullet went right.

```dart
// home_vm.dart
final windMil = targetPoint?.windageAngle.in_(Unit.mil) ?? 0.0;

// _buildAdjustment
final corr = windAngle.in_(u.$1);
```

This means:
- **RH spin drift** (bullet right) → displayed as **positive / right** ✓
- **Wind from right** (bullet left, after the +π fix above) → displayed as
  **negative / left** ✓

The reticle dot, adjustment arrows, and trajectory table all use this same
sign: **positive = rightward displacement**.

> **Note:** This is the *displacement* convention, not the *scope-dial
> correction* convention. If the displayed value is +0.3 MIL (bullet goes
> right), the shooter dials the scope **left** by 0.3 MIL (or holds the
> right-of-center BDC mark on target) to compensate.

---

## Summary table

| Item | Positive value means |
|------|---------------------|
| `Weapon.twistInch` | Right-hand (RH) twist |
| `windDirectionDeg` | Wind blowing **from** that clock angle |
| `windageAngleRad` (C output) | Bullet displaced to the **right** |
| `windMil` / `corr` (display) | Bullet displaced to the **right** |
