// Default seed data derived from real .a7p profiles (a7p-lib/gallery/338LM/).
// All scaled integer values are converted to physical units as per the a7p spec:
//   bc_cd  / 10000 → G7 BC
//   mv     / 10    → m/s
//   b_weight  / 10    → grain
//   b_diameter / 1000 → inch
//   b_length   / 1000 → inch
//   sc_height  / 10   → mm
//   r_twist    / 100  → inch

import 'package:bclibc_ffi/unit.dart';
import 'cartridge.dart';
import 'conditions_data.dart';
import 'rifle.dart';
import 'shot_profile.dart';
import 'sight.dart';

// ── Rifle ─────────────────────────────────────────────────────────────────────
// Based on .338LM UKROP profile (sc_height=8.5mm, r_twist=10")

final seedRifle = Rifle(
  id: 'seed-rifle-338lm',
  name: '.338 Lapua Magnum',
  vendor: 'Generic .338LM platform',
  sightHeight: Distance.millimeter(8.5),
  twist: Distance.inch(10.0),
  caliber: Distance.inch(0.338),
);

// ── Sight ─────────────────────────────────────────────────────────────────────

final seedSight = Sight(
  id: 'seed-sight-generic',
  name: 'Generic Long-Range Scope',
);

// ── Seed zero conditions ───────────────────────────────────────────────────────

final _seedZeroAtmo = AtmoData(
  altitude: Distance.meter(0.0),
  temperature: Temperature.celsius(15.0),
  pressure: Pressure.hPa(1000.0),
  humidity: 0.02,
  powderTemp: Temperature.celsius(15.0),
);

final _seedZeroConditions = Conditions.withDefaults(
  atmo: _seedZeroAtmo,
  winds: const [],
  lookAngle: Angular.degree(0.0),
  usePowderSensitivity: false,
  useDiffPowderTemp: false,
);

// ── Projectiles ───────────────────────────────────────────────────────────────
// 338LM_UKROP_250GR_SMK_G7 — single BC G7 0.314 @ 888 m/s

// 338LM_HORNADY_250GR_BTHP_G7 — single BC G7 0.322 @ 885 m/s

// 338LM_LAPUA_300GR_SMK_G7 — single BC G7 0.381 @ 825 m/s

// 338LM_STS_285GR_ELD_M_G7MBC — multi-BC G7

// ── Cartridges ────────────────────────────────────────────────────────────────
// Тепер використовуємо zeroConditions замість окремих полів

final seedCartridgeUkrop250 = Cartridge(
  id: 'seed-cart-ukrop-250-smk',
  name: '.338LM UKROP 250GR SMK',
  dragType: DragModelType.g7,
  weight: Weight.grain(250.0),
  diameter: Distance.inch(0.338),
  length: Distance.inch(1.555),
  coefRows: [CoeficientRow(bcCd: 0.314, mv: 888.0)],
  mv: Velocity.mps(888.0),
  powderTemp: Temperature.celsius(29.0),
  powderSensitivity: Ratio.fraction(0.02),
  zeroConditions: _seedZeroConditions, // ← використовуємо Conditions
);

final seedCartridgeHornady250 = Cartridge(
  id: 'seed-cart-hornady-250-bthp',
  name: '.338LM Hornady 250GR BTHP',
  dragType: DragModelType.g7,
  weight: Weight.grain(250.0),
  diameter: Distance.inch(0.338),
  length: Distance.inch(1.567),
  coefRows: [CoeficientRow(bcCd: 0.322, mv: 885.0)],
  mv: Velocity.mps(885.0),
  powderTemp: Temperature.celsius(15.0),
  powderSensitivity: Ratio.fraction(0.02),
  zeroConditions: _seedZeroConditions,
);

final seedCartridgeLapua300 = Cartridge(
  id: 'seed-cart-lapua-300-smk',
  name: '.338LM Lapua 300GR SMK',
  dragType: DragModelType.g7,
  weight: Weight.grain(300.0),
  diameter: Distance.inch(0.338),
  length: Distance.inch(1.700),
  coefRows: [CoeficientRow(bcCd: 0.381, mv: 825.0)],
  mv: Velocity.mps(825.0),
  powderTemp: Temperature.celsius(15.0),
  powderSensitivity: Ratio.fraction(0.123),
  zeroConditions: _seedZeroConditions,
);

final seedCartridgeSts285EldM = Cartridge(
  id: 'seed-cart-sts-285-eld-m',
  name: '.338LM Hornady 285GR ELD-M',
  dragType: DragModelType.g7,
  weight: Weight.grain(285.0),
  diameter: Distance.inch(0.338),
  length: Distance.inch(1.746),
  coefRows: [
    CoeficientRow(bcCd: 0.417, mv: 765.0),
    CoeficientRow(bcCd: 0.409, mv: 680.0),
    CoeficientRow(bcCd: 0.400, mv: 595.0),
  ],
  mv: Velocity.mps(810.0),
  powderTemp: Temperature.celsius(15.0),
  powderSensitivity: Ratio.fraction(0.02),
  zeroConditions: _seedZeroConditions,
);

final seedCartridges = [
  seedCartridgeUkrop250,
  seedCartridgeHornady250,
  seedCartridgeLapua300,
  seedCartridgeSts285EldM,
];

// ── Default Shot Profiles ─────────────────────────────────────────────────────
// Профілі тепер не містять умов (вони в окремому провайдері)

final seedShotProfile = ShotProfile(
  id: 'seed-profile-default',
  name: '.338LM UKROP 250GR SMK',
  rifle: seedRifle,
  cartridgeId: seedCartridgeUkrop250.id,
  cartridge: seedCartridgeUkrop250,
  sightId: seedSight.id,
  sight: seedSight,
);

final seedShotProfileHornady = ShotProfile(
  id: 'seed-profile-hornady-250',
  name: '.338LM Hornady 250GR BTHP',
  rifle: seedRifle,
  cartridgeId: seedCartridgeHornady250.id,
  cartridge: seedCartridgeHornady250,
  sightId: seedSight.id,
  sight: seedSight,
);

final seedShotProfileLapua300 = ShotProfile(
  id: 'seed-profile-lapua-300',
  name: '.338LM Lapua 300GR SMK',
  rifle: seedRifle,
  cartridgeId: seedCartridgeLapua300.id,
  cartridge: seedCartridgeLapua300,
  sightId: seedSight.id,
  sight: seedSight,
);

final seedShotProfiles = [
  seedShotProfile,
  seedShotProfileHornady,
  seedShotProfileLapua300,
];

// ── Default Conditions (для початкового стану) ─────────────────────────────────

final seedConditions = Conditions.withDefaults(
  atmo: AtmoData(
    altitude: Distance.meter(150.0),
    temperature: Temperature.celsius(20.0),
    pressure: Pressure.hPa(1013.25),
    humidity: 0.50,
    powderTemp: Temperature.celsius(20.0),
  ),
  winds: [
    WindData(
      velocity: Velocity.mps(3.0),
      directionFrom: Angular.degree(90.0),
      untilDistance: Distance.meter(9999.0),
    ),
  ],
  lookAngle: Angular.degree(0.0),
  distance: Distance.meter(300.0),
  usePowderSensitivity: false,
  useDiffPowderTemp: false,
  useCoriolis: false,
);
