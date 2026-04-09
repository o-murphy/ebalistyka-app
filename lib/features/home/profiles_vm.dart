import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';

// ── Display model ─────────────────────────────────────────────────────────────

class ProfileCardData {
  const ProfileCardData({
    required this.id,
    required this.name,
    required this.weaponName,
    required this.weaponCaliber,
    required this.twist,
    required this.rightHanded,
    required this.ammoCaliber,
    required this.cartridgeName,
    required this.projectileName,
    required this.dragModel,
    required this.muzzleVelocity,
    required this.weight,
    required this.sightName,
    required this.hasAmmo,
    required this.hasSight,
  });

  final String id;
  final String name;
  final String weaponName;
  final String weaponCaliber;
  final String twist;
  final bool rightHanded;
  final String ammoCaliber;
  final String cartridgeName;
  final String projectileName;
  final String dragModel;
  final String muzzleVelocity;
  final String weight;
  final String sightName;
  final bool hasAmmo;
  final bool hasSight;
}

// ── State ─────────────────────────────────────────────────────────────────────

sealed class ProfilesUiState {
  const ProfilesUiState();
}

class ProfilesLoading extends ProfilesUiState {
  const ProfilesLoading();
}

class ProfilesReady extends ProfilesUiState {
  final List<ProfileCardData> profiles;
  final String? activeProfileId;

  const ProfilesReady({required this.profiles, this.activeProfileId});
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class ProfilesViewModel extends AsyncNotifier<ProfilesUiState> {
  @override
  Future<ProfilesUiState> build() async {
    final appState = await ref.watch(appStateProvider.future);
    final formatter = ref.read(unitFormatterProvider);
    final units = ref.read(unitSettingsProvider);

    final activeId = appState.activeProfile?.id.toString();
    final cards = appState.profiles
        .map((p) => _buildCardData(p, appState, formatter, units))
        .toList();

    return ProfilesReady(
      profiles: _sortProfiles(cards, activeId),
      activeProfileId: activeId,
    );
  }

  ProfileCardData _buildCardData(
    Profile profile,
    AppState appState,
    UnitFormatter formatter,
    UnitSettings units,
  ) {
    final weapon = appState.weapons
        .where((w) => w.id == profile.weapon.targetId)
        .firstOrNull;
    final ammo = appState.cartridges
        .where((a) => a.id == profile.ammo.targetId)
        .firstOrNull;
    final sight = appState.sights
        .where((s) => s.id == profile.sight.targetId)
        .firstOrNull;

    return ProfileCardData(
      id: profile.id.toString(),
      name: profile.name,
      weaponName: weapon?.name ?? '—',
      weaponCaliber: weapon != null ? formatter.diameter(weapon.caliber) : '—',
      twist: weapon != null && weapon.twistInch.abs() > 0
          ? formatter.twist(weapon.twist)
          : '—',
      rightHanded: weapon?.isRightHandTwist ?? true,
      ammoCaliber: ammo != null ? formatter.diameter(ammo.caliber) : '—',
      cartridgeName: ammo?.name ?? "—",
      projectileName: ammo?.projectileName ?? '—',
      dragModel: ammo?.dragModelFormattedInfo ?? '—',
      muzzleVelocity: ammo != null ? formatter.velocity(ammo.mv) : '—',
      weight: ammo != null ? formatter.weight(ammo.weight) : '—',
      sightName: sight?.name ?? 'Not selected',
      hasAmmo: ammo != null,
      hasSight: sight != null,
    );
  }

  List<ProfileCardData> _sortProfiles(
    List<ProfileCardData> all,
    String? activeId,
  ) {
    if (activeId == null) return all;
    ProfileCardData? active;
    final others = <ProfileCardData>[];
    for (final p in all) {
      if (p.id == activeId) {
        active = p;
      } else {
        others.add(p);
      }
    }
    return [?active, ...others];
  }

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

final profilesVmProvider =
    AsyncNotifierProvider<ProfilesViewModel, ProfilesUiState>(
      ProfilesViewModel.new,
    );
