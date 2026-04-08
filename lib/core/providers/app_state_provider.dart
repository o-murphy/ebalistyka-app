import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/providers/db_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod/riverpod.dart';

// ── AppState ──────────────────────────────────────────────────────────────────

class AppState {
  final List<Weapon> weapons;
  final List<Ammo> cartridges;
  final List<Sight> sights;
  final List<Profile> profiles;
  final Profile? activeProfile;

  const AppState({
    required this.weapons,
    required this.cartridges,
    required this.sights,
    required this.profiles,
    this.activeProfile,
  });

  factory AppState.empty() =>
      const AppState(weapons: [], cartridges: [], sights: [], profiles: []);

  AppState copyWith({
    List<Weapon>? weapons,
    List<Ammo>? cartridges,
    List<Sight>? sights,
    List<Profile>? profiles,
    Profile? activeProfile,
    bool clearActiveProfile = false,
  }) => AppState(
    weapons: weapons ?? this.weapons,
    cartridges: cartridges ?? this.cartridges,
    sights: sights ?? this.sights,
    profiles: profiles ?? this.profiles,
    activeProfile: clearActiveProfile
        ? null
        : (activeProfile ?? this.activeProfile),
  );
}

// ── AppStateNotifier ──────────────────────────────────────────────────────────

class AppStateNotifier extends AsyncNotifier<AppState> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<AppState> build() async {
    return _load();
  }

  AppState _load() {
    final owner = _owner;

    var weapons = _store
        .box<Weapon>()
        .query(Weapon_.owner.equals(owner.id))
        .build()
        .find();
    var cartridges = _store
        .box<Ammo>()
        .query(Ammo_.owner.equals(owner.id))
        .build()
        .find();
    var sights = _store
        .box<Sight>()
        .query(Sight_.owner.equals(owner.id))
        .build()
        .find();
    var profiles = _store
        .box<Profile>()
        .query(Profile_.owner.equals(owner.id))
        .build()
        .find();

    // ── Seed on first run ──────────────────────────────────────────────────────
    if (weapons.isEmpty && cartridges.isEmpty && sights.isEmpty && profiles.isEmpty) {
      debugPrint('AppStateNotifier: seeding initial data...');
      _seed(owner);
      weapons = _store
          .box<Weapon>()
          .query(Weapon_.owner.equals(owner.id))
          .build()
          .find();
      cartridges = _store
          .box<Ammo>()
          .query(Ammo_.owner.equals(owner.id))
          .build()
          .find();
      sights = _store
          .box<Sight>()
          .query(Sight_.owner.equals(owner.id))
          .build()
          .find();
      profiles = _store
          .box<Profile>()
          .query(Profile_.owner.equals(owner.id))
          .build()
          .find();
    }

    // Use targetId (just the ID, no cached entity) then find the fresh
    // entity from the just-loaded profiles list so Riverpod always sees
    // a new object reference and notifies downstream providers.
    final activeId = owner.activeProfile.targetId;
    final activeProfile = activeId != 0
        ? profiles.where((p) => p.id == activeId).firstOrNull
        : (profiles.isNotEmpty ? profiles.first : null);

    debugPrint(
      'AppStateNotifier: ${weapons.length} weapons, ${cartridges.length} ammo, '
      '${sights.length} sights, ${profiles.length} profiles',
    );

    return AppState(
      weapons: weapons,
      cartridges: cartridges,
      sights: sights,
      profiles: profiles,
      activeProfile: activeProfile,
    );
  }

  void _seed(Owner owner) {
    _store.runInTransaction(TxMode.write, () {
      final sight = Sight()
        ..name = 'Generic Long-Range Scope'
        ..sightHeight = Distance.inch(1.5)
        ..owner.target = owner;
      _store.box<Sight>().put(sight);

      final weapon = Weapon()
        ..name = '.338 Lapua Magnum'
        ..caliber = Distance.inch(0.338)
        ..twist = Distance.inch(10.0)
        ..owner.target = owner;
      _store.box<Weapon>().put(weapon);

      final ammos = [
        Ammo()
          ..name = '.338LM UKROP 250GR SMK'
          ..dragType = DragType.g7
          ..weight = Weight.grain(250.0)
          ..caliber = Distance.inch(0.338)
          ..length = Distance.inch(1.555)
          ..bcG7 = 0.314
          ..mv = Velocity.mps(888.0)
          ..powderTemp = Temperature.celsius(29.0)
          ..powderSensitivity = Ratio.fraction(0.02)
          ..zeroDistance = Distance.meter(100.0)
          ..owner.target = owner,
        Ammo()
          ..name = '.338LM Hornady 250GR BTHP'
          ..dragType = DragType.g7
          ..weight = Weight.grain(250.0)
          ..caliber = Distance.inch(0.338)
          ..length = Distance.inch(1.567)
          ..bcG7 = 0.322
          ..mv = Velocity.mps(885.0)
          ..powderTemp = Temperature.celsius(15.0)
          ..powderSensitivity = Ratio.fraction(0.02)
          ..zeroDistance = Distance.meter(100.0)
          ..owner.target = owner,
        Ammo()
          ..name = '.338LM Lapua 300GR SMK'
          ..dragType = DragType.g7
          ..weight = Weight.grain(300.0)
          ..caliber = Distance.inch(0.338)
          ..length = Distance.inch(1.700)
          ..bcG7 = 0.381
          ..mv = Velocity.mps(825.0)
          ..powderTemp = Temperature.celsius(15.0)
          ..powderSensitivity = Ratio.fraction(0.123)
          ..zeroDistance = Distance.meter(100.0)
          ..owner.target = owner,
      ];
      _store.box<Ammo>().putMany(ammos);

      for (var i = 0; i < ammos.length; i++) {
        final profile = Profile()
          ..name = ammos[i].name
          ..sortOrder = i
          ..weapon.target = weapon
          ..sight.target = sight
          ..ammo.target = ammos[i]
          ..owner.target = owner;
        _store.box<Profile>().put(profile);
      }
    });
  }

  // ── Active profile ────────────────────────────────────────────────────────────

  Future<void> setActiveProfile(Profile profile) async {
    final owner = _owner;
    owner.activeProfile.target = profile;
    _store.box<Owner>().put(owner);
    state = AsyncData(_load());
  }

  // ── Ammo CRUD ─────────────────────────────────────────────────────────────────

  Future<void> saveAmmo(Ammo ammo) async {
    ammo.owner.target = _owner;
    _store.box<Ammo>().put(ammo);
    // Full reload so activeProfile.ammo.target reflects the updated entity.
    state = AsyncData(_load());
  }

  Future<void> deleteAmmo(int id) async {
    _store.runInTransaction(TxMode.write, () {
      // Nullify ammo relation on linked profiles (keep profiles, just unlink)
      final linked = _store
          .box<Profile>()
          .query(Profile_.ammo.equals(id))
          .build()
          .find();
      for (final p in linked) {
        p.ammo.targetId = 0;
        _store.box<Profile>().put(p);
      }
      _store.box<Ammo>().remove(id);
    });
    state = AsyncData(_load());
  }

  // ── Sight CRUD ────────────────────────────────────────────────────────────────

  Future<void> saveWeapon(Weapon weapon) async {
    weapon.owner.target = _owner;
    _store.box<Weapon>().put(weapon);
    state = AsyncData(_load());
  }

  Future<void> saveSight(Sight sight) async {
    sight.owner.target = _owner;
    _store.box<Sight>().put(sight);
    // Full reload so activeProfile.sight.target reflects the updated entity.
    state = AsyncData(_load());
  }

  Future<void> deleteSight(int id) async {
    _store.runInTransaction(TxMode.write, () {
      final linked = _store
          .box<Profile>()
          .query(Profile_.sight.equals(id))
          .build()
          .find();
      for (final p in linked) {
        p.sight.targetId = 0;
        _store.box<Profile>().put(p);
      }
      _store.box<Sight>().remove(id);
    });
    state = AsyncData(_load());
  }

  // ── Profile CRUD ──────────────────────────────────────────────────────────────

  Future<void> saveProfile(Profile profile) async {
    profile.owner.target = _owner;
    _store.box<Profile>().put(profile);
    // Full reload so activeProfile is always fresh from ObjectBox.
    state = AsyncData(_load());
  }

  Future<void> deleteProfile(int id) async {
    final wasActive = state.value?.activeProfile?.id == id;
    _store.box<Profile>().remove(id);
    final fresh = _load();
    // If deleted profile was active — pick the first remaining profile.
    if (wasActive && fresh.activeProfile == null && fresh.profiles.isNotEmpty) {
      await setActiveProfile(fresh.profiles.first);
    } else {
      state = AsyncData(fresh);
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final appStateProvider = AsyncNotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

final weaponsProvider = Provider<List<Weapon>>((ref) {
  return ref.watch(appStateProvider).value?.weapons ?? [];
});

final cartridgesProvider = Provider<List<Ammo>>((ref) {
  return ref.watch(appStateProvider).value?.cartridges ?? [];
});

final sightsProvider = Provider<List<Sight>>((ref) {
  return ref.watch(appStateProvider).value?.sights ?? [];
});

final profilesProvider = Provider<List<Profile>>((ref) {
  return ref.watch(appStateProvider).value?.profiles ?? [];
});

final activeProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(appStateProvider).value?.activeProfile;
});
