// app_state.dart
import 'package:ebalistyka/core/providers/storage_provider.dart';
import 'package:ebalistyka/core/models/cartridge.dart';
import 'package:ebalistyka/core/models/shot_profile.dart';
import 'package:ebalistyka/core/models/sight.dart';
import 'package:ebalistyka/core/models/app_settings.dart';
import 'package:ebalistyka/core/models/conditions_data.dart';
import 'package:ebalistyka/core/models/convertors_state.dart';
import 'package:ebalistyka/core/models/seed_data.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:riverpod/riverpod.dart'; // Додайте цей імпорт

class AppState {
  // ВСІ дані в одному місці
  final List<Cartridge> cartridges;
  final List<Sight> sights;
  final List<ShotProfile> profiles;
  final AppSettings? settings;
  final Conditions? conditions;
  final ConvertorsState? convertors;
  final String? activeProfileId;

  const AppState({
    required this.cartridges,
    required this.sights,
    required this.profiles,
    this.settings,
    this.conditions,
    this.convertors,
    this.activeProfileId,
  });

  // Пустий стан для початку
  factory AppState.empty() =>
      const AppState(cartridges: [], sights: [], profiles: []);

  // Копіювання зі змінами (імутабельність)
  AppState copyWith({
    List<Cartridge>? cartridges,
    List<Sight>? sights,
    List<ShotProfile>? profiles,
    AppSettings? settings,
    Conditions? conditions,
    ConvertorsState? convertors,
    String? activeProfileId,
  }) {
    return AppState(
      cartridges: cartridges ?? this.cartridges,
      sights: sights ?? this.sights,
      profiles: profiles ?? this.profiles,
      settings: settings ?? this.settings,
      conditions: conditions ?? this.conditions,
      convertors: convertors ?? this.convertors,
      activeProfileId: activeProfileId ?? this.activeProfileId,
    );
  }

  // Допоміжні методи для цілісності даних
  List<ShotProfile> getValidProfiles() {
    final validCartridgeIds = cartridges.map((c) => c.id).toSet();
    final validSightIds = sights.map((s) => s.id).toSet();

    return profiles.where((profile) {
      return validCartridgeIds.contains(profile.cartridgeId) &&
          validSightIds.contains(profile.sightId);
    }).toList();
  }
}

class AppStateNotifier extends AsyncNotifier<AppState> {
  @override
  Future<AppState> build() async {
    final storage = ref.read(appStorageProvider);

    debugPrint('AppStateNotifier: Loading data from storage...');

    // Завантажуємо дані
    var cartridges = await storage.loadCartridges();
    var sights = await storage.loadSights();
    var profiles = await storage.loadProfiles();
    final settings = await storage.loadSettings();
    final conditions = await storage.loadConditions();
    final convertors = await storage.loadConvertorsState();
    var activeProfileId = await storage.loadActiveProfileId();

    // ============================================================
    // ДОДАЄМО SEED ДАНІ, ЯКЩО СХОВИЩЕ ПУСТЕ
    // ============================================================

    // Seed sights
    if (sights.isEmpty) {
      debugPrint('AppStateNotifier: No sights found, adding seed sights...');
      sights = [seedSight]; // seedSights має бути List<Sight> абощо
      for (final sight in sights) {
        await storage.saveSight(sight);
      }
    }

    // Seed cartridges
    if (cartridges.isEmpty) {
      debugPrint(
        'AppStateNotifier: No cartridges found, adding seed cartridges...',
      );
      cartridges = seedCartridges; // seedCartridges має бути List<Cartridge>
      for (final cartridge in cartridges) {
        await storage.saveCartridge(cartridge);
      }
    }

    // Seed profiles
    if (profiles.isEmpty) {
      debugPrint(
        'AppStateNotifier: No profiles found, adding seed profiles...',
      );
      profiles =
          seedShotProfiles; // seedShotProfiles має бути List<ShotProfile>
      for (final profile in profiles) {
        await storage.saveProfile(profile);
      }

      // Якщо немає активного профілю і ми додали seed, встановлюємо перший як активний
      if (activeProfileId == null && profiles.isNotEmpty) {
        activeProfileId = profiles.first.id;
        await storage.saveActiveProfileId(activeProfileId);
      }
    }

    debugPrint(
      'AppStateNotifier: Loaded ${cartridges.length} cartridges, ${sights.length} sights, ${profiles.length} profiles',
    );
    debugPrint('AppStateNotifier: Active profile ID: $activeProfileId');

    return AppState(
      cartridges: cartridges,
      sights: sights,
      profiles: profiles,
      settings: settings,
      conditions: conditions,
      convertors: convertors,
      activeProfileId: activeProfileId,
    );
  }

