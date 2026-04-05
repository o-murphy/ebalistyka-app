import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/projectile.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/library_provider.dart';
import 'package:eballistica/core/providers/shot_profile_provider.dart';

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

  // Rifle section
  final String rifleName;
  final String caliber;
  final String twist;
  final String twistDirection;

  // Cartridge section
  final String cartridgeName;
  final String dragModel;
  final String muzzleVelocity;
  final String weight;

  // Sight section
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
  @override
  Future<ProfilesUiState> build() async {
    final profiles = await ref.watch(profileLibraryProvider.future);
    final formatter = ref.read(unitFormatterProvider);
    // ref.read (not watch) — щоб зміна активного профілю не ініціювала
    // повний async rebuild з AsyncLoading → AsyncData, що спричиняє фліккер.
    // selectProfile() оновлює activeProfileId напряму через state = AsyncData(...).
    final activeProfileId = ref.read(shotProfileProvider).value?.id;
    return ProfilesReady(
      profiles: profiles.map((p) => _buildCardData(p, formatter)).toList(),
      activeProfileId: activeProfileId,
    );
  }

  ProfileCardData _buildCardData(ShotProfile profile, UnitFormatter fmt) {
    final cartridge = profile.cartridge;
    final sight = profile.sight;

    String dragModel = '—';
    String caliber = '—';
    String muzzleVelocity = '—';
    String weight = '—';

    if (cartridge != null) {
      final proj = cartridge.projectile;
      final bcAcc = FC.ballisticCoefficient.accuracy;
      final firstBc = proj.coefRows.isNotEmpty ? proj.coefRows.first.bcCd : 0.0;
      dragModel = switch (proj.dragType) {
        DragModelType.g1 =>
          proj.isMultiBC ? 'G1 Multi' : 'G1 ${firstBc.toStringAsFixed(bcAcc)}',
        DragModelType.g7 =>
          proj.isMultiBC ? 'G7 Multi' : 'G7 ${firstBc.toStringAsFixed(bcAcc)}',
        DragModelType.custom => 'CUSTOM',
      };
      caliber = fmt.diameter(proj.diameter);
      muzzleVelocity = fmt.velocity(cartridge.mv);
      weight = fmt.weight(proj.weight);
    }

    return ProfileCardData(
      id: profile.id,
      name: profile.name,
      rifleName: profile.rifle.name,
      caliber: caliber,
      twist: fmt.twist(profile.rifle.twist),
      twistDirection: profile.rifle.isRightHandTwist ? 'right' : 'left',
      cartridgeName: cartridge?.name ?? 'Not selected',
      dragModel: dragModel,
      muzzleVelocity: muzzleVelocity,
      weight: weight,
      sightName: sight?.name ?? 'Not selected',
    );
  }

  Future<void> selectProfile(String id) async {
    final profiles = ref.read(profileLibraryProvider).value ?? [];
    final profile = profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Profile $id not found'),
    );
    // Відновлює повний стан профілю (включно з runtime) і зберігає activeProfileId
    await ref.read(shotProfileProvider.notifier).selectProfile(profile);
    // Переміщуємо обраний профіль на першу позицію в бібліотеці
    await ref.read(profileLibraryProvider.notifier).moveToFirst(id);
    // Оновлюємо стан ViewModel без повного async rebuild
    final current = state.value;
    if (current is ProfilesReady) {
      final idx = current.profiles.indexWhere((p) => p.id == id);
      final reordered = idx > 0
          ? [
              current.profiles[idx],
              ...current.profiles.sublist(0, idx),
              ...current.profiles.sublist(idx + 1),
            ]
          : current.profiles;
      state = AsyncData(
        ProfilesReady(profiles: reordered, activeProfileId: id),
      );
    }
  }

  Future<void> updateProfileRifle(String profileId, Rifle rifle) async {
    final profiles = ref.read(profileLibraryProvider).value ?? [];
    final idx = profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return;
    final updated = profiles[idx].copyWith(rifle: rifle);
    await ref.read(profileLibraryProvider.notifier).save(updated);
    // Sync active profile in shotProfileProvider if needed
    final activeId = ref.read(shotProfileProvider).value?.id;
    if (activeId == profileId) {
      await ref.read(shotProfileProvider.notifier).selectRifle(rifle);
    }
    // Update VM state without full rebuild
    final current = state.value;
    if (current is ProfilesReady) {
      final formatter = ref.read(unitFormatterProvider);
      state = AsyncData(
        ProfilesReady(
          profiles: [
            for (final p in current.profiles)
              if (p.id == profileId) _buildCardData(updated, formatter) else p,
          ],
          activeProfileId: current.activeProfileId,
        ),
      );
    }
  }

  Future<void> removeProfile(String id) async {
    await ref.read(profileLibraryProvider.notifier).delete(id);
  }

  Future<void> saveProfile(ShotProfile profile) async {
    await ref.read(profileLibraryProvider.notifier).save(profile);
  }

  Future<void> importFromA7pBytes(List<int> bytes, {String? fileName}) async {
    // A7pParser works with a Payload parsed from bytes — this is handled
    // upstream (file picker → parse → call saveProfile).
    // This stub is intentionally empty; the screen invokes saveProfile directly
    // after parsing.
  }
}

final rifleSelectVmProvider =
    AsyncNotifierProvider<ProfilesViewModel, ProfilesUiState>(
      ProfilesViewModel.new,
    );
