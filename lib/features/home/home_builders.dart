import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:ebalistyka/shared/models/chart_point.dart';
import 'package:ebalistyka/shared/models/formatted_row.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

import 'home_ui_state.dart';

// ── Builders ──────────────────────────────────────────────────────────────────

bool generalNeedsRecalc(GeneralSettings? prev, GeneralSettings next) {
  if (prev == null) return true;
  return prev.homeChartDistanceStep != next.homeChartDistanceStep ||
      prev.homeTableDistanceStep != next.homeTableDistanceStep ||
      prev.homeShowMrad != next.homeShowMrad ||
      prev.homeShowMoa != next.homeShowMoa ||
      prev.homeShowMil != next.homeShowMil ||
      prev.homeShowCmPer100m != next.homeShowCmPer100m ||
      prev.homeShowInPer100yd != next.homeShowInPer100yd ||
      prev.homeShowInClicks != next.homeShowInClicks ||
      prev.homeShowSubsonicTransition != next.homeShowSubsonicTransition;
}

double parseMilWidth(String svg) {
  final m = RegExp(
    r'viewBox="[^"]*?\s+[^"]*?\s+([^"]*?)\s+[^"]*?"',
  ).firstMatch(svg);
  return m != null ? double.tryParse(m.group(1)!) ?? 0.5 : 0.0;
}

String? buildZeroOffsetMessageLine({
  required Unit zeroOffsetYUnit,
  required Unit zeroOffsetXUnit,
  required double zeroOffsetYMil,
  required double zeroOffsetXMil,
}) {
  if (zeroOffsetYMil == 0.0 && zeroOffsetXMil == 0.0) return null;

  final parts = <String>[];

  if (zeroOffsetYMil != 0.0) {
    parts.add(_angularPart(zeroOffsetYMil, zeroOffsetYUnit, 'vertical'));
  }
  if (zeroOffsetXMil != 0.0) {
    parts.add(_angularPart(zeroOffsetXMil, zeroOffsetXUnit, 'horizontal'));
  }

  return 'Zero offset: ${parts.join(' / ')}';
}

String? buildAdjustedMessageLine(
  ReticleSettings reticle, {
  required double vClickSizeMil,
  required double hClickSizeMil,
  required AppLocalizations l10n,
}) {
  final vAdj = reticle.verticalAdjustment;
  final hAdj = reticle.horizontalAdjustment;

  if (vAdj == 0.0 && hAdj == 0.0) return null;

  final parts = <String>[];

  if (vAdj != 0.0) {
    final part = reticle.verticalAdjInClicks && vClickSizeMil > 0
        ? _clicksPart(vAdj, vClickSizeMil, 'vertical')
        : _angularPart(vAdj, reticle.verticalAdjustmentUnitValue, 'vertical');
    parts.add(part);
  }
  if (hAdj != 0.0) {
    final part = reticle.horizontalAdjInClicks && hClickSizeMil > 0
        ? _clicksPart(hAdj, hClickSizeMil, 'horizontal')
        : _angularPart(
            hAdj,
            reticle.horizontalAdjustmentUnitValue,
            'horizontal',
          );
    parts.add(part);
  }
  return '${l10n.drumAdjustment}: ${parts.join(' / ')}';
}

String buildCartridgeInfoLine(
  Profile profile,
  ShootingConditions conditions,
  UnitFormatter formatter,
  AppLocalizations l10n,
) {
  final ammo = profile.ammo.target!;
  final weapon = profile.weapon.target;
  final sight = profile.sight.target;

  final mvStr = formatter.velocity(ammo.mv);
  final dragStr = ammo.dragModelFormattedInfo;

  String? sgStr;
  if (weapon != null && ammo.weightGrain > 0 && ammo.caliberInch > 0) {
    final sightHeight = sight?.sightHeight ?? Distance.inch(0.0);
    final bcWeapon = weapon.toWeapon(sightHeight);
    final currentShot = profile.toCurrentShot(conditions, bcWeapon);
    final sg = currentShot.calculateStabilityCoefficient();
    sgStr = '${l10n.sgAbbr} ${sg.toFixedSafe(2)}';
  }

  return '${ammo.projectileName ?? ammo.name};  $mvStr;  $dragStr${sgStr != null ? ';  $sgStr' : ''}';
}

