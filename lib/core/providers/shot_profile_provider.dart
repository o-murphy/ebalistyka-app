import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:riverpod/riverpod.dart';

class ShotProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final appState = await ref.watch(appStateProvider.future);
    return appState.activeProfile;
  }

  Future<void> selectProfile(Profile profile) async {
    await ref.read(appStateProvider.notifier).setActiveProfile(profile);
  }

  Future<void> selectWeapon(Weapon weapon) async {
    final profile = state.value;
    if (profile == null) return;
    profile.weapon.target = weapon;
    await ref.read(appStateProvider.notifier).saveProfile(profile);
  }

  Future<void> selectSight(Sight sight) async {
    final profile = state.value;
    if (profile == null) return;
    profile.sight.target = sight;
    await ref.read(appStateProvider.notifier).saveProfile(profile);
  }

  Future<void> selectAmmo(Ammo ammo) async {
    final profile = state.value;
    if (profile == null) return;
    profile.ammo.target = ammo;
    await ref.read(appStateProvider.notifier).saveProfile(profile);
  }
}

final shotProfileProvider = AsyncNotifierProvider<ShotProfileNotifier, Profile?>(
  ShotProfileNotifier.new,
);
