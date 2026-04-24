import 'dart:typed_data';
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
  final List<Ammo> ammo;
  final List<Sight> sights;
  final List<Profile> profiles;
  final Profile? activeProfile;

  const AppState({
    required this.weapons,
    required this.ammo,
    required this.sights,
    required this.profiles,
    this.activeProfile,
  });

  factory AppState.empty() =>
      const AppState(weapons: [], ammo: [], sights: [], profiles: []);

  AppState copyWith({
    List<Weapon>? weapons,
    List<Ammo>? ammo,
    List<Sight>? sights,
    List<Profile>? profiles,
    Profile? activeProfile,
    bool clearActiveProfile = false,
  }) => AppState(
    weapons: weapons ?? this.weapons,
    ammo: ammo ?? this.ammo,
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
    final owner = _owner;

    void reload() => state = AsyncData(_load());

    final subs = [
      _store
          .box<Owner>()
          .query(Owner_.id.equals(owner.id))
          .watch(triggerImmediately: false)
          .listen((_) => reload()),
      _store
          .box<Weapon>()
          .query(Weapon_.owner.equals(owner.id))
          .watch(triggerImmediately: false)
          .listen((_) => reload()),
      _store
          .box<Ammo>()
          .query(Ammo_.owner.equals(owner.id))
          .watch(triggerImmediately: false)
          .listen((_) => reload()),
      _store
          .box<Sight>()
          .query(Sight_.owner.equals(owner.id))
          .watch(triggerImmediately: false)
          .listen((_) => reload()),
      _store
          .box<Profile>()
          .query(Profile_.owner.equals(owner.id))
          .watch(triggerImmediately: false)
          .listen((_) => reload()),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });

    return _load();
  }

  AppState _load() {
    final owner = _owner;

    var weapons = _store
        .box<Weapon>()
        .query(Weapon_.owner.equals(owner.id))
        .build()
        .find();
    var ammo = _store
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
    if (weapons.isEmpty && ammo.isEmpty && sights.isEmpty && profiles.isEmpty) {
      debugPrint('AppStateNotifier: seeding initial data...');
      _seed(owner);
      weapons = _store
          .box<Weapon>()
          .query(Weapon_.owner.equals(owner.id))
          .build()
          .find();
      ammo = _store
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
      'AppStateNotifier: ${weapons.length} weapons, ${ammo.length} ammo, '
      '${sights.length} sights, ${profiles.length} profiles',
    );

    return AppState(
      weapons: weapons,
      ammo: ammo,
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

      final ammos = [
        Ammo()
          ..name = '.338LM UKROP 250GR SMK'
          ..dragType = DragType.g7
          ..weight = Weight.grain(250.0)
          ..caliber = Distance.inch(0.338)
          ..length = Distance.inch(1.555)
          ..bcG7 = 0.314
          ..mv = Velocity.mps(888.0)
          ..mvTemperature = Temperature.celsius(29.0)
          ..powderSensitivity = Ratio.fraction(0.02)
          ..zeroDistance = Distance.meter(100.0)
          ..owner.target = owner,
      ];
      _store.box<Ammo>().putMany(ammos);

      for (var i = 0; i < ammos.length; i++) {
        final weapon = Weapon()
          ..name = '.338 Lapua Magnum'
          ..caliber = Distance.inch(0.338)
          ..twist = Distance.inch(10.0)
          ..owner.target = owner;
        _store.box<Weapon>().put(weapon);

        final profile = Profile()
          ..name = ammos[i].name
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
    // Owner stream triggers reload.
  }

  // ── Ammo CRUD ─────────────────────────────────────────────────────────────────

  Future<void> saveAmmo(Ammo ammo) async {
    ammo.owner.target = _owner;
    _store.box<Ammo>().put(ammo);
    // Ammo stream triggers reload.
  }

  Future<int> duplicateAmmo(int id, String newName) async {
    final original = _store.box<Ammo>().get(id);
    if (original == null) return 0;
    final copy = Ammo()
      ..name = newName
      ..caliberInch = original.caliberInch
      ..weightGrain = original.weightGrain
      ..lengthInch = original.lengthInch
      ..dragTypeValue = original.dragTypeValue
      ..bcG1 = original.bcG1
      ..bcG7 = original.bcG7
      ..useMultiBcG1 = original.useMultiBcG1
      ..useMultiBcG7 = original.useMultiBcG7
      ..muzzleVelocityMps = original.muzzleVelocityMps
      ..muzzleVelocityTemperatureC = original.muzzleVelocityTemperatureC
      ..powderSensitivityFrac = original.powderSensitivityFrac
      ..usePowderSensitivity = original.usePowderSensitivity
      ..powderSensitivityTC = original.powderSensitivityTC != null
          ? Float64List.fromList(original.powderSensitivityTC!)
          : null
      ..powderSensitivityVMps = original.powderSensitivityVMps != null
          ? Float64List.fromList(original.powderSensitivityVMps!)
          : null
      ..multiBcTableG1VMps = original.multiBcTableG1VMps != null
          ? Float64List.fromList(original.multiBcTableG1VMps!)
          : null
      ..multiBcTableG1Bc = original.multiBcTableG1Bc != null
          ? Float64List.fromList(original.multiBcTableG1Bc!)
          : null
      ..multiBcTableG7VMps = original.multiBcTableG7VMps != null
          ? Float64List.fromList(original.multiBcTableG7VMps!)
          : null
      ..multiBcTableG7Bc = original.multiBcTableG7Bc != null
          ? Float64List.fromList(original.multiBcTableG7Bc!)
          : null
      ..customDragTableMach = original.customDragTableMach != null
          ? Float64List.fromList(original.customDragTableMach!)
          : null
      ..customDragTableCd = original.customDragTableCd != null
          ? Float64List.fromList(original.customDragTableCd!)
          : null
      ..zeroDistanceMeter = original.zeroDistanceMeter
      ..zeroLookAngleRad = original.zeroLookAngleRad
      ..zeroAltitudeMeter = original.zeroAltitudeMeter
      ..zeroTemperatureC = original.zeroTemperatureC
      ..zeroPressurehPa = original.zeroPressurehPa
      ..zeroHumidityFrac = original.zeroHumidityFrac
      ..zeroPowderTemperatureC = original.zeroPowderTemperatureC
      ..zeroUseDiffPowderTemperature = original.zeroUseDiffPowderTemperature
      ..zeroUseCoriolis = original.zeroUseCoriolis
      ..zeroLatitudeDeg = original.zeroLatitudeDeg
      ..zeroAzimuthDeg = original.zeroAzimuthDeg
      ..zeroOffsetX = original.zeroOffsetX
      ..zeroOffsetY = original.zeroOffsetY
      ..zeroOffsetXUnit = original.zeroOffsetXUnit
      ..zeroOffsetYUnit = original.zeroOffsetYUnit
      ..projectileName = original.projectileName
      ..vendor = original.vendor
      ..owner.target = _owner;
    return _store.box<Ammo>().put(copy);
    // Ammo stream triggers reload.
  }

  Future<void> deleteAmmo(int id) async {
    _store.runInTransaction(TxMode.write, () {
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
    // Ammo + Profile streams trigger reload.
  }

  // ── Weapon CRUD ───────────────────────────────────────────────────────────────

  Future<void> saveWeapon(Weapon weapon) async {
    weapon.owner.target = _owner;
    _store.box<Weapon>().put(weapon);
    // Weapon stream triggers reload.
  }

  // ── Sight CRUD ────────────────────────────────────────────────────────────────

  Future<int> duplicateSight(int id, String newName) async {
    final original = _store.box<Sight>().get(id);
    if (original == null) return 0;
    final copy = Sight()
      ..name = newName
      ..focalPlaneValue = original.focalPlaneValue
      ..sightHeightInch = original.sightHeightInch
      ..sightHorizontalOffsetInch = original.sightHorizontalOffsetInch
      ..verticalClick = original.verticalClick
      ..horizontalClick = original.horizontalClick
      ..verticalClickUnit = original.verticalClickUnit
      ..horizontalClickUnit = original.horizontalClickUnit
      ..minMagnification = original.minMagnification
      ..maxMagnification = original.maxMagnification
      ..reticleImage = original.reticleImage
      ..vendor = original.vendor
      ..notes = original.notes
      ..owner.target = _owner;
    return _store.box<Sight>().put(copy);
    // Sight stream triggers reload.
  }

  Future<void> saveSight(Sight sight) async {
    sight.owner.target = _owner;
    _store.box<Sight>().put(sight);
    // Sight stream triggers reload.
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
    // Sight + Profile streams trigger reload.
  }

  // ── Profile CRUD ──────────────────────────────────────────────────────────────

  Future<void> setProfileAmmo(String profileId, int ammoId) async {
    final id = int.tryParse(profileId);
    if (id == null) return;
    final profile = _store.box<Profile>().get(id);
    if (profile == null) return;
    profile.ammo.targetId = ammoId;
    await saveProfile(profile);
  }

  Future<void> setProfileSight(String profileId, int sightId) async {
    final id = int.tryParse(profileId);
    if (id == null) return;
    final profile = _store.box<Profile>().get(id);
    if (profile == null) return;
    profile.sight.targetId = sightId;
    await saveProfile(profile);
  }

  Future<int> createProfile(String name, Weapon weapon) async {
    int profileId = 0;
    final owner = _owner;
    _store.runInTransaction(TxMode.write, () {
      weapon.owner.target = owner;
      _store.box<Weapon>().put(weapon);

      final profile = Profile()
        ..name = name
        ..weapon.target = weapon
        ..owner.target = owner;
      profileId = _store.box<Profile>().put(profile);
    });
    // Weapon + Profile streams trigger reload.
    return profileId;
  }

  Future<int> duplicateProfile(int id, String newName) async {
    int newProfileId = 0;
    final owner = _owner;
    _store.runInTransaction(TxMode.write, () {
      final original = _store.box<Profile>().get(id);
      if (original == null) return;

      final originalWeapon = _store.box<Weapon>().get(original.weapon.targetId);
      if (originalWeapon == null) return;

      final weaponCopy = Weapon()
        ..name = originalWeapon.name
        ..caliberInch = originalWeapon.caliberInch
        ..caliberName = originalWeapon.caliberName
        ..twistInch = originalWeapon.twistInch
        ..barrelLengthInch = originalWeapon.barrelLengthInch
        ..zeroElevationRad = originalWeapon.zeroElevationRad
        ..vendor = originalWeapon.vendor
        ..image = originalWeapon.image
        ..owner.target = owner;
      _store.box<Weapon>().put(weaponCopy);

      final profile = Profile()
        ..name = newName
        ..weapon.target = weaponCopy
        ..ammo.targetId = original.ammo.targetId
        ..sight.targetId = original.sight.targetId
        ..owner.target = owner;
      newProfileId = _store.box<Profile>().put(profile);
    });
    // Weapon + Profile streams trigger reload.
    return newProfileId;
  }

  Future<void> saveProfile(Profile profile) async {
    profile.owner.target = _owner;
    _store.box<Profile>().put(profile);
    // Profile stream triggers reload.
  }

  Future<int> importProfile(ProfileExport export) async {
    int profileId = 0;
    final owner = _owner;
    final (profileData, weaponData, ammoData, sightData) = export.toEntities();
    _store.runInTransaction(TxMode.write, () {
      weaponData.owner.target = owner;
      _store.box<Weapon>().put(weaponData);

      if (ammoData != null) {
        ammoData.owner.target = owner;
        _store.box<Ammo>().put(ammoData);
      }
      if (sightData != null) {
        sightData.owner.target = owner;
        _store.box<Sight>().put(sightData);
      }

      profileData
        ..weapon.target = weaponData
        ..ammo.target = ammoData
        ..sight.target = sightData
        ..owner.target = owner;
      profileId = _store.box<Profile>().put(profileData);
    });
    return profileId;
  }

  Future<int> importAmmo(AmmoExport export) async {
    final ammo = export.toEntity()..owner.target = _owner;
    return _store.box<Ammo>().put(ammo);
  }

  Future<int> importSight(SightExport export) async {
    final sight = export.toEntity()..owner.target = _owner;
    return _store.box<Sight>().put(sight);
  }

  Future<void> deleteProfile(int id) async {
    final wasActive = state.value?.activeProfile?.id == id;
    _store.runInTransaction(TxMode.write, () {
      final profile = _store.box<Profile>().get(id);
      final weaponId = profile?.weapon.targetId ?? 0;

      _store.box<Profile>().remove(id);

      // Delete the weapon if no other profile references it.
      if (weaponId != 0) {
        final stillLinked = _store
            .box<Profile>()
            .query(Profile_.weapon.equals(weaponId))
            .build()
            .count();
        if (stillLinked == 0) {
          _store.box<Weapon>().remove(weaponId);
        }
      }

      // If deleted profile was active — reset Owner so _load() picks profiles.first.
      if (wasActive) {
        final owner = _owner;
        owner.activeProfile.targetId = 0;
        _store.box<Owner>().put(owner);
      }
    });
    // Profile + Owner streams trigger reload; _load() picks profiles.first if activeId == 0.
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final appStateProvider = AsyncNotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

final ammoProvider = Provider<List<Ammo>>((ref) {
  return ref.watch(appStateProvider).value?.ammo ?? [];
});

final sightsProvider = Provider<List<Sight>>((ref) {
  return ref.watch(appStateProvider).value?.sights ?? [];
});
