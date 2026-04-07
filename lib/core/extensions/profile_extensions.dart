import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

extension ProfileExtension on Profile {
  bool get isReadyForCalculation {
    final ammo = this.ammo.target;
    return ammo != null && ammo.isReadyForCalculation;
  }

  bclibc.Shot toZeroShot(bclibc.Weapon weapon, Angular lookAngle) {
    final ammo = this.ammo.target!;

    return bclibc.Shot(
      weapon: weapon,
      ammo: ammo.toZeroAmmo(),
      lookAngle: lookAngle,
      atmo: ammo.toZeroAtmo(),
      winds: const [],
      latitudeDeg: ammo.zeroUseCoriolis ? ammo.zerolatitudeDeg : null,
      azimuthDeg: ammo.zeroUseCoriolis ? ammo.zeroAzimuthDeg : null,
    );
  }

  bclibc.Shot toCurrentShot(ShootingConditions cond, bclibc.Weapon weapon) {
    final ammo = this.ammo.target!;

    return bclibc.Shot(
      weapon: weapon,
      ammo: ammo.toCurrentAmmo(cond),
      lookAngle: cond.lookAngle,
      atmo: cond.toCurrentAtmo(),
      winds: [cond.toWind()],
      latitudeDeg: cond.useCoriolis ? cond.latitudeDeg : null,
      azimuthDeg: cond.useCoriolis ? cond.azimuthDeg : null,
    );
  }
}