AdjustmentData buildAdjustment(
  bclibc.HitResult hit,
  double targetM,
  Angular elevAngle,
  Angular windAngle,
  double horizontalClickSizeMil,
  double verticalClickSizeMil,
  GeneralSettings settings,
  AppLocalizations l10n,
) {
  final dispUnits = <(Unit, String)>[
    if (settings.homeShowMrad) (Unit.mRad, Unit.mRad.localizedSymbol(l10n)),
    if (settings.homeShowMoa) (Unit.moa, Unit.moa.localizedSymbol(l10n)),
    if (settings.homeShowMil) (Unit.mil, Unit.mil.localizedSymbol(l10n)),
    if (settings.homeShowCmPer100m)
      (Unit.cmPer100m, Unit.cmPer100m.localizedSymbol(l10n)),
    if (settings.homeShowInPer100yd)
      (Unit.inPer100Yd, Unit.inPer100Yd.localizedSymbol(l10n)),
  ];

  final elevValues = dispUnits.map((u) {
    final val = elevAngle.in_(u.$1);
    return AdjustmentValue(
      absValue: val.abs(),
      isPositive: val >= 0,
      symbol: u.$2,
      decimals: FC.adjustment.accuracyFor(u.$1),
    );
  }).toList();

  if (settings.homeShowInClicks) {
    final val = elevAngle.in_(Unit.mil);
    final clicks = verticalClickSizeMil > 0.0
        ? val / verticalClickSizeMil
        : 0.0;
    elevValues.add(
      AdjustmentValue(
        absValue: clicks.abs(),
        isPositive: clicks >= 0,
        symbol: l10n.unitClicks,
        decimals: 0,
        isClicks: true,
      ),
    );
  }

  final windValues = dispUnits.map((u) {
    final corr = windAngle.in_(u.$1);
    return AdjustmentValue(
      absValue: corr.abs(),
      isPositive: corr >= 0,
      symbol: u.$2,
      decimals: FC.adjustment.accuracyFor(u.$1),
    );
  }).toList();

  if (settings.homeShowInClicks) {
    final val = windAngle.in_(Unit.mil);
    final clicks = horizontalClickSizeMil > 0.0
        ? val / horizontalClickSizeMil
        : 0.0;
    windValues.add(
      AdjustmentValue(
        absValue: clicks.abs(),
        isPositive: clicks >= 0,
        symbol: l10n.unitClicks,
        decimals: 0,
        isClicks: true,
      ),
    );
  }

  return AdjustmentData(elevation: elevValues, windage: windValues);
}

FormattedTableData buildHomeTable(
  bclibc.HitResult hit,
  double targetM,
  double zeroElevRad,
  List<double> tableHolds,
  GeneralSettings settings,
  UnitSettings units,
  UnitFormatter fmt,
  AppLocalizations l10n,
) {
  final stepM = settings.homeTableDistanceStep;
  final distUnit = units.distanceUnit;
  final dropUnit = units.dropUnit;
  final velUnit = units.velocityUnit;
  final energyUnit = units.energyUnit;
  final distAcc = FC.targetDistance.accuracyFor(distUnit);

  final dists = [
    targetM - 2 * stepM,
    targetM - stepM,
    targetM,
    targetM + stepM,
    targetM + 2 * stepM,
  ];

  final points = dists
      .map((d) => d < 0 ? null : hit.getAtDistance(Distance.meter(d)))
      .toList();

  final distHeaders = dists.map<String>((m) {
    if (m < 0) return nullStr;
    final disp = Distance.meter(m).in_(distUnit);
    return disp.toFixedSafe(distAcc);
  }).toList();

  const targetCol = 2;
  final milAcc = FC.adjustment.accuracyFor(Unit.mil);
  final moaAcc = FC.adjustment.accuracyFor(Unit.moa);

  // Rows derived from trajectory points (single fired trajectory).
  final trajRowDefs =
      <(String, String, double? Function(bclibc.TrajectoryData), int)>[
        (
          'Height',
          dropUnit.localizedSymbol(l10n),
          (p) => p.height.in_(dropUnit),
          FC.drop.accuracyFor(dropUnit),
        ),
        ('Elev', 'MIL', (p) => p.dropAngle.in_(Unit.mil), milAcc),
        ('Elev', 'MOA', (p) => p.dropAngle.in_(Unit.moa), moaAcc),
        (
          'Windage',
          dropUnit.localizedSymbol(l10n),
          (p) => p.windage.in_(dropUnit),
          FC.drop.accuracyFor(dropUnit),
        ),
        (
          'Velocity',
          velUnit.localizedSymbol(l10n),
          (p) => p.velocity.in_(velUnit),
          FC.velocity.accuracyFor(velUnit),
        ),
        (
          'Energy',
          energyUnit.localizedSymbol(l10n),
          (p) => p.energy.in_(energyUnit),
          FC.energy.accuracyFor(energyUnit),
        ),
        ('Time', 's', (p) => p.time, 3),
      ];

  // Drop (hold) rows — barrelElevationForTarget(d) - zeroElevRad for each
  // column, matching the hold value shown on Page 1 (reticle).
  FormattedRow buildDropRow(String unitLabel, Unit u, int acc) {
    final cells = <FormattedCell>[];
    for (var ci = 0; ci < dists.length; ci++) {
      final hold = tableHolds.length > ci ? tableHolds[ci] : double.nan;
      final valStr = (hold.isNaN || dists[ci] < 0)
          ? nullStr
          : Angular.radian(hold).in_(u).toFixedSafe(acc);
      cells.add(FormattedCell(value: valStr, isTargetColumn: ci == targetCol));
    }
    return FormattedRow(
      label: l10n.columnDrop,
      unitSymbol: unitLabel,
      cells: cells,
    );
  }

  FormattedRow buildTrajRow(
    (String, String, double? Function(bclibc.TrajectoryData), int) rd,
  ) {
    final cells = <FormattedCell>[];
    for (var ci = 0; ci < dists.length; ci++) {
      final p = points[ci];
      final valStr = p == null
          ? nullStr
          : (rd.$3(p) ?? double.nan).toFixedSafe(rd.$4);
      cells.add(FormattedCell(value: valStr, isTargetColumn: ci == targetCol));
    }
    return FormattedRow(label: rd.$1, unitSymbol: rd.$2, cells: cells);
  }

  // Row order: Height, Elev MIL, Elev MOA, Drop MIL, Drop MOA,
  //            Windage (distance), Velocity, Energy, Time
  final rows = [
    buildTrajRow(trajRowDefs[0]), // Height
    buildTrajRow(trajRowDefs[1]), // Elev MIL
    buildTrajRow(trajRowDefs[2]), // Elev MOA
    buildDropRow('MIL', Unit.mil, milAcc),
    buildDropRow('MOA', Unit.moa, moaAcc),
    buildTrajRow(trajRowDefs[3]), // Windage (distance)
    buildTrajRow(trajRowDefs[4]), // Velocity
    buildTrajRow(trajRowDefs[5]), // Energy
    buildTrajRow(trajRowDefs[6]), // Time
  ];

  return FormattedTableData(
    distanceHeaders: distHeaders,
    rows: rows,
    distanceUnit: distUnit.localizedSymbol(l10n),
  );
}

