import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/providers/db_provider.dart';
import 'package:riverpod/riverpod.dart';

class ShotConditionsNotifier extends AsyncNotifier<ShootingConditions> {
  Store get _store => ref.read(dbProvider);
  Owner get _owner => ref.read(ownerProvider);

  @override
  Future<ShootingConditions> build() async => _load();

  ShootingConditions _load() {
    final owner = _owner;
    final existing = _store
        .box<ShootingConditions>()
        .query(ShootingConditions_.owner.equals(owner.id))
        .build()
        .findFirst();
    if (existing != null) return existing;
    final cond = ShootingConditions()..owner.target = owner;
    _store.box<ShootingConditions>().put(cond);
    return cond;
  }

  Future<void> _save(ShootingConditions cond) async {
    _store.box<ShootingConditions>().put(cond);
    state = AsyncData(cond);
  }

  // ── Distance / geometry ───────────────────────────────────────────────────────

  Future<void> updateDistance(double meters) async {
    final s = state.value ?? _load();
    s.distanceMeter = meters;
    await _save(s);
  }

  Future<void> updateLookAngle(double degrees) async {
    final s = state.value ?? _load();
    s.lookAngleRad = Angular.degree(degrees).in_(Unit.radian);
    await _save(s);
  }

  Future<void> updateAltitude(double meters) async {
    final s = state.value ?? _load();
    s.altitudeMeter = meters;
    await _save(s);
  }

  // ── Atmosphere ────────────────────────────────────────────────────────────────

  Future<void> updateTemperature(double celsius) async {
    final s = state.value ?? _load();
    s.temperatureC = celsius;
    await _save(s);
  }

  Future<void> updatePressure(double hpa) async {
    final s = state.value ?? _load();
    s.pressurehPa = hpa;
    await _save(s);
  }

  Future<void> updateHumidity(double fraction) async {
    final s = state.value ?? _load();
    s.humidityFrac = fraction;
    await _save(s);
  }

  Future<void> updatePowderTemperature(double celsius) async {
    final s = state.value ?? _load();
    s.powderTemperatureC = celsius;
    await _save(s);
  }

  // ── Wind ──────────────────────────────────────────────────────────────────────

  Future<void> updateWindSpeed(double mps) async {
    final s = state.value ?? _load();
    s.windSpeedMps = mps;
    await _save(s);
  }

  Future<void> updateWindDirection(double degrees) async {
    final s = state.value ?? _load();
    s.windDirectionDeg = degrees;
    await _save(s);
  }

  // ── Flags ─────────────────────────────────────────────────────────────────────

  Future<void> updateUsePowderSensitivity(bool value) async {
    final s = state.value ?? _load();
    s.usePowderSensitivity = value;
    await _save(s);
  }

  Future<void> updateUseDiffPowderTemp(bool value) async {
    final s = state.value ?? _load();
    s.useDiffPowderTemp = value;
    await _save(s);
  }

  Future<void> updateUseCoriolis(bool value) async {
    final s = state.value ?? _load();
    s.useCoriolis = value;
    await _save(s);
  }

  Future<void> updateLatitude(double? degrees) async {
    final s = state.value ?? _load();
    s.latitudeDeg = degrees ?? 0.0;
    await _save(s);
  }

  Future<void> updateAzimuth(double? degrees) async {
    final s = state.value ?? _load();
    s.azimuthDeg = degrees ?? 0.0;
    await _save(s);
  }
}

final shotConditionsProvider =
    AsyncNotifierProvider<ShotConditionsNotifier, ShootingConditions>(
      ShotConditionsNotifier.new,
    );
