import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/models/app_settings.dart';
import 'package:ebalistyka/core/solver/unit.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    // Отримуємо налаштування з глобального стану
    final appState = await ref.watch(appStateProvider.future);
    return appState.settings ?? const AppSettings();
  }

  Future<void> setUnit(String key, Unit unit) async {
    final current = state.value ?? const AppSettings();
    final newSettings = current.copyWith(
      units: _setUnitByKey(current.units, key, unit),
    );
    await _save(newSettings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final newSettings = (state.value ?? const AppSettings()).copyWith(
      themeMode: mode,
    );
    await _save(newSettings);
  }

  Future<void> setLanguage(String code) async {
    final newSettings = (state.value ?? const AppSettings()).copyWith(
      languageCode: code,
    );
    await _save(newSettings);
  }

  Future<void> setSwitch(String key, bool value) async {
    final s = state.value ?? const AppSettings();
    final newSettings = switch (key) {
      'coriolis' => s.copyWith(enableCoriolis: value),
      'derivation' => s.copyWith(enableDerivation: value),
      'aerodynamicJump' => s.copyWith(enableAerodynamicJump: value),
      'pressureFromAltitude' => s.copyWith(pressureDependsOnAltitude: value),
      'subsonicTransition' => s.copyWith(showSubsonicTransition: value),
      _ => s,
    };
    await _save(newSettings);
  }

  Future<void> updateTableConfig(TableConfig config) async {
    final newSettings = (state.value ?? const AppSettings()).copyWith(
      tableConfig: config,
    );
    await _save(newSettings);
  }

  Future<void> setChartDistanceStep(double step) async {
    final newSettings = (state.value ?? const AppSettings()).copyWith(
      chartDistanceStep: step,
    );
    await _save(newSettings);
  }

  Future<void> setHomeTableStep(double step) async {
    final newSettings = (state.value ?? const AppSettings()).copyWith(
      homeTableStep: step,
    );
    await _save(newSettings);
  }

  Future<void> setAdjustmentFormat(AdjustmentFormat format) async {
    final newSettings = (state.value ?? const AppSettings()).copyWith(
      adjustmentFormat: format,
    );
    await _save(newSettings);
  }

  Future<void> setAdjustmentToggle(String key, bool value) async {
    final s = state.value ?? const AppSettings();
    final newSettings = switch (key) {
      'showMrad' => s.copyWith(showMrad: value),
      'showMoa' => s.copyWith(showMoa: value),
      'showMil' => s.copyWith(showMil: value),
      'showCmPer100m' => s.copyWith(showCmPer100m: value),
      'showInPer100yd' => s.copyWith(showInPer100yd: value),
      _ => s,
    };
    await _save(newSettings);
  }

  Future<void> _save(AppSettings newSettings) async {
    // Оновлюємо локальний стан
    state = AsyncData(newSettings);

    // Оновлюємо глобальний стан
    final appStateNotifier = ref.read(appStateProvider.notifier);
    await appStateNotifier.saveSettings(newSettings);
  }

  UnitSettings _setUnitByKey(UnitSettings u, String key, Unit unit) =>
      switch (key) {
        'angular' => u.copyWith(angular: unit),
        'distance' => u.copyWith(distance: unit),
        'velocity' => u.copyWith(velocity: unit),
        'pressure' => u.copyWith(pressure: unit),
        'temperature' => u.copyWith(temperature: unit),
        'diameter' => u.copyWith(diameter: unit),
        'length' => u.copyWith(length: unit),
        'weight' => u.copyWith(weight: unit),
        'adjustment' => u.copyWith(adjustment: unit),
        'drop' => u.copyWith(drop: unit),
        'energy' => u.copyWith(energy: unit),
        'sightHeight' => u.copyWith(sightHeight: unit),
        'twist' => u.copyWith(twist: unit),
        'time' => u.copyWith(time: unit),
        _ => u,
      };
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Synchronous access — returns defaults while loading.
final unitSettingsProvider = Provider<UnitSettings>((ref) {
  return ref.watch(settingsProvider).value?.units ?? const UnitSettings();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
});
