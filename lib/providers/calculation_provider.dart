import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/models/shot_profile.dart';
import '../src/solver/calculator.dart';
import '../src/solver/ffi/bclibc_bindings.g.dart';
import '../src/solver/shot.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';
import 'settings_provider.dart';
import 'shot_profile_provider.dart';

HitResult? _runCalculation((ShotProfile, double) args) {
  final (profile, stepM) = args;
  try {
    final calc = Calculator();
    // If zero-finding fails (e.g. look angle is corrupted / out of range),
    // fall back to lookAngle = 0 so the user still gets trajectory data.
    Shot shot;
    try {
      shot = profile.toShot();
      calc.setWeaponZero(shot, Distance(100.0, Unit.meter));
    } catch (_) {
      shot = profile.copyWith(lookAngle: Angular(0.0, Unit.radian)).toShot();
      calc.setWeaponZero(shot, Distance(100.0, Unit.meter));
    }
    return calc.fire(
      shot: shot,
      trajectoryRange: Distance(2000.0, Unit.meter),
      trajectoryStep:  Distance(stepM,  Unit.meter),
      filterFlags: BCTrajFlag.BC_TRAJ_FLAG_RANGE | BCTrajFlag.BC_TRAJ_FLAG_ZERO,
    );
  } catch (e, st) {
    // ignore: avoid_print
    print('_runCalculation error: $e\n$st');
    return null;
  }
}

class CalculationNotifier extends AsyncNotifier<HitResult?> {
  bool _dirty = true;

  @override
  Future<HitResult?> build() async {
    // No ref.watch/listen here — keeps this notifier dependency-free
    // so build() is never re-run and state is never reset unexpectedly.
    return null; // lazy — calculate only when requested
  }

  /// Called externally when the shot profile changes.
  void markDirty() => _dirty = true;

  Future<void> recalculateIfNeeded() async {
    if (!_dirty) return;
    final profile = ref.read(shotProfileProvider).value;
    if (profile == null) return;
    final stepM = ref.read(settingsProvider).value?.tableDistanceStep ?? 100;
    _dirty = false;
    state = const AsyncLoading();
    state = AsyncData(await compute(_runCalculation, (profile, stepM)));
  }
}

final calculationProvider =
    AsyncNotifierProvider<CalculationNotifier, HitResult?>(CalculationNotifier.new);
