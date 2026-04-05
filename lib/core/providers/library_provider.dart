import 'package:eballistica/core/models/shot_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/models/cartridge.dart';
import 'package:eballistica/core/models/seed_data.dart';
import 'package:eballistica/core/models/sight.dart';
import 'storage_provider.dart';

// ── Sights ────────────────────────────────────────────────────────────────────

class SightLibraryNotifier extends AsyncNotifier<List<Sight>> {
  @override
  Future<List<Sight>> build() async {
    final sights = await ref.read(appStorageProvider).loadSights();
    if (sights.isEmpty) {
      await ref.read(appStorageProvider).saveSight(seedSight);
      return [seedSight];
    }
    return sights;
  }

  Future<void> save(Sight s) async {
    await ref.read(appStorageProvider).saveSight(s);
    state = AsyncData([
      for (final item in (state.value ?? []))
        if (item.id == s.id) s else item,
      if (!(state.value ?? []).any((item) => item.id == s.id)) s,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteSight(id);
    state = AsyncData((state.value ?? []).where((s) => s.id != id).toList());
  }
}

final sightLibraryProvider =
    AsyncNotifierProvider<SightLibraryNotifier, List<Sight>>(
      SightLibraryNotifier.new,
    );

// ── Cartridges ────────────────────────────────────────────────────────────────

class CartridgeLibraryNotifier extends AsyncNotifier<List<Cartridge>> {
  @override
  Future<List<Cartridge>> build() async {
    final cartridges = await ref.read(appStorageProvider).loadCartridges();
    if (cartridges.isEmpty) {
      for (final c in seedCartridges) {
        await ref.read(appStorageProvider).saveCartridge(c);
      }
      return seedCartridges;
    }
    return cartridges;
  }

  Future<void> save(Cartridge c) async {
    await ref.read(appStorageProvider).saveCartridge(c);
    state = AsyncData([
      for (final item in (state.value ?? []))
        if (item.id == c.id) c else item,
      if (!(state.value ?? []).any((item) => item.id == c.id)) c,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteCartridge(id);
    state = AsyncData((state.value ?? []).where((c) => c.id != id).toList());
  }
}

final cartridgeLibraryProvider =
    AsyncNotifierProvider<CartridgeLibraryNotifier, List<Cartridge>>(
      CartridgeLibraryNotifier.new,
    );

class ProfileLibraryNotifier extends AsyncNotifier<List<ShotProfile>> {
  @override
  Future<List<ShotProfile>> build() async {
    final profiles = await ref.read(appStorageProvider).loadProfiles();
    if (profiles.isEmpty) {
      for (final p in seedShotProfiles) {
        await ref.read(appStorageProvider).saveProfile(p);
      }
      return seedShotProfiles;
    }
    return profiles;
  }

  Future<void> save(ShotProfile p) async {
    await ref.read(appStorageProvider).saveProfile(p);
    state = AsyncData([
      for (final item in (state.value ?? []))
        if (item.id == p.id) p else item,
      if (!(state.value ?? []).any((item) => item.id == p.id)) p,
    ]);
  }

  Future<void> delete(String id) async {
    await ref.read(appStorageProvider).deleteProfile(id);
    state = AsyncData((state.value ?? []).where((p) => p.id != id).toList());
  }

  Future<void> moveToFirst(String id) async {
    final current =
        state.value ?? await ref.read(appStorageProvider).loadProfiles();
    final idx = current.indexWhere((p) => p.id == id);
    if (idx <= 0) return;
    final reordered = [
      current[idx],
      ...current.sublist(0, idx),
      ...current.sublist(idx + 1),
    ];
    await ref.read(appStorageProvider).saveProfilesOrdered(reordered);
    state = AsyncData(reordered);
  }
}

final profileLibraryProvider =
    AsyncNotifierProvider<ProfileLibraryNotifier, List<ShotProfile>>(
      ProfileLibraryNotifier.new,
    );
