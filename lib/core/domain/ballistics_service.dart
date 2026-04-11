import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;

class TableCalcOptions {
  final double startM;
  final double endM;
  final double stepM;

  const TableCalcOptions({this.startM = 0, this.endM = 2000, this.stepM = 100});
}

class TargetCalcOptions {
  final double targetDistM;

  /// If null, trajectory ends at [targetDistM].
  final double? trajectoryEndM;

  /// Table column step. If provided, the service computes hold corrections
  /// for each table column (targetDistM ± n*tableStepM) inside the isolate.
  final double? tableStepM;

  final double stepM;

  const TargetCalcOptions({
    required this.targetDistM,
    this.trajectoryEndM,
    this.tableStepM,
    this.stepM = 10,
  });
}

class BallisticsResult {
  final bclibc.HitResult hitResult;
  final double zeroElevationRad;

  /// Hold angle (elevation correction relative to zero) for the target distance.
  /// Zero for table calculations where no target hold is computed.
  final double holdRad;

  /// Hold corrections for each of the 5 home table columns
  /// [target-2s, target-s, target, target+s, target+2s].
  /// Empty when [TargetCalcOptions.tableStepM] is not provided.
  final List<double> tableHolds;

  const BallisticsResult({
    required this.hitResult,
    required this.zeroElevationRad,
    this.holdRad = 0.0,
    this.tableHolds = const [],
  });
}

abstract interface class BallisticsService {
  Future<BallisticsResult> calculateTable(
    Profile profile,
    ShootingConditions conditions,
    TableCalcOptions opts,
  );

  Future<BallisticsResult> calculateForTarget(
    Profile profile,
    ShootingConditions conditions,
    TargetCalcOptions opts,
  );
}
