import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/shot_details_vm.dart';
import 'package:ebalistyka/features/tables/trajectory_tables_vm.dart';
import 'package:riverpod/riverpod.dart';

/// Centralises all recalculation triggers.
///
/// Listens to [shotContextProvider], [settingsProvider],
/// [unitSettingsNotifierProvider], and [reticleSettingsNotifierProvider]
/// and triggers the ViewModels for the active features.
class RecalcCoordinator extends Notifier<void> {
  @override
  void build() {
    ref.listen(shotContextProvider, (_, next) {
      if (next.hasValue) _triggerAll();
    });

    ref.listen<AsyncValue<GeneralSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_generalNeedsRecalc(prev?.value, next.value!)) _triggerAll();
    });

    ref.listen<AsyncValue<UnitSettings>>(unitSettingsNotifierProvider, (
      prev,
      next,
    ) {
      if (!next.hasValue) return;
      if (prev?.value != null) _triggerAll(); // any unit change → recalc
    });

    ref.listen<AsyncValue<ReticleSettings>>(reticleSettingsNotifierProvider, (
      prev,
      next,
    ) {
      if (!next.hasValue) return;
      if (prev?.value != null) _triggerAll();
    });
  }

  /// Called from router/shell when a tab is activated.
  void onTabActivated(int tabIndex) {
    if (tabIndex == 0) {
      ref.read(homeVmProvider.notifier).recalculate();
      ref.read(shotDetailsVmProvider.notifier).recalculate();
    }
    if (tabIndex == 2) {
      ref.read(trajectoryTablesVmProvider.notifier).recalculate();
    }
  }

  void _triggerAll() {
    ref.read(homeVmProvider.notifier).recalculate();
    ref.read(trajectoryTablesVmProvider.notifier).recalculate();
    ref.read(shotDetailsVmProvider.notifier).recalculate();
  }

  bool _generalNeedsRecalc(GeneralSettings? prev, GeneralSettings next) {
    if (prev == null) return true;
    return prev.homeChartDistanceStep != next.homeChartDistanceStep ||
        prev.homeTableDistanceStep != next.homeTableDistanceStep ||
        prev.homeShowMrad != next.homeShowMrad ||
        prev.homeShowMoa != next.homeShowMoa ||
        prev.homeShowMil != next.homeShowMil ||
        prev.homeShowCmPer100m != next.homeShowCmPer100m ||
        prev.homeShowInPer100yd != next.homeShowInPer100yd ||
        prev.homeShowSubsonicTransition != next.homeShowSubsonicTransition;
  }
}

final recalcCoordinatorProvider = NotifierProvider<RecalcCoordinator, void>(
  RecalcCoordinator.new,
);
