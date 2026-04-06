// profiles_vm.dart
import 'package:ebalistyka/core/models/cartridge.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/models/rifle.dart';
import 'package:ebalistyka/core/models/shot_profile.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
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
  // Кешуємо дані, щоб не перебудовуватись при змінах appState
  List<ProfileCardData>? _cachedProfiles;
  String? _cachedActiveProfileId;

  @override
  Future<ProfilesUiState> build() async {
    // Завантажуємо дані один раз при створенні
    await _loadData();
    return ProfilesReady(
      profiles: _cachedProfiles ?? [],
      activeProfileId: _cachedActiveProfileId,
    );
  }

  Future<void> _loadData() async {
    final appState = await ref.read(appStateProvider.future);
    final formatter = ref.read(unitFormatterProvider);

    _cachedProfiles = appState.profiles
        .map((p) => _buildCardData(p, appState, formatter))
        .toList();
    _cachedActiveProfileId = appState.activeProfileId;
  }

  ProfileCardData _buildCardData(
    ShotProfile profile,
    AppState appState,
    UnitFormatter fmt,
  ) {
    final cartridge = profile.cartridgeId != null
        ? appState.cartridges.firstWhere(
            (c) => c.id == profile.cartridgeId,
            orElse: () =>
                throw StateError('Cartridge ${profile.cartridgeId} not found'),
          )
        : null;

    final sight = profile.sightId != null
        ? appState.sights.firstWhere(
            (s) => s.id == profile.sightId,
            orElse: () =>
                throw StateError('Sight ${profile.sightId} not found'),
          )
        : null;

    String dragModel = '—';
    String caliber = '—';
    String muzzleVelocity = '—';
    String weight = '—';

    if (cartridge != null) {
      final bcAcc = FC.ballisticCoefficient.accuracy;
      final firstBc = cartridge.coefRows.isNotEmpty
          ? cartridge.coefRows.first.bcCd
          : 0.0;
      dragModel = switch (cartridge.dragType) {
        DragModelType.g1 =>
          cartridge.isMultiBC
              ? 'G1 Multi'
              : 'G1 ${firstBc.toStringAsFixed(bcAcc)}',
        DragModelType.g7 =>
          cartridge.isMultiBC
              ? 'G7 Multi'
              : 'G7 ${firstBc.toStringAsFixed(bcAcc)}',
        DragModelType.custom => 'CUSTOM',
      };
      caliber = fmt.diameter(cartridge.diameter);
      muzzleVelocity = fmt.velocity(cartridge.mv);
      weight = fmt.weight(cartridge.weight);
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
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Profile $id not found'),
    );

    // Відновлює повний стан профілю
    await ref.read(shotProfileProvider.notifier).selectProfile(profile);

    // Переміщуємо профіль на першу позицію (в бекграунді)
    await appStateNotifier.moveProfileToFirst(id);

    // Оновлюємо кеш після зміни порядку
    await _loadData();

    // Оновлюємо стан ViewModel тихо, без перебудови UI (якщо сторінка ще відкрита)
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

  Future<void> updateProfileRifle(String profileId, Rifle rifle) async {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final idx = appState.profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return;

    final updated = appState.profiles[idx].copyWith(rifle: rifle);
    await appStateNotifier.saveProfile(updated);

    final activeId = appState.activeProfileId;
    if (activeId == profileId) {
      await ref.read(shotProfileProvider.notifier).selectRifle(rifle);
    }

    // Оновлюємо кеш
    await _loadData();

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

  Future<void> removeProfile(String id) async {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    await appStateNotifier.deleteProfile(id);

    await _loadData();

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

  Future<void> saveProfile(ShotProfile profile) async {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    await appStateNotifier.saveProfile(profile);

    await _loadData();

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

  Future<void> importFromA7pBytes(List<int> bytes, {String? fileName}) async {
    // A7pParser implementation
  }
}

final rifleSelectVmProvider =
    AsyncNotifierProvider<ProfilesViewModel, ProfilesUiState>(
      ProfilesViewModel.new,
    );
