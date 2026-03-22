import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/models/shot_profile.dart';
import '../src/solver/calculator.dart';
import '../src/solver/trajectory_data.dart';
import '../src/solver/unit.dart';
import 'shot_profile_provider.dart';

HitResult? _runCalculation(ShotProfile profile) {
  try {
    final calc = Calculator();
    return calc.fire(
      shot: profile.toShot(),
      trajectoryRange: Distance(2000.0, Unit.meter),
      trajectoryStep:  Distance(100.0,  Unit.meter),
    );
  } catch (_) {
    return null;
  }
}

/// Reactive calculation — recalculates whenever [shotProfileProvider] changes.
/// Runs [Calculator] in an isolate via [compute] to keep the UI thread free.
final calculationProvider = FutureProvider<HitResult?>((ref) async {
  final profile = ref.watch(shotProfileProvider).value;
  if (profile == null) return null;
  return compute(_runCalculation, profile);
});
