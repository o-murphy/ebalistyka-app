import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_profile_provider.dart';

// ── Display model ─────────────────────────────────────────────────────────────

class ProfileCardData {
  const ProfileCardData({
    required this.id,
    required this.name,
    required this.rifleName,
    required this.caliber,
    required this.twist,
    required this.twistDirection,
    required this.cartridgeName,
    required this.dragModel,
    required this.muzzleVelocity,
    required this.weight,
    required this.sightName,
  });

  final String id;
  final String name;
  final String rifleName;
  final String caliber;
  final String twist;
  final String twistDirection;
  final String cartridgeName;
  final String dragModel;
  final String muzzleVelocity;
  final String weight;
  final String sightName;
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
  List<ProfileCardData>? _cachedProfiles;
  String? _cachedActiveProfileId;

  @override
  Future<ProfilesUiState> build() async {
    await _loadData();
    return ProfilesReady(
      profiles: _cachedProfiles ?? [],
      activeProfileId: _cachedActiveProfileId,
    );
  }

  Future<void> _loadData() async {
    final appState = await ref.read(appStateProvider.future);
    final formatter = ref.read(unitFormatterProvider);
    final units = ref.read(unitSettingsProvider);

    _cachedProfiles = appState.profiles
        .map((p) => _buildCardData(p, formatter, units))
        .toList();
    _cachedActiveProfileId = appState.activeProfile?.id.toString();
  }

  ProfileCardData _buildCardData(
    Profile profile,
    UnitFormatter formatter,
    UnitSettings units,
  ) {
    final ammo = profile.ammo.target;
    final sight = profile.sight.target;
    final weapon = profile.weapon.target;

    String dragStr = '—';
    String caliber = '—';
    String muzzleVelocity = '—';
    String weight = '—';

    if (ammo != null) {
      dragStr = ammo.dragModelFormattedInfo;
      caliber = formatter.diameter(ammo.caliber);
      muzzleVelocity = formatter.velocity(ammo.mv);
      weight = formatter.weight(ammo.weight);
    }

    final twistStr = weapon != null && weapon.twistInch.abs() > 0
        ? formatter.twist(weapon.twist)
        : '—';

    final twistDirStr = weapon != null && weapon.isRightHandTwist
        ? "right"
        : "left";

    return ProfileCardData(
      id: profile.id.toString(),
      name: profile.name,
      rifleName: weapon?.name ?? '—',
      caliber: caliber,
      twist: twistStr,
      twistDirection: twistDirStr,
      cartridgeName: ammo?.name ?? 'Not selected',
      dragModel: dragStr,
      muzzleVelocity: muzzleVelocity,
      weight: weight,
      sightName: sight?.name ?? 'Not selected',
    );
  }

  Future<void> selectProfile(String id) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles
        .where((p) => p.id.toString() == id)
        .firstOrNull;
    if (profile == null) return;

    await ref.read(shotProfileProvider.notifier).selectProfile(profile);

    // Move to first by setting sortOrder = 0, push others up
    await ref.read(appStateProvider.notifier).reorderProfile(profile.id, 0);

    await _loadData();
    _notifyReady();
  }

  Future<void> removeProfile(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;

    await ref.read(appStateProvider.notifier).deleteProfile(intId);

    await _loadData();
    _notifyReady();
  }

  Future<void> updateProfileWeapon(String profileId, Weapon weapon) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles
        .where((p) => p.id.toString() == profileId)
        .firstOrNull;
    if (profile == null) return;

    await ref.read(appStateProvider.notifier).saveWeapon(weapon);
    profile.weapon.target = weapon;
    await ref.read(appStateProvider.notifier).saveProfile(profile);

    if (appState.activeProfile?.id.toString() == profileId) {
      await ref.read(shotProfileProvider.notifier).selectWeapon(weapon);
    }

    await _loadData();
    _notifyReady();
  }

  void _notifyReady() {
    final current = state.value;
    if (current is ProfilesReady) {
      state = AsyncData(
        ProfilesReady(
          profiles: _cachedProfiles ?? [],
          activeProfileId: _cachedActiveProfileId,
        ),
      );
    }
  }
}

final rifleSelectVmProvider =
    AsyncNotifierProvider<ProfilesViewModel, ProfilesUiState>(
      ProfilesViewModel.new,
    );
