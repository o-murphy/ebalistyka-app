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

    void reload() {
      final settings = _loadOrCreate(owner);
      state = AsyncData(settings);
    }

    final subscription = _store
        .box<GeneralSettings>()
        .query(GeneralSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((_) => reload());

    ref.onDispose(subscription.cancel);

    return _loadOrCreate(owner);
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
      ..homeShowMil = true
      ..homeShowMoa = true
      ..homeShowCmPer100m = true
      ..homeShowInClicks = true;
    _store.box<GeneralSettings>().put(s); // put() returns int, no await needed
    return s;
  }

  Future<void> restore(GeneralSettingsExport export) async {
    final current = _loadOrCreate(_owner);
    final updated = export.toEntity()
      ..id = current.id
      ..owner.target = _owner;
    _store.box<GeneralSettings>().put(updated); // remove await
    // reload() will be triggered by watch
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final s = _loadOrCreate(_owner);
    s.flutterThemeMode = mode;
    _store.box<GeneralSettings>().put(s); // remove await
  }

  Future<void> setLanguage(String code) async {
    final s = _loadOrCreate(_owner);
    s.languageCode = code;
    _store.box<GeneralSettings>().put(s); // remove await
  }

  Future<void> setAdjustmentFormat(AdjustmentDisplayFormat format) async {
    final s = _loadOrCreate(_owner);
    s.adjustmentDisplayFormat = format;
    _store.box<GeneralSettings>().put(s); // remove await
  }

  Future<void> setChartDistanceStep(double step) async {
    final s = _loadOrCreate(_owner);
    s.homeChartDistanceStep = step;
    _store.box<GeneralSettings>().put(s); // remove await
  }

  Future<void> setHomeTableStep(double step) async {
    final s = _loadOrCreate(_owner);
    s.homeTableDistanceStep = step;
    _store.box<GeneralSettings>().put(s); // remove await
  }

  Future<void> setAdjustmentToggle(String key, bool value) async {
    final s = _loadOrCreate(_owner);
    switch (key) {
      case 'showMrad':
        s.homeShowMrad = value;
        break;
      case 'showMoa':
        s.homeShowMoa = value;
        break;
      case 'showMil':
        s.homeShowMil = value;
        break;
      case 'showCmPer100m':
        s.homeShowCmPer100m = value;
        break;
      case 'showInPer100yd':
        s.homeShowInPer100yd = value;
        break;
      case 'subsonicTransition':
        s.homeShowSubsonicTransition = value;
        break;
      case 'showInClicks':
        s.homeShowInClicks = value;
        break;
    }
    _store.box<GeneralSettings>().put(s); // remove await
  }
}

// ── UnitSettings notifier ─────────────────────────────────────────────────────

class UnitSettingsNotifier extends AsyncNotifier<UnitSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<UnitSettings> build() async {
    final owner = _owner;

    void reload() {
      final settings = _loadOrCreate(owner);
      state = AsyncData(settings);
    }

    final subscription = _store
        .box<UnitSettings>()
        .query(UnitSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((_) => reload());

    ref.onDispose(subscription.cancel);

    return _loadOrCreate(owner);
  }

  UnitSettings _loadOrCreate(Owner owner) {
    final existing = _store
        .box<UnitSettings>()
        .query(UnitSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = UnitSettings()..owner.target = owner;
    _store.box<UnitSettings>().put(s); // put() returns int, no await needed
    return s;
  }

  Future<void> restore(UnitSettingsExport export) async {
    final current = _loadOrCreate(_owner);
    final updated = export.toEntity()
      ..id = current.id
      ..owner.target = _owner;
    _store.box<UnitSettings>().put(updated); // remove await
  }

  Future<void> setUnit(String key, Unit unit) async {
    final s = _loadOrCreate(_owner);
    switch (key) {
      case 'angular':
        s.angularUnit = unit;
        break;
      case 'distance':
        s.distanceUnit = unit;
        break;
      case 'velocity':
        s.velocityUnit = unit;
        break;
      case 'pressure':
        s.pressureUnit = unit;
        break;
      case 'temperature':
        s.temperatureUnit = unit;
        break;
      case 'diameter':
        s.diameterUnit = unit;
        break;
      case 'length':
        s.lengthUnit = unit;
        break;
      case 'weight':
        s.weightUnit = unit;
        break;
      case 'drop':
        s.dropUnit = unit;
        break;
      case 'energy':
        s.energyUnit = unit;
        break;
      case 'torque':
        s.torqueUnit = unit;
        break;
      case 'targetSize':
        s.targetSizeUnit = unit;
        break;
    }
    _store.box<UnitSettings>().put(s); // remove await
  }
}

// ── TablesSettings notifier ───────────────────────────────────────────────────

class TablesSettingsNotifier extends AsyncNotifier<TablesSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<TablesSettings> build() async {
    final owner = _owner;

