import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;

extension WeaponExtension on Weapon {
  Distance get twist => Distance.inch(twistInch);
  set twist(Distance value) => twistInch = value.in_(Unit.inch);

  bool get isRightHandTwist => twistInch >= 0.0;

  Distance get caliber => Distance.inch(caliberInch);
  set caliber(Distance value) => caliberInch = value.in_(Unit.inch);

  Angular get zeroElevation => Angular.radian(zeroElevationRad);
  set zeroElevation(Angular value) => zeroElevationRad = value.in_(Unit.radian);

  Distance? get barrelLength {
    final v = barrelLengthInch;
    return v == null ? null : Distance.inch(v);
  }

  set barrelLength(Distance? value) => barrelLengthInch = value?.in_(Unit.inch);

  bclibc.Weapon toWeapon(Distance sightHeight) => bclibc.Weapon(
    sightHeight: sightHeight,
    twist: twist,
    zeroElevation: zeroElevation,
  );
}