int? closestIndex(List<ChartPoint> points, double targetM) {
  if (points.isEmpty) return null;
  var best = 0;
  var bestDist = (points[0].distanceM - targetM).abs();
  for (var i = 1; i < points.length; i++) {
    final d = (points[i].distanceM - targetM).abs();
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

ChartData buildChartData(
  bclibc.HitResult hit,
  double targetM,
  GeneralSettings settings,
) {
  final step = settings.homeChartDistanceStep;

  final points = List.generate((targetM / step).ceil() + 1, (i) => i * step)
      .where((d) => d <= targetM)
      .map((d) {
        final td = hit.getAtDistance(Distance.meter(d));

        final isZero = (td.flag & bclibc.TrajFlag.zero.value) != 0;
        final isMach = (td.flag & bclibc.TrajFlag.mach.value) != 0;

        return ChartPoint(
          distanceM: td.distance.in_(Unit.meter),
          heightCm: td.height.in_(Unit.centimeter),
          velocityMps: td.velocity.in_(Unit.mps),
          mach: td.mach,
          energyJ: td.energy.in_(Unit.joule),
          time: td.time,
          dropAngleMil: td.dropAngle.in_(Unit.mil),
          windageAngleMil: td.windageAngle.in_(Unit.mil),
          isZeroCrossing: isZero,
          isSubsonic: isMach || td.mach < 1.0,
        );
      })
      .whereType<ChartPoint>()
      .toList();

  return ChartData(points: points, snapDistM: step);
}

HomeChartPointInfo buildPointInfo(ChartPoint point, UnitFormatter formatter) {
  return HomeChartPointInfo(
    distance: formatter.distance(Distance(point.distanceM, Unit.meter)),
    velocity: formatter.velocity(Velocity(point.velocityMps, Unit.mps)),
    energy: formatter.energy(Energy(point.energyJ, Unit.joule)),
    time: formatter.time(point.time),
    height: formatter.drop(Distance(point.heightCm / 100.0, Unit.meter)),
    drop: '${point.dropAngleMil.toFixedSafe(2)} ${formatter.adjustmentSymbol}',
    windage:
        '${point.windageAngleMil.toFixedSafe(2)} ${formatter.adjustmentSymbol}',
    mach: formatter.mach(point.mach),
  );
}

// ── Private helpers ───────────────────────────────────────────────────────────

String _clicksPart(double rawMil, double clickSizeMil, String dir) {
  final clicks = rawMil / clickSizeMil;
  final v = clicks.toStringAsFixed(0);
  return '${clicks > 0 ? '+' : ''}$v click $dir';
}

String _angularPart(double adjInUnit, Unit unit, String dir) {
  final acc = FC.adjustment.accuracyFor(unit);
  return '${adjInUnit > 0 ? '+' : ''}${adjInUnit.toFixedSafe(acc)} ${_unitLabel(unit)} $dir';
}

String _unitLabel(Unit u) => switch (u) {
  Unit.mRad => 'MRAD',
  Unit.moa => 'MOA',
  Unit.mil => 'MIL',
  Unit.cmPer100m => 'cm/100m',
  Unit.inPer100Yd => 'in/100yd',
  _ => u.name.toUpperCase(),
};
