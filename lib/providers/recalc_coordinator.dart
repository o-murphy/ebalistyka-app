import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../providers/calculation_provider.dart';
import '../src/models/app_settings.dart';
import '../viewmodels/home_vm.dart';
import '../viewmodels/tables_vm.dart';

/// Centralises all recalculation triggers.
///
/// Listens to [shotProfileProvider] and [settingsProvider] and triggers
/// both the new ViewModels (Phase 2) and the old calculation providers
/// (until Phase 4 migrates the screens).
class RecalcCoordinator extends Notifier<void> {
  @override
  void build() {
    ref.listen(shotProfileProvider, (_, next) {
      if (next.hasValue) _triggerAll();
    });

    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_needsRecalc(prev?.value, next.value!)) _triggerAll();
    });
  }

  /// Called from router/shell when a tab is activated.
  void onTabActivated(int tabIndex) {
    if (tabIndex == 0) {
      ref.read(homeVmProvider.notifier).recalculate();
      ref.read(homeCalculationProvider.notifier).recalculateIfNeeded();
    }
    if (tabIndex == 2) {
      ref.read(tablesVmProvider.notifier).recalculate();
      ref.read(tableCalculationProvider.notifier).recalculateIfNeeded();
    }
  }

  void _triggerAll() {
    // New ViewModels (Phase 2)
    ref.read(homeVmProvider.notifier).recalculate();
    ref.read(tablesVmProvider.notifier).recalculate();

    // Old calculation providers (still used by screens until Phase 4)
    ref.read(homeCalculationProvider.notifier).markDirty();
    ref.read(tableCalculationProvider.notifier).markDirty();
    ref.read(homeCalculationProvider.notifier).recalculateIfNeeded();
    ref.read(tableCalculationProvider.notifier).recalculateIfNeeded();
  }

  bool _needsRecalc(AppSettings? prev, AppSettings next) {
    if (prev == null) return true;
    return prev.enablePowderSensitivity != next.enablePowderSensitivity ||
        prev.useDifferentPowderTemperature !=
            next.useDifferentPowderTemperature ||
        prev.chartDistanceStep != next.chartDistanceStep ||
        prev.tableConfig.stepM != next.tableConfig.stepM;
  }
}

final recalcCoordinatorProvider =
    NotifierProvider<RecalcCoordinator, void>(RecalcCoordinator.new);
