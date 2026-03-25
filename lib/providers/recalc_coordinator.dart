import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../src/models/app_settings.dart';
import '../viewmodels/home_vm.dart';
import '../viewmodels/tables_vm.dart';

/// Centralises all recalculation triggers.
///
/// Listens to [shotProfileProvider] and [settingsProvider] and triggers
/// the new ViewModels and the old [homeCalculationProvider] (still used by
/// shot_details_screen.dart).
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
    }
  }

  void _triggerAll() {
    ref.read(homeVmProvider.notifier).recalculate();
    ref.read(tablesVmProvider.notifier).recalculate();
    // homeCalculationProvider still used by shot_details_screen
    ref.read(homeCalculationProvider.notifier).markDirty();
    ref.read(homeCalculationProvider.notifier).recalculateIfNeeded();
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
