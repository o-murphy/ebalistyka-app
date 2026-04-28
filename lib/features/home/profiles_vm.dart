import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';

// ── Paging state ──────────────────────────────────────────────────────────────
//
// Contains only structural data (profile IDs in display order + active ID).
// Equality is field-level so Riverpod suppresses notifications when a
// content-only change (ammo/sight/weapon edit) leaves the structure unchanged.

class ProfilesPagingState {
  const ProfilesPagingState({required this.orderedIds, this.activeId});

  final List<String> orderedIds;
  final String? activeId;

  @override
  bool operator ==(Object other) {
    if (other is! ProfilesPagingState) return false;
    if (activeId != other.activeId) return false;
    if (orderedIds.length != other.orderedIds.length) return false;
    for (var i = 0; i < orderedIds.length; i++) {
      if (orderedIds[i] != other.orderedIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(activeId, Object.hashAll(orderedIds));
}

/// Synchronous paging provider — no async states, no intermediate loading.
/// Only changes (and notifies) when profiles are added/removed or the active
/// profile changes.  Content changes (ammo, sight, weapon edits) are invisible
/// here because they do not affect orderedIds or activeId.
final profilesPagingProvider = Provider<ProfilesPagingState>((ref) {
  final appState = ref.watch(appStateProvider).value;
  if (appState == null) {
    return const ProfilesPagingState(orderedIds: [], activeId: null);
  }

  final activeId = appState.activeProfile?.id.toString();
  final ids = appState.profiles.map((p) => p.id.toString()).toList();

  final orderedIds = activeId == null
      ? ids
      : [activeId, ...ids.where((id) => id != activeId)];

  return ProfilesPagingState(orderedIds: orderedIds, activeId: activeId);
});

// ── Profile card data ─────────────────────────────────────────────────────────
//
// Per-profile synchronous provider.  Riverpod will not notify a card widget
// unless THIS profile's data (name, weapon, ammo, sight) actually changed.

class ProfileCardData {
  const ProfileCardData({
    required this.id,
    required this.name,
    required this.weaponFingerprint,
    required this.weaponName,
    this.weaponImage,
    required this.weaponCaliber,
    required this.twist,
    required this.rightHanded,
    this.ammoId,
    required this.ammoFingerprint,
    required this.ammoCaliber,
    required this.cartridgeName,
    required this.projectileName,
    required this.dragModel,
    required this.muzzleVelocity,
    required this.weight,
    this.sightId,
    required this.sightFingerprint,
    required this.sightName,
    required this.sightHeight,
    required this.focalPlane,
    required this.reticleImage,
    required this.magnification,
    required this.verticalClick,
    required this.horizontalClick,
  });

  final String id;
  final String name;

  /// Hash of all weapon entity fields. Triggers card rebuild on any weapon edit.
  final int weaponFingerprint;
  final String weaponName;
  final String? weaponImage;
  final String weaponCaliber;
  final String twist;
  final bool rightHanded;

  final int? ammoId;

  /// Hash of all ammo fields. Triggers card rebuild on any ammo edit.
  final int ammoFingerprint;
  final String ammoCaliber;
  final String cartridgeName;
  final String projectileName;
  final String dragModel;
  final String muzzleVelocity;
  final String weight;

  final int? sightId;

  /// Hash of all sight entity fields. Triggers card rebuild on any sight edit.
  final int sightFingerprint;
  final String sightName;
  final String sightHeight;
  final FocalPlane focalPlane;
  final String reticleImage;
  final String magnification;
  final String verticalClick;
  final String horizontalClick;

  @override
  bool operator ==(Object other) {
    if (other is! ProfileCardData) return false;
    return id == other.id &&
        name == other.name &&
        weaponFingerprint == other.weaponFingerprint &&
        ammoId == other.ammoId &&
        ammoFingerprint == other.ammoFingerprint &&
        sightId == other.sightId &&
        sightFingerprint == other.sightFingerprint;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    weaponFingerprint,
    ammoId,
    ammoFingerprint,
    sightId,
    sightFingerprint,
  );
}

final profileCardProvider = Provider.autoDispose
    .family<ProfileCardData?, String>((ref, profileId) {
      final appState = ref.watch(appStateProvider).value;
      if (appState == null) return null;

      final profile = appState.profiles
          .where((p) => p.id.toString() == profileId)
          .firstOrNull;
      if (profile == null) return null;

      final formatter = ref.read(unitFormatterProvider);
      final units = ref.read(unitSettingsProvider);

      return _buildCardData(profile, appState, formatter, units);
    });

ProfileCardData _buildCardData(
  Profile profile,
  AppState appState,
  UnitFormatter formatter,
  UnitSettings units,
) {
  final weapon = appState.weapons
      .where((w) => w.id == profile.weapon.targetId)
      .firstOrNull;
  final ammo = appState.ammo
      .where((a) => a.id == profile.ammo.targetId)
      .firstOrNull;
  final sight = appState.sights
      .where((s) => s.id == profile.sight.targetId)
      .firstOrNull;

  return ProfileCardData(
    id: profile.id.toString(),
    name: profile.name,
    weaponFingerprint: _weaponFingerprint(weapon),
    weaponName: weapon?.name ?? nullStr,
    weaponImage: weapon?.image,
    weaponCaliber: formatter.diameter(weapon?.caliber),
    twist: weapon != null && weapon.twistInch.abs() > 0
        ? formatter.twist(weapon.twist)
        : nullStr,
    rightHanded: weapon?.isRightHandTwist ?? true,
    ammoId: ammo?.id,
    ammoFingerprint: _ammoFingerprint(ammo),
    ammoCaliber: formatter.diameter(ammo?.caliber),
    cartridgeName: ammo?.name ?? nullStr,
    projectileName: ammo?.projectileName ?? nullStr,
    dragModel: ammo?.dragModelFormattedInfo ?? nullStr,
    muzzleVelocity: formatter.velocity(ammo?.mv),
    weight: formatter.weight(ammo?.weight),
    sightId: sight?.id,
    sightFingerprint: _sightFingerprint(sight),
    sightName: sight?.name ?? nullStr,
    sightHeight: formatter.sightHeight(sight?.sightHeight),
    focalPlane: sight?.focalPlane ?? FocalPlane.ffp,
    reticleImage: sight?.reticleImage?.isNotEmpty == true
        ? sight!.reticleImage!
        : defaultReticleId,
    magnification: formatter.magnificationRange(
      sight?.minMagnification,
      sight?.maxMagnification,
    ),
    verticalClick: formatter.click(
      sight?.verticalClick,
      sight?.verticalClickUnitValue,
    ),
    horizontalClick: formatter.click(
      sight?.horizontalClick,
      sight?.horizontalClickUnitValue,
    ),
  );
}

int _weaponFingerprint(Weapon? w) {
  if (w == null) return 0;
  return Object.hashAll([
    w.name,
    w.caliberInch,
    w.caliberName,
    w.twistInch,
    w.barrelLengthInch,
    w.zeroElevationRad,
    w.vendor,
    w.notes,
    w.image,
  ]);
}

int _ammoFingerprint(Ammo? a) {
  if (a == null) return 0;
  return Object.hashAll([
    a.name,
    a.caliberInch,
    a.weightGrain,
    a.lengthInch,
    a.projectileName,
    a.vendor,
    a.image,
    a.muzzleVelocityMps,
    a.muzzleVelocityTemperatureC,
    a.usePowderSensitivity,
    a.powderSensitivityFrac,
    Object.hashAll(a.powderSensitivityTC ?? const []),
    Object.hashAll(a.powderSensitivityVMps ?? const []),
    a.zeroDistanceMeter,
    a.zeroTemperatureC,
    a.zeroPressurehPa,
    a.zeroHumidityFrac,
    a.zeroAltitudeMeter,
    a.zeroPowderTemperatureC,
    a.zeroUseDiffPowderTemperature,
    a.zeroLookAngleRad,
    a.zeroUseCoriolis,
    a.zeroLatitudeDeg,
    a.zeroAzimuthDeg,
    a.zeroOffsetX,
    a.zeroOffsetY,
    a.zeroOffsetXUnit,
    a.zeroOffsetYUnit,
    a.bcG1,
    a.bcG7,
    a.dragTypeValue,
    a.useMultiBcG1,
    a.useMultiBcG7,
    Object.hashAll(a.multiBcTableG1VMps ?? const []),
    Object.hashAll(a.multiBcTableG1Bc ?? const []),
    Object.hashAll(a.multiBcTableG7VMps ?? const []),
    Object.hashAll(a.multiBcTableG7Bc ?? const []),
    Object.hashAll(a.customDragTableMach ?? const []),
    Object.hashAll(a.customDragTableCd ?? const []),
  ]);
}

int _sightFingerprint(Sight? s) {
  if (s == null) return 0;
  return Object.hashAll([
    s.name,
    s.focalPlaneValue,
    s.sightHeightInch,
    s.sightHorizontalOffsetInch,
    s.verticalClick,
    s.horizontalClick,
    s.verticalClickUnit,
    s.horizontalClickUnit,
    s.minMagnification,
    s.maxMagnification,
    s.reticleImage,
    s.calibratedMagnification,
    s.vendor,
    s.notes,
    s.image,
  ]);
}

// ── Profile actions ───────────────────────────────────────────────────────────

class ProfilesActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> selectProfile(String id) async {
    final profile = ref
        .read(appStateProvider)
        .value
        ?.profiles
        .where((p) => p.id.toString() == id)
        .firstOrNull;
    if (profile == null) return;
    await ref.read(appStateProvider.notifier).setActiveProfile(profile);
  }

  Future<void> removeProfile(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await ref.read(appStateProvider.notifier).deleteProfile(intId);
  }

  Future<String> createProfile(String name, Weapon weapon) async {
    final id = await ref
        .read(appStateProvider.notifier)
        .createProfile(name, weapon);
    return id.toString();
  }

  Future<String> duplicateProfile(String id, String newName) async {
    final intId = int.tryParse(id);
    if (intId == null) return '';
    final newId = await ref
        .read(appStateProvider.notifier)
        .duplicateProfile(intId, newName);
    return newId.toString();
  }

  Future<void> renameProfile(String id, String name) async {
    final profile = ref
        .read(appStateProvider)
        .value
        ?.profiles
        .where((p) => p.id.toString() == id)
        .firstOrNull;
    if (profile == null) return;
    profile.name = name;
    await ref.read(appStateProvider.notifier).saveProfile(profile);
  }
}

final profilesActionsProvider = NotifierProvider<ProfilesActions, void>(
  ProfilesActions.new,
);
