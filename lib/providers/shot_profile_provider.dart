import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/models/cartridge.dart';
import '../src/models/rifle.dart';
import '../src/models/seed_data.dart';
import '../src/models/shot_profile.dart';
import '../src/models/sight.dart';
import '../src/solver/conditions.dart';
import '../src/solver/unit.dart';
import 'storage_provider.dart';

class ShotProfileNotifier extends AsyncNotifier<ShotProfile> {
  @override
  Future<ShotProfile> build() async {
    return await ref.read(appStorageProvider).loadCurrentProfile()
        ?? seedShotProfile;
  }

  Future<void> selectRifle(Rifle r) =>
      _update((p) => p.copyWith(rifle: r));

  Future<void> selectSight(Sight s) =>
      _update((p) => p.copyWith(sight: s));

  Future<void> selectCartridge(Cartridge c) =>
      _update((p) => p.copyWith(cartridge: c));

  Future<void> updateConditions(Atmo atmo) =>
      _update((p) => p.copyWith(conditions: atmo));

  Future<void> updateWinds(List<Wind> winds) =>
      _update((p) => p.copyWith(winds: winds));

  Future<void> updateLookAngle(double degrees) =>
      _update((p) => p.copyWith(lookAngle: Angular(degrees, Unit.degree)));

  Future<void> updateTargetDistance(double meters) =>
      _update((p) => p.copyWith(
        // targetDistance is not on ShotProfile directly — stored externally
        // This is a placeholder for when we add that field
      ));

  Future<void> _update(ShotProfile Function(ShotProfile) fn) async {
    final current = state.value ?? seedShotProfile;
    final updated = fn(current);
    state = AsyncData(updated);
    await ref.read(appStorageProvider).saveCurrentProfile(updated);
  }
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>(ShotProfileNotifier.new);
