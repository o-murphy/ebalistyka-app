import 'dart:async';
import 'package:bclibc_ffi/unit.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_profile_provider.dart';

sealed class ShotDetailsUiState {
  const ShotDetailsUiState();
}

class ShotDetailsLoading extends ShotDetailsUiState {
  const ShotDetailsLoading();
}

class ShotDetailsError extends ShotDetailsUiState {
  final String message;
  const ShotDetailsError(this.message);
}

class ShotDetailsReady extends ShotDetailsUiState {
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
  final String heightAtTarget;
  final String maxHeightDistance;
  final String windage;
  final String timeToTarget;

  const ShotDetailsReady({
    required this.currentMv,
    required this.zeroMv,
    required this.speedOfSound,
    required this.velocityAtTarget,
    required this.energyAtMuzzle,
    required this.energyAtTarget,
    required this.gyroscopicStability,
    required this.shotDistance,
    required this.heightAtTarget,
    required this.maxHeightDistance,
    required this.windage,
    required this.timeToTarget,
  });
}

class ShotDetailsViewModel extends AsyncNotifier<ShotDetailsUiState> {
  @override
  Future<ShotDetailsUiState> build() async {
    return _calculate();
  }

  Future<void> recalculate() async {
    try {
      final newState = await _calculate();
      if (!ref.mounted) return;
      state = AsyncData(newState);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<ShotDetailsUiState> _calculate() async {
    try {
      final profile = await ref.read(shotProfileProvider.future);
      final conditions = await ref.read(shotConditionsProvider.future);
      final settings = await ref.read(settingsProvider.future);
      final formatter = ref.read(unitFormatterProvider);

      if (profile == null || profile.ammo.target == null) {
        return const ShotDetailsError('No cartridge selected');
      }

      final opts = TargetCalcOptions(
        targetDistM: conditions.distanceMeter,
        stepM: settings.homeChartDistanceStep,
      );

      final result = await ref
          .read(ballisticsServiceProvider)
          .calculateForTarget(profile, conditions, opts);

      final hit = result.hitResult;

      return _buildReadyState(profile, conditions, formatter, hit);
    } catch (e) {
      return ShotDetailsError(e.toString());
    }
  }

  ShotDetailsReady _buildReadyState(
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
    String sgStr = '—';
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

    return ShotDetailsReady(
      currentMv: formatter.velocity(curVelocity),
      zeroMv: formatter.velocity(zeroVelocity),
      speedOfSound: soundSpeedFps == null
          ? '—'
          : formatter.velocity(Velocity.fps(soundSpeedFps)),
      velocityAtTarget: formatter.velocity(atTarget.velocity),
      energyAtMuzzle: firstPoint == null
          ? '—'
          : formatter.energy(firstPoint.energy),
      energyAtTarget: formatter.energy(atTarget.energy),
      gyroscopicStability: sgStr,
      shotDistance: formatter.distance(conditions.distance),
      heightAtTarget: formatter.drop(atTarget.height),
      maxHeightDistance: apexPoint == null
          ? '—'
          : formatter.distance(apexPoint.distance),
      windage: formatter.drop(atTarget.windage),
      timeToTarget: formatter.time(atTarget.time),
    );
  }
}

final shotDetailsVmProvider =
    AsyncNotifierProvider<ShotDetailsViewModel, ShotDetailsUiState>(
      ShotDetailsViewModel.new,
    );
