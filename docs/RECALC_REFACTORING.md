# RecalcCoordinator Removal & ViewModel Listener Refactoring

**Date:** April 21, 2026  
**Status:** ✅ COMPLETED

## Overview

On April 21, 2026, `lib/core/providers/recalc_coordinator.dart` was **completely removed** and replaced with a distributed listener pattern directly in each ViewModel.

### Previous Architecture (Centralized)

```
recalcCoordinatorProvider
├── watches shotContextProvider
├── watches settingsProvider
├── watches unitSettingsProvider
├── watches reticleSettingsProvider
└── triggers recalculate() on all 3 ViewModels
    ├── homeVmProvider
    ├── shotDetailsVmProvider
    └── trajectoryTablesVmProvider
```

**Problem:** When `recalcCoordinatorProvider` was disposed, it called `recalculate()` on disposed providers, causing "Cannot use Ref after disposal" errors.

### New Architecture (Distributed)

Each ViewModel now manages its own listeners directly in `build()`:

```dart
@override
Future<HomeUiState> build() async {
  // Each ViewModel watches its dependencies with fireImmediately: true
  ref.listen<AsyncValue<ShotContext?>>(
    shotContextProvider,
    (_, next) => { if (next.hasValue) _recalculate(); },
    fireImmediately: true,  // ← Key: triggers immediately on first build
  );
  ref.listen<AsyncValue<GeneralSettings>>(
    settingsProvider,
    (prev, next) => { if (_generalNeedsRecalc(prev?.value, next.value!)) _recalculate(); },
    fireImmediately: true,
  );
  // ... more listeners
  return const HomeUiNoData(type: EmptyStateType.noProfile);
}

Future<void> _recalculate() async {
  // ... calculation
  if (!ref.mounted) return;  // Safety: check before writing state after async gaps
  state = AsyncData(result);
}
```

## Files Modified

### Deleted
- ✅ `lib/core/providers/recalc_coordinator.dart` — entire file removed
- ✅ `test/core/recalc_coordinator_test.dart` — test file for deleted provider

### Modified

#### 1. **lib/features/home/home_vm.dart**
   - Moved 4 listeners from `RecalcCoordinator` into `build()`
   - Added `fireImmediately: true` to all listeners
   - Renamed `public recalculate()` → `private _recalculate()`
   - Added `ref.mounted` checks after async gaps

#### 2. **lib/features/home/shot_details_vm.dart**
   - Moved 3 listeners into `build()`
   - Added `fireImmediately: true`
   - Renamed `public recalculate()` → `private _recalculate()`
   - Added `ref.mounted` checks

#### 3. **lib/features/tables/trajectory_tables_vm.dart**
   - Moved listeners into `build()`
   - Added `fireImmediately: true`
   - Renamed `public recalculate()` → `private _recalculate()`
   - Added `_rebuild()` for non-calculation listener (`tablesSettingsProvider`, `unitSettingsProvider`)
   - Added `ref.mounted` checks

#### 4. **lib/router.dart**
   - Removed import of `recalcCoordinatorProvider`
   - Removed `ref.watch(recalcCoordinatorProvider)` initialization
   - Removed `ref.read(recalcCoordinatorProvider.notifier).onTabActivated(i)` calls
   - Removed `WidgetsBinding.instance.addPostFrameCallback()` trigger

#### 5. **.claude/settings.local.json**
   - Removed obsolete sed commands for `recalc_coordinator.dart` import fixes

### Documentation Updates

- ✅ `docs/1.REFACTORING_PLAN.md` — marked Phase 3 as DONE & REMOVED
- ✅ `docs/2.REFACTORING_PLAN_2.md` — updated completion notes
- ✅ `docs/3.OBJECTBOX_MIGRATION.md` — removed `recalc_coordinator.dart` reference
- ✅ `docs/4.PROFILES_CRUD_PLAN.md` — marked as REMOVED with explanation

## Key Changes in Logic

### 1. `fireImmediately: true` — Critical Fix

When a provider is already saturated (value available) **before** attaching a listener, the listener will only fire on **subsequent changes** unless `fireImmediately: true` is set.

**Scenario:** User launches the app → ObjectBox loads `ShotContext` → `shotContextProvider` is ready before `homeVmProvider.build()` attaches its listener.

**Without `fireImmediately: true`:** Listener never fires → calculation never happens → screen stays Loading.

**With `fireImmediately: true`:** Listener fires immediately with current value → `_recalculate()` triggered → screen populated.

### 2. `ref.mounted` Checks — Preventing "Reference After Disposal" Errors

When ViewModels are disposed while async operations (`await service.calculate()`) are in progress, Riverpod prevents state updates:

```dart
try {
  final result = await ref.read(ballisticsServiceProvider).calculateForTarget(...);
  if (!ref.mounted) return;  // ← Check before state update
  state = AsyncData(result);
} catch (e) {
  if (ref.mounted) {  // ← Also check in catch block
    state = AsyncData(HomeUiError(e.toString()));
  }
}
```

## Test Updates

### Deleted
- `test/core/recalc_coordinator_test.dart`

### Updated
- `test/features/home/home_vm_test.dart` — changed from `_recalculate(container)` (manual call) to `_waitFor<T>(container)` (listener-driven)
- `test/features/tables/tables_vm_test.dart` — same pattern

### Test Pattern Change

**Old (manual recalculate):**
```dart
Future<HomeUiReady> _recalculate(ProviderContainer container) async {
  await container.read(shotContextProvider.future);
  final notifier = container.read(homeVmProvider.notifier);
  await notifier.recalculate();  // ← manually called public method
  return container.read(homeVmProvider).value as HomeUiReady;
}
```

**New (listener-driven):**
```dart
Future<T> _waitFor<T extends HomeUiState>(ProviderContainer container) {
  final completer = Completer<T>();
  late ProviderSubscription<AsyncValue<HomeUiState>> sub;
  sub = container.listen<AsyncValue<HomeUiState>>(
    homeVmProvider,
    (_, value) {
      if (value.value is T) {
        completer.complete(value.value! as T);
        sub.close();
      }
    },
    fireImmediately: true,
  );
  return completer.future;  // ← Waits for listener to deliver state
}
```

## Benefits of New Architecture

1. **No disposal race conditions** — Each ViewModel only writes to its own state
2. **Immediate calculations on app launch** — `fireImmediately: true` ensures first calculation
3. **Simpler testing** — Tests wait for natural listener events, not manual calls
4. **Decoupled ViewModels** — No single point of failure (coordinator)
5. **Transparent dependency tracking** — Riverpod sees all provider dependencies directly

## Issues Fixed

- ✅ Table not displaying on app startup (caused by missing `fireImmediately: true`)
- ✅ "Cannot use Ref after disposal" errors in tests
- ✅ Inconsistent recalculation triggers between home and tables screens

## Verification

Run full test suite:
```bash
make test
# or
flutter test
```

All tests should pass. Run app:
```bash
flutter run -d linux
# (or any target platform)
```

Profiles, ammo, sight settings should display immediately without manual tab switching.
