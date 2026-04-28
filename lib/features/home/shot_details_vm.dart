import 'dart:async';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/services/ballistics_service.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';

sealed class ShotInfoUiState {
  const ShotInfoUiState();
}

class ShotInfoLoading extends ShotInfoUiState {
  const ShotInfoLoading();
}

class ShotInfoError extends ShotInfoUiState {
  final String? message;
  final EmptyStateType type;
  const ShotInfoError({this.message, this.type = EmptyStateType.error});
}

class ShotInfoReady extends ShotInfoUiState {
  // Velocity section
  final String currentMv;
  final String zeroMv;
  final String speedOfSound;
  final String velocityAtTarget;

  // Energy section
  final String energyAtMuzzle;
  final String energyAtTarget;

  // Stability section
  final String gyroscopicStability;

  // Trajectory section
  final String shotDistance;
  final String apexHeight;
  final String maxHeightDistance;
  final String windage;
  final String timeToTarget;

  const ShotInfoReady({
    required this.currentMv,
    required this.zeroMv,
    required this.speedOfSound,
    required this.velocityAtTarget,
    required this.energyAtMuzzle,
    required this.energyAtTarget,
    required this.gyroscopicStability,
    required this.shotDistance,
    required this.apexHeight,
    required this.maxHeightDistance,
    required this.windage,
    required this.timeToTarget,
  });
}

class ShotInfoViewModel extends AsyncNotifier<ShotInfoUiState> {
  @override
  Future<ShotInfoUiState> build() async {
    ref.listen<AsyncValue<ShotContext?>>(shotContextProvider, (_, next) {
      if (next.hasValue) unawaited(_recalculate());
    }, fireImmediately: true);
    ref.listen<AsyncValue<GeneralSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (prev?.value != null) unawaited(_recalculate());
    }, fireImmediately: true);
    ref.listen<UnitSettings>(unitSettingsProvider, (prev, next) {
      if (prev != null) unawaited(_recalculate());
    }, fireImmediately: true);
    return _calculate();
  }

  Future<void> _recalculate() async {
    try {
      final newState = await _calculate();
      if (!ref.mounted) return;
      state = AsyncData(newState);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<ShotInfoUiState> _calculate() async {
    try {
      final ctx = await ref.read(shotContextProvider.future);
      final settings = await ref.read(settingsProvider.future);
      final formatter = ref.read(unitFormatterProvider);

      if (ctx == null) {
        return const ShotInfoError(type: EmptyStateType.noProfile);
      }
      if (ctx.profile.ammo.target == null) {
        return const ShotInfoError(type: EmptyStateType.noAmmo);
      }

      if (!ctx.profile.isReadyForCalculation) {
        return const ShotInfoError(type: EmptyStateType.incompleteAmmo);
      }

      final profile = ctx.profile;
      final conditions = ctx.conditions;

      final opts = TargetCalcOptions(
        targetDistM: conditions.distanceMeter,
        stepM: settings.homeChartDistanceStep,
      );

      final result = await ref
          .read(ballisticsServiceProvider)
          .calculateForTarget(profile, conditions, opts);

      return _buildReadyState(profile, conditions, formatter, result.hitResult);
    } catch (e) {
      return ShotInfoError(message: e.toString());
    }
  }

  ShotInfoReady _buildReadyState(
    Profile profile,
    ShootingConditions conditions,
    UnitFormatter formatter,
    bclibc.HitResult hit,
  ) {
    final weapon = profile.weapon.target;
    final sight = profile.sight.target;

    final targetDistM = conditions.distanceMeter;
    final traj = hit.trajectory;
    final atTarget = hit.getAtDistance(Distance.meter(targetDistM));

    final zeroVelocity = profile.getCalculatedZeroVelocity();
    final curVelocity = profile.getCalculatedCurrentVelocity(conditions);

    // Speed of sound estimation from first trajectory point
    final double? soundSpeedFps = (traj.isNotEmpty && traj[0].mach > 0)
        ? (traj[0].velocity.in_(Unit.fps)) / traj[0].mach
        : null;

    // Gyroscopic stability
    final sightHeight = Distance.inch(sight?.sightHeightInch ?? 0.0);
    final bcWeapon = weapon?.toWeapon(sightHeight);
    String sgStr = nullStr;
    if (bcWeapon != null) {
      final currentShot = profile.toCurrentShot(conditions, bcWeapon);
      final sg = currentShot.calculateStabilityCoefficient();
      sgStr = sg.toStringAsFixed(2);
    }

    // Trajectory markers
    final firstPoint = traj.isNotEmpty ? traj[0] : null;
    bclibc.TrajectoryData? apexPoint;
    if (traj.length > 1) {
      apexPoint = traj.reduce(
        (a, b) => a.height.in_(Unit.meter) >= b.height.in_(Unit.meter) ? a : b,
      );
    }

    return ShotInfoReady(
      currentMv: formatter.velocity(curVelocity),
      zeroMv: formatter.velocity(zeroVelocity),
      speedOfSound: soundSpeedFps == null
          ? nullStr
          : formatter.velocity(Velocity.fps(soundSpeedFps)),
      velocityAtTarget: formatter.velocity(atTarget.velocity),
      energyAtMuzzle: formatter.energy(firstPoint?.energy),
      energyAtTarget: formatter.energy(atTarget.energy),
      gyroscopicStability: sgStr,
      shotDistance: formatter.distance(conditions.distance),
      apexHeight: formatter.drop(apexPoint?.height),
      maxHeightDistance: formatter.distance(apexPoint?.distance),
      windage: formatter.drop(atTarget.windage),
      timeToTarget: formatter.time(atTarget.time),
    );
  }
}

final shotInfoVmProvider =
    AsyncNotifierProvider<ShotInfoViewModel, ShotInfoUiState>(
      ShotInfoViewModel.new,
    );
