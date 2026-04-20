import 'package:bclibc_ffi/bclibc.dart';
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
  Future<GeneralSettings> build() async {
    final owner = _owner;
    final settings = _loadOrCreate(owner);

    // OB stream: re-read whenever any GeneralSettings is written to the box.
    // This fires even when _save() writes, giving a fresh object reference
    // so that Riverpod detects the change and notifies all watchers.
    final subscription = _store
        .box<GeneralSettings>()
        .query(GeneralSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((query) {
          final updated = query.findFirst();
          if (updated != null) state = AsyncData(updated);
        });
    ref.onDispose(subscription.cancel);

    return settings;
  }

  GeneralSettings _loadOrCreate(Owner owner) {
    final existing = _store
        .box<GeneralSettings>()
        .query(GeneralSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = GeneralSettings()
      ..owner.target = owner
      ..homeShowMil = true;
    _store.box<GeneralSettings>().put(s);
    return s;
  }

  Future<void> _save(GeneralSettings s) async {
    _store.box<GeneralSettings>().put(s);
    // Stream triggers state update.
  }

  Future<void> restore(GeneralSettingsExport export) async {
    final current = state.value ?? _loadOrCreate(_owner);
    await _save(
      export.toEntity()
        ..id = current.id
        ..owner.target = _owner,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final s = state.value ?? _loadOrCreate(_owner);
    s.flutterThemeMode = mode;
    await _save(s);
  }

  Future<void> setLanguage(String code) async {
    final s = state.value ?? _loadOrCreate(_owner);
    s.languageCode = code;
    await _save(s);
  }

  Future<void> setAdjustmentFormat(AdjustmentDisplayFormat format) async {
    final s = state.value ?? _loadOrCreate(_owner);
    s.adjustmentDisplayFormat = format;
    await _save(s);
  }

  Future<void> setChartDistanceStep(double step) async {
    final s = state.value ?? _loadOrCreate(_owner);
    s.homeChartDistanceStep = step;
    await _save(s);
  }

  Future<void> setHomeTableStep(double step) async {
    final s = state.value ?? _loadOrCreate(_owner);
    s.homeTableDistanceStep = step;
    await _save(s);
  }

  Future<void> setAdjustmentToggle(String key, bool value) async {
    final s = state.value ?? _loadOrCreate(_owner);
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
  Future<UnitSettings> build() async {
    final owner = _owner;
    final settings = _loadOrCreate(owner);

    final subscription = _store
        .box<UnitSettings>()
        .query(UnitSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((query) {
          final updated = query.findFirst();
          if (updated != null) state = AsyncData(updated);
        });
    ref.onDispose(subscription.cancel);

    return settings;
  }

  UnitSettings _loadOrCreate(Owner owner) {
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
    // Stream triggers state update.
  }

  Future<void> restore(UnitSettingsExport export) async {
    final current = state.value ?? _loadOrCreate(_owner);
    await _save(
      export.toEntity()
        ..id = current.id
        ..owner.target = _owner,
    );
  }

  Future<void> setUnit(String key, Unit unit) async {
    final s = state.value ?? _loadOrCreate(_owner);
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

// ── TablesSettings notifier ───────────────────────────────────────────────────

class TablesSettingsNotifier extends AsyncNotifier<TablesSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<TablesSettings> build() async {
    final owner = _owner;
    final settings = _loadOrCreate(owner);

    final subscription = _store
        .box<TablesSettings>()
        .query(TablesSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((query) {
          final updated = query.findFirst();
          if (updated != null) state = AsyncData(updated);
        });
    ref.onDispose(subscription.cancel);

    return settings;
  }

  TablesSettings _loadOrCreate(Owner owner) {
    final existing = _store
        .box<TablesSettings>()
        .query(TablesSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = TablesSettings()
      ..owner.target = owner
      ..distanceEndMeter = 1000.0
      ..showMil = true;
    _store.box<TablesSettings>().put(s);
    return s;
  }

  Future<void> save(TablesSettings s) async {
    _store.box<TablesSettings>().put(s);
    // Stream triggers state update.
  }

  Future<void> restore(TablesSettingsExport export) async {
    final current = state.value ?? _loadOrCreate(_owner);
    await save(
      export.toEntity()
        ..id = current.id
        ..owner.target = _owner,
    );
  }
}

// ── ReticleSettings notifier ──────────────────────────────────────────────────

class ReticleSettingsNotifier extends AsyncNotifier<ReticleSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<ReticleSettings> build() async {
    final owner = _owner;
    final settings = _loadOrCreate(owner);

    final subscription = _store
        .box<ReticleSettings>()
        .query(ReticleSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((query) {
          final updated = query.findFirst();
          if (updated != null) state = AsyncData(updated);
        });
    ref.onDispose(subscription.cancel);

    return settings;
  }

  ReticleSettings _loadOrCreate(Owner owner) {
    final existing = _store
        .box<ReticleSettings>()
        .query(ReticleSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = ReticleSettings()..owner.target = owner;
    _store.box<ReticleSettings>().put(s);
    return s;
  }

  Future<void> save(ReticleSettings s) async {
    _store.box<ReticleSettings>().put(s);
    // Stream triggers state update.
  }

  Future<void> restore(ReticleSettingsExport export) async {
    final current = state.value ?? _loadOrCreate(_owner);
    await save(
      export.toEntity()
        ..id = current.id
        ..owner.target = _owner,
    );
  }

  // Future<void> setVerticalAdjustment(Angular value) async {
  //   final s = state.value ?? _loadOrCreate(_owner);
  //   s.verticalAdjustment = value;
  //   await save(s);
  // }

  // Future<void> setHorizontalAdjustment(Angular value) async {
  //   final s = state.value ?? _loadOrCreate(_owner);
  //   s.horizontalAdjustment = value;
  //   await save(s);
  // }

  Future<void> setTargetImage(String? imageId) async {
    final s = state.value ?? _loadOrCreate(_owner);
    s.targetImage = imageId;
    await save(s);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, GeneralSettings>(
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

final tablesSettingsNotifierProvider =
    AsyncNotifierProvider<TablesSettingsNotifier, TablesSettings>(
      TablesSettingsNotifier.new,
    );

/// Synchronous access to TablesSettings — returns defaults while loading.
final tablesSettingsProvider = Provider<TablesSettings>((ref) {
  return ref.watch(tablesSettingsNotifierProvider).value ?? TablesSettings();
});

final reticleSettingsNotifierProvider =
    AsyncNotifierProvider<ReticleSettingsNotifier, ReticleSettings>(
      ReticleSettingsNotifier.new,
    );

/// Synchronous access to ReticleSettings — returns defaults while loading.
final reticleSettingsProvider = Provider<ReticleSettings>((ref) {
  return ref.watch(reticleSettingsNotifierProvider).value ?? ReticleSettings();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).value?.flutterThemeMode ??
      ThemeMode.system;
});
