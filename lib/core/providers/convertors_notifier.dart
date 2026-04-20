import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/providers/db_provider.dart';
import 'package:riverpod/riverpod.dart';

class ConvertorsNotifier extends AsyncNotifier<ConvertorsState> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<ConvertorsState> build() async {
    final owner = _owner;
    final s = _loadOrCreate(owner);

    final subscription = _store
        .box<ConvertorsState>()
        .query(ConvertorsState_.owner.equals(owner.id))
        .watch(triggerImmediately: false)
        .listen((query) {
          final updated = query.findFirst();
          if (updated != null) state = AsyncData(updated);
        });
    ref.onDispose(subscription.cancel);

    return s;
  }

  ConvertorsState _loadOrCreate(Owner owner) {
    final existing = _store
        .box<ConvertorsState>()
        .query(ConvertorsState_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final s = ConvertorsState()..owner.target = owner;
    _store.box<ConvertorsState>().put(s);
    return s;
  }

  ConvertorsState _load() => _loadOrCreate(_owner);

  Future<void> _save(ConvertorsState s) async {
    _store.box<ConvertorsState>().put(s);
    final fresh = _store.box<ConvertorsState>().get(s.id);
    if (fresh != null) state = AsyncData(fresh);
  }

  // ── Length ────────────────────────────────────────────────────────────────────

  Future<void> updateLengthValue(double? valueInInches) async {
    if (valueInInches == null || valueInInches < 0) return;
    final s = state.value ?? _load();
    s.lengthValueInch = valueInInches;
    await _save(s);
  }

  Future<void> updateLengthUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.lengthUnit = unit;
    await _save(s);
  }

  // ── Weight ────────────────────────────────────────────────────────────────────

  Future<void> updateWeightValue(double? valueInGrains) async {
    if (valueInGrains == null || valueInGrains < 0) return;
    final s = state.value ?? _load();
    s.weightValueGrain = valueInGrains;
    await _save(s);
  }

  Future<void> updateWeightUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.weightUnit = unit;
    await _save(s);
  }

  // ── Pressure ──────────────────────────────────────────────────────────────────

  Future<void> updatePressureValue(double? valueInMmHg) async {
    if (valueInMmHg == null || valueInMmHg < 0) return;
    final s = state.value ?? _load();
    s.pressureValueMmHg = valueInMmHg;
    await _save(s);
  }

  Future<void> updatePressureUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.pressureUnit = unit;
    await _save(s);
  }

  // ── Temperature ───────────────────────────────────────────────────────────────

  Future<void> updateTemperatureValue(double? valueInFahrenheit) async {
    if (valueInFahrenheit == null) return;
    final s = state.value ?? _load();
    s.temperatureValueF = valueInFahrenheit;
    await _save(s);
  }

  Future<void> updateTemperatureUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.temperatureUnit = unit;
    await _save(s);
  }

  // ── Torque ────────────────────────────────────────────────────────────────────

  Future<void> updateTorqueValue(double? valueInNewtonMeter) async {
    if (valueInNewtonMeter == null || valueInNewtonMeter < 0) return;
    final s = state.value ?? _load();
    s.torqueValueNewtonMeter = valueInNewtonMeter;
    await _save(s);
  }

  Future<void> updateTorqueUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.torqueUnit = unit;
    await _save(s);
  }

  // ── Velocity ──────────────────────────────────────────────────────────────────

  Future<void> updateVelocityValue(double? valueInMps) async {
    if (valueInMps == null || valueInMps < 0) return;
    final s = state.value ?? _load();
    s.velocityValueMps = valueInMps;
    await _save(s);
  }

  Future<void> updateVelocityUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.velocityUnit = unit;
    await _save(s);
  }

  // ── Angles convertor ──────────────────────────────────────────────────────────

  Future<void> updateAnglesConvDistanceValue(double? valueInMeters) async {
    if (valueInMeters == null || valueInMeters < 0) return;
    final s = state.value ?? _load();
    s.anglesConvDistanceValueMeter = valueInMeters;
    await _save(s);
  }

  Future<void> updateAnglesConvDistanceUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.anglesConvDistanceUnit = unit;
    await _save(s);
  }

  Future<void> updateAnglesConvAngularValue(double? valueInMil) async {
    if (valueInMil == null || valueInMil < 0) return;
    final s = state.value ?? _load();
    s.anglesConvAngularValueMil = valueInMil;
    await _save(s);
  }

  Future<void> updateAnglesConvAngularUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.anglesConvAngularUnit = unit;
    await _save(s);
  }

  Future<void> updateAnglesConvOutputUnit(Unit unit) async {
    final s = state.value ?? _load();
    s.anglesConvOutputUnit = unit;
    await _save(s);
  }
}

final convertorsProvider =
    AsyncNotifierProvider<ConvertorsNotifier, ConvertorsState>(
      ConvertorsNotifier.new,
    );

/// Synchronous access — returns defaults while loading.
final convertorStateProvider = Provider<ConvertorsState>((ref) {
  return ref.watch(convertorsProvider).value ?? ConvertorsState();
});