    void reload() {
      final settings = _loadOrCreate(owner);
      state = AsyncData(settings);
    }

    final subscription = _store
        .box<TablesSettings>()
        .query(TablesSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((_) => reload());

    ref.onDispose(subscription.cancel);

    return _loadOrCreate(owner);
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
      ..showMil = true
      ..showMoa = true
      ..showCmPer100m = true
      ..showInClicks = true;
    _store.box<TablesSettings>().put(s); // put() returns int, no await needed
    return s;
  }

  Future<void> restore(TablesSettingsExport export) async {
    final current = _loadOrCreate(_owner);
    final updated = export.toEntity()
      ..id = current.id
      ..owner.target = _owner;
    _store.box<TablesSettings>().put(updated); // remove await
  }

  Future<void> saveSettings(TablesSettings settings) async {
    final s = _loadOrCreate(_owner);
    s.distanceStartMeter = settings.distanceStartMeter;
    s.distanceEndMeter = settings.distanceEndMeter;
    s.distanceStepMeter = settings.distanceStepMeter;
    s.showZeros = settings.showZeros;
    s.showSubsonicTransition = settings.showSubsonicTransition;
    s.hiddenCols = List<String>.from(settings.hiddenCols);
    s.showMrad = settings.showMrad;
    s.showMoa = settings.showMoa;
    s.showMil = settings.showMil;
    s.showCmPer100m = settings.showCmPer100m;
    s.showInPer100yd = settings.showInPer100yd;
    s.showInClicks = settings.showInClicks;
    _store.box<TablesSettings>().put(s);
  }
}

// ── ReticleSettings notifier ──────────────────────────────────────────────────

class ReticleSettingsNotifier extends AsyncNotifier<ReticleSettings> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<ReticleSettings> build() async {
    final owner = _owner;

    void reload() {
      final settings = _loadOrCreate(owner);
      state = AsyncData(settings);
    }

    final subscription = _store
        .box<ReticleSettings>()
        .query(ReticleSettings_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((_) => reload());

    ref.onDispose(subscription.cancel);

    return _loadOrCreate(owner);
  }

  ReticleSettings _loadOrCreate(Owner owner) {
    final existing = _store
        .box<ReticleSettings>()
        .query(ReticleSettings_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = ReticleSettings()..owner.target = owner;
    _store.box<ReticleSettings>().put(s); // put() returns int, no await needed
    return s;
  }

  Future<void> restore(ReticleSettingsExport export) async {
    final current = _loadOrCreate(_owner);
    final updated = export.toEntity()
      ..id = current.id
      ..owner.target = _owner;
    _store.box<ReticleSettings>().put(updated); // remove await
  }

  Future<void> setTargetImage(String? imageId) async {
    final s = _loadOrCreate(_owner);
    s.targetImage = imageId;
    _store.box<ReticleSettings>().put(s); // remove await
  }

  Future<void> setVerticalAdjustment(double value) async {
    final s = _loadOrCreate(_owner);
    s.verticalAdjustment = value;
    _store.box<ReticleSettings>().put(s); // remove await
  }

  Future<void> setHorizontalAdjustment(double value) async {
    final s = _loadOrCreate(_owner);
    s.horizontalAdjustment = value;
    _store.box<ReticleSettings>().put(s); // remove await
  }

  Future<void> setVerticalAdjustmentUnit(Unit unit) async {
    final s = _loadOrCreate(_owner);
    s.verticalAdjustmentUnit = unit.name;
    _store.box<ReticleSettings>().put(s); // remove await
  }

  Future<void> setHorizontalAdjustmentUnit(Unit unit) async {
    final s = _loadOrCreate(_owner);
    s.horizontalAdjustmentUnit = unit.name;
    _store.box<ReticleSettings>().put(s); // remove await
  }

  Future<void> setVerticalAdjustmentUnitRaw(String name) async {
    final s = _loadOrCreate(_owner);
    s.verticalAdjustmentUnit = name;
    _store.box<ReticleSettings>().put(s);
  }

  Future<void> setHorizontalAdjustmentUnitRaw(String name) async {
    final s = _loadOrCreate(_owner);
    s.horizontalAdjustmentUnit = name;
    _store.box<ReticleSettings>().put(s);
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

/// Returns the user-selected [Locale] from settings, or null to fall back
/// to the system locale (handled by [MaterialApp.localeResolutionCallback]).
final localeProvider = Provider<Locale?>((ref) {
  final code = ref.watch(settingsProvider).value?.languageCode ?? '';
  return code.isNotEmpty ? Locale(code) : null;
});
