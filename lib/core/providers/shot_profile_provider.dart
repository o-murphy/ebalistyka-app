import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/models/cartridge.dart';
import 'package:ebalistyka/core/models/rifle.dart';
import 'package:ebalistyka/core/models/seed_data.dart';
import 'package:ebalistyka/core/models/shot_profile.dart';
import 'package:ebalistyka/core/models/sight.dart';

class ShotProfileNotifier extends AsyncNotifier<ShotProfile> {
  @override
  Future<ShotProfile> build() async {
    final appState = ref.watch(appStateProvider);

    return appState.when(
      loading: () => seedShotProfile,
      error: (_, _) => seedShotProfile,
      data: (state) {
        final activeId = state.activeProfileId;
        final profiles = state.profiles;

        if (activeId != null) {
          final matches = profiles.where((p) => p.id == activeId);
          if (matches.isNotEmpty) {
            return _resolve(matches.first, state);
          }
        }

        return profiles.isNotEmpty
            ? _resolve(profiles.first, state)
            : seedShotProfile;
      },
    );
  }

  // ---- Resolve cartridge/sight з глобального стану ----
  ShotProfile _resolve(ShotProfile profile, AppState appState) {
    String? cartridgeId = profile.cartridgeId;
    Cartridge? cartridge = profile.cartridge;
    String? sightId = profile.sightId;
    Sight? sight = profile.sight;

    // Якщо є вбудований cartridge (backward-compat) - зберігаємо в глобальний стан
    if (cartridge != null && cartridgeId == null) {
      // Створюємо ID якщо немає
      cartridgeId = cartridge.id;
      _saveCartridgeToGlobalState(cartridge);
    }

    // Шукаємо cartridge в глобальному стані
    if (cartridgeId != null) {
      final found = appState.cartridges.where((c) => c.id == cartridgeId);
      if (found.isNotEmpty) {
        cartridge = found.first;
      } else {
        // Зламаний референс - обнуляємо
        cartridgeId = null;
        cartridge = null;
        // TODO: show toast "Cartridge not found"
      }
    }

    // Аналогічно для sight
    if (sight != null && sightId == null) {
      sightId = sight.id;
      _saveSightToGlobalState(sight);
    }

    if (sightId != null) {
      final found = appState.sights.where((s) => s.id == sightId);
      if (found.isNotEmpty) {
        sight = found.first;
      } else {
        sightId = null;
        sight = null;
        // TODO: show toast "Sight not found"
      }
    }

    // Якщо референси змінились - зберігаємо оновлений профіль
    if (cartridgeId != profile.cartridgeId || sightId != profile.sightId) {
      final cleaned = ShotProfile(
        id: profile.id,
        name: profile.name,
        rifle: profile.rifle,
        cartridgeId: cartridgeId,
        cartridge: cartridge,
        sightId: sightId,
        sight: sight,
      );
      _saveProfileToGlobalState(cleaned);
      return cleaned;
    }

    return ShotProfile(
      id: profile.id,
      name: profile.name,
      rifle: profile.rifle,
      cartridgeId: cartridgeId,
      cartridge: cartridge,
      sightId: sightId,
      sight: sight,
    );
  }

  // ---- Допоміжні методи для роботи з глобальним станом ----
  Future<void> _saveCartridgeToGlobalState(Cartridge cartridge) async {
    final notifier = ref.read(appStateProvider.notifier);
    await notifier.saveCartridge(cartridge);
  }

  Future<void> _saveSightToGlobalState(Sight sight) async {
    final notifier = ref.read(appStateProvider.notifier);
    await notifier.saveSight(sight);
  }

  Future<void> _saveProfileToGlobalState(ShotProfile profile) async {
    final notifier = ref.read(appStateProvider.notifier);
    await notifier.saveProfile(profile);
  }

  // ---- Public API ----
  Future<void> selectRifle(Rifle r) => _update((p) => p.copyWith(rifle: r));

  Future<void> selectSight(Sight s) => _update((p) => p.copyWith(sight: s));

  Future<void> selectCartridge(Cartridge c) =>
      _update((p) => p.copyWith(cartridge: c));

  Future<void> selectProfile(ShotProfile profile) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final resolved = _resolve(profile, appState);
    state = AsyncData(resolved);

    final notifier = ref.read(appStateProvider.notifier);
    await notifier.saveActiveProfileId(resolved.id);
  }

  Future<void> _update(ShotProfile Function(ShotProfile) fn) async {
    final current = state.value ?? seedShotProfile;
    final updated = fn(current);
    state = AsyncData(updated);

    final notifier = ref.read(appStateProvider.notifier);
    await notifier.saveProfile(updated);
  }
}

final shotProfileProvider =
    AsyncNotifierProvider<ShotProfileNotifier, ShotProfile>(
      ShotProfileNotifier.new,
    );
