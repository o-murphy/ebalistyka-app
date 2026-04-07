import 'package:ebalistyka/core/models/conditions_data.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart'; // Змінений імпорт
import 'package:bclibc_ffi/unit.dart';
import 'package:riverpod/riverpod.dart';

class ShotConditionsNotifier extends AsyncNotifier<Conditions> {
  @override
  Future<Conditions> build() async {
    // Отримуємо умови з глобального стану
    final appState = await ref.watch(appStateProvider.future);
    final conditions = appState.conditions;

    Conditions loaded = conditions ?? Conditions.withDefaults();
    final laDeg = loaded.lookAngle.in_(Unit.degree);
    if (laDeg.abs() > 45) {
      loaded = loaded.copyWith(lookAngle: Angular.degree(0.0));
    }

    return loaded;
  }

  Future<void> updateAtmo(AtmoData atmo) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(atmo: atmo));
  }

  Future<void> updateWinds(List<WindData> winds) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(winds: winds));
  }

  Future<void> updateLookAngle(double degrees) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(lookAngle: Angular.degree(degrees)));
  }

  Future<void> updateTargetDistance(double meters) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(distance: Distance.meter(meters)));
  }

  Future<void> updateUsePowderSensitivity(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(usePowderSensitivity: value));
  }

  Future<void> updateUseDiffPowderTemp(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(useDiffPowderTemp: value));
  }

  Future<void> updateUseCoriolis(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(useCoriolis: value));
  }

  Future<void> updateLatitude(double? degrees) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(latitudeDeg: degrees));
  }

  Future<void> updateAzimuth(double? degrees) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(azimuthDeg: degrees));
  }

  Future<void> updateWindSpeed(double mps) async {
    final current = state.value;
    if (current == null) return;

    final existing = current.winds;
    final dir = existing.isNotEmpty
        ? existing.first.directionFrom
        : Angular.degree(0.0);
    final until = existing.isNotEmpty
        ? existing.first.untilDistance
        : Distance.meter(9999.0);

    await _save(
      current.copyWith(
        winds: [
          WindData(
            velocity: Velocity.mps(mps),
            directionFrom: dir,
            untilDistance: until,
          ),
        ],
      ),
    );
  }

  Future<void> _save(Conditions newConditions) async {
    // Оновлюємо локальний стан
    state = AsyncData(newConditions);

    // Оновлюємо глобальний стан через appStateProvider
    final appStateNotifier = ref.read(appStateProvider.notifier);
    await appStateNotifier.saveConditions(newConditions);
  }
}

final shotConditionsProvider =
    AsyncNotifierProvider<ShotConditionsNotifier, Conditions>(
      ShotConditionsNotifier.new,
    );