  Future<void> saveActiveProfileId(String id) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveActiveProfileId(id);
    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(activeProfileId: id));
  }

  // ---- Операції з патронами ----
  Future<void> saveCartridge(Cartridge cartridge) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveCartridge(cartridge);
    final currentState = state.value!;
    final newCartridges = [...currentState.cartridges];
    final index = newCartridges.indexWhere((c) => c.id == cartridge.id);
    if (index >= 0) {
      newCartridges[index] = cartridge;
    } else {
      newCartridges.add(cartridge);
    }
    state = AsyncData(currentState.copyWith(cartridges: newCartridges));
  }

  Future<void> deleteCartridge(String id) async {
    final storage = ref.read(appStorageProvider);
    await storage.deleteCartridge(id);
    final currentState = state.value!;
    final newCartridges = currentState.cartridges
        .where((c) => c.id != id)
        .toList();
    final newProfiles = currentState.profiles
        .where((p) => p.cartridgeId != id)
        .toList();
    state = AsyncData(
      currentState.copyWith(cartridges: newCartridges, profiles: newProfiles),
    );
    for (final profile in currentState.profiles.where(
      (p) => p.cartridgeId == id,
    )) {
      await storage.deleteProfile(profile.id);
    }
  }

  // ---- Операції з прицілами ----
  Future<void> saveSight(Sight sight) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveSight(sight);
    final currentState = state.value!;
    final newSights = [...currentState.sights];
    final index = newSights.indexWhere((s) => s.id == sight.id);
    if (index >= 0) {
      newSights[index] = sight;
    } else {
      newSights.add(sight);
    }
    state = AsyncData(currentState.copyWith(sights: newSights));
  }

  Future<void> deleteSight(String id) async {
    final storage = ref.read(appStorageProvider);
    await storage.deleteSight(id);
    final currentState = state.value!;
    final newSights = currentState.sights.where((s) => s.id != id).toList();
    final newProfiles = currentState.profiles
        .where((p) => p.sightId != id)
        .toList();
    state = AsyncData(
      currentState.copyWith(sights: newSights, profiles: newProfiles),
    );
    for (final profile in currentState.profiles.where((p) => p.sightId == id)) {
      await storage.deleteProfile(profile.id);
    }
  }

  // ---- Операції з профілями ----
  Future<void> saveProfile(ShotProfile profile) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveProfile(profile);
    final currentState = state.value!;
    final newProfiles = [...currentState.profiles];
    final index = newProfiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      newProfiles[index] = profile;
    } else {
      newProfiles.add(profile);
    }
    state = AsyncData(currentState.copyWith(profiles: newProfiles));
  }

  Future<void> deleteProfile(String id) async {
    final storage = ref.read(appStorageProvider);
    await storage.deleteProfile(id);
    final currentState = state.value!;
    final newProfiles = currentState.profiles.where((p) => p.id != id).toList();
    state = AsyncData(currentState.copyWith(profiles: newProfiles));
  }

  // Додайте в AppStateNotifier (app_state.dart)
  Future<void> moveProfileToFirst(String id) async {
    final storage = ref.read(appStorageProvider);
    final currentState = state.value!;

    final currentIndex = currentState.profiles.indexWhere((p) => p.id == id);
    if (currentIndex <= 0) return; // Вже перший або не знайдено

    // Створюємо новий порядок
    final reorderedProfiles = [
      currentState.profiles[currentIndex],
      ...currentState.profiles.sublist(0, currentIndex),
      ...currentState.profiles.sublist(currentIndex + 1),
    ];

    // Зберігаємо новий порядок у сховищі
    for (final profile in reorderedProfiles) {
      await storage.saveProfile(profile);
    }

    // Оновлюємо стан
    state = AsyncData(currentState.copyWith(profiles: reorderedProfiles));
  }

  // ---- Допоміжні геттери ----
  List<ShotProfile> getValidProfiles() {
    return state.value?.getValidProfiles() ?? [];
  }

  ShotProfile? getActiveProfile() {
    final appState = state.value;
    if (appState?.activeProfileId == null) return null;
    return appState?.profiles.firstWhere(
      (p) => p.id == appState.activeProfileId,
      orElse: () => throw Exception('Active profile not found'),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveSettings(settings);

    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(settings: settings));
  }

  Future<void> saveConditions(Conditions conditions) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveConditions(conditions);

    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(conditions: conditions));
  }

  Future<void> saveConvertorsState(ConvertorsState convertors) async {
    final storage = ref.read(appStorageProvider);
    await storage.saveConvertorsState(convertors);

    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(convertors: convertors));
  }
}

final appStateProvider = AsyncNotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

// Селектори для зручності
final cartridgesProvider = Provider((ref) {
  final appState = ref.watch(appStateProvider);
  return appState.value?.cartridges ?? [];
});

final sightsProvider = Provider((ref) {
  final appState = ref.watch(appStateProvider);
  return appState.value?.sights ?? [];
});

final profilesProvider = Provider((ref) {
  final appState = ref.watch(appStateProvider);
  return appState.value?.profiles ?? [];
});

final validProfilesProvider = Provider((ref) {
  final notifier = ref.watch(appStateProvider.notifier);
  return notifier.getValidProfiles();
});
