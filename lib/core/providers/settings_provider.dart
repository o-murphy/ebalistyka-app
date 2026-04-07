import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/providers/db_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

// ── GeneralSettings notifier ──────────────────────────────────────────────────

class SettingsNotifier extends AsyncNotifier<GeneralSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<GeneralSettings> build() async => _load();

  GeneralSettings _load() {
    final owner = _owner;
    final existing = _store
        .box<GeneralSettings>()
        .query(GeneralSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = GeneralSettings()..owner.target = owner;
    _store.box<GeneralSettings>().put(s);
    return s;
  }

  Future<void> _save(GeneralSettings s) async {
    _store.box<GeneralSettings>().put(s);
    state = AsyncData(s);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final s = state.value ?? _load();
    s.flutterThemeMode = mode;
    await _save(s);
  }

  Future<void> setLanguage(String code) async {
    final s = state.value ?? _load();
    s.languageCode = code;
    await _save(s);
  }

  Future<void> setAdjustmentFormat(AdjustmentDisplayFormat format) async {
    final s = state.value ?? _load();
    s.adjustmentDisplayFormat = format;
    await _save(s);
  }

  Future<void> setChartDistanceStep(double step) async {
    final s = state.value ?? _load();
    s.homeChartDistanceStep = step;
    await _save(s);
  }

  Future<void> setHomeTableStep(double step) async {
    final s = state.value ?? _load();
    s.homeTableDistanceStep = step;
    await _save(s);
  }

  Future<void> setAdjustmentToggle(String key, bool value) async {
    final s = state.value ?? _load();
    switch (key) {
      case 'showMrad':
        s.homeShowMrad = value;
      case 'showMoa':
        s.homeShowMoa = value;
      case 'showMil':
        s.homeShowMil = value;
      case 'showCmPer100m':
        s.homeShowCmPer100m = value;
      case 'showInPer100yd':
        s.homeShowInPer100yd = value;
      case 'subsonicTransition':
        s.homeShowSubsonicTransition = value;
    }
    await _save(s);
  }
}

// ── UnitSettings notifier ─────────────────────────────────────────────────────

class UnitSettingsNotifier extends AsyncNotifier<UnitSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<UnitSettings> build() async => _load();

  UnitSettings _load() {
    final owner = _owner;
    final existing = _store
        .box<UnitSettings>()
        .query(UnitSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = UnitSettings()..owner.target = owner;
    _store.box<UnitSettings>().put(s);
    return s;
  }

  Future<void> _save(UnitSettings s) async {
    _store.box<UnitSettings>().put(s);
    state = AsyncData(s);
  }

  Future<void> setUnit(String key, Unit unit) async {
    final s = state.value ?? _load();
    switch (key) {
      case 'angular':
        s.angularUnit = unit;
      case 'distance':
        s.distanceUnit = unit;
      case 'velocity':
        s.velocityUnit = unit;
      case 'pressure':
        s.pressureUnit = unit;
      case 'temperature':
        s.temperatureUnit = unit;
      case 'diameter':
        s.diameterUnit = unit;
      case 'length':
        s.lengthUnit = unit;
      case 'weight':
        s.weightUnit = unit;
      case 'drop':
        s.dropUnit = unit;
      case 'energy':
        s.energyUnit = unit;
    }
    await _save(s);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, GeneralSettings>(
  SettingsNotifier.new,
);

final unitSettingsNotifierProvider =
    AsyncNotifierProvider<UnitSettingsNotifier, UnitSettings>(
      UnitSettingsNotifier.new,
    );

/// Synchronous access — returns defaults while loading.
final unitSettingsProvider = Provider<UnitSettings>((ref) {
  return ref.watch(unitSettingsNotifierProvider).value ?? UnitSettings();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).value?.flutterThemeMode ?? ThemeMode.system;
});
