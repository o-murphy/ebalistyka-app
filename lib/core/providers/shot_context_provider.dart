import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:riverpod/riverpod.dart';

// ── ShotContext ───────────────────────────────────────────────────────────────

/// The minimal context required for a ballistics calculation:
/// the active profile and current shooting conditions.
class ShotContext {
  final Profile profile;
  final ShootingConditions conditions;

  const ShotContext({required this.profile, required this.conditions});
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ShotContextNotifier extends AsyncNotifier<ShotContext?> {
  @override
  Future<ShotContext?> build() async {
    final appState = await ref.watch(appStateProvider.future);
    final conditions = await ref.watch(shotConditionsProvider.future);
    final profile = appState.activeProfile;
    if (profile == null) return null;
    return ShotContext(profile: profile, conditions: conditions);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final shotContextProvider =
    AsyncNotifierProvider<ShotContextNotifier, ShotContext?>(
      ShotContextNotifier.new,
    );
