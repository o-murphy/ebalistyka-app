import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';

import 'package:uuid/uuid.dart';

import '_storage.dart';

class WeaponData {
  final String id;
  final String name;
  final String? vendor;
  final Distance sightHeight;
  final Distance twist;
  final Angular zeroElevation;
  // Caliber diameter (inches) — used for filtering cartridges by caliber.
  // Optional: user-created rifles may not have this set.
  final Distance? caliber;
  // Barrel length — optional, must be > 0 if set.
  final Distance? barrelLength;
  final String? notes;

  WeaponData({
    String? id,
    required this.name,
    this.vendor,
    required this.sightHeight,
    required this.twist,
    Angular? zeroElevation,
    this.caliber,
    this.barrelLength,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       zeroElevation = zeroElevation ?? Angular.radian(0);

  /// Right-hand twist when positive, left-hand when negative.
  bool get isRightHandTwist => twist.raw >= 0;

  bclibc.Weapon toWeapon() => bclibc.Weapon(
    sightHeight: sightHeight,
    twist: twist,
    zeroElevation: zeroElevation,
  );

  WeaponData copyWith({
    String? name,
    String? vendor,
    Distance? sightHeight,
    Distance? twist,
    Angular? zeroElevation,
    Distance? caliber,
    Distance? barrelLength,
    String? notes,
  }) => WeaponData(
    id: id,
    name: name ?? this.name,
    vendor: vendor ?? this.vendor,
    sightHeight: sightHeight ?? this.sightHeight,
    twist: twist ?? this.twist,
    zeroElevation: zeroElevation ?? this.zeroElevation,
    caliber: caliber ?? this.caliber,
    barrelLength: barrelLength ?? this.barrelLength,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (vendor != null) 'vendor': vendor,
    'weapon': {
      'sightHeight': sightHeight.in_(StorageUnits.weaponSightHeight),
      'twist': twist.in_(StorageUnits.weaponTwist),
      'zeroElevation': zeroElevation.in_(StorageUnits.weaponZeroElevation),
      if (caliber != null)
        'caliberDiameter': caliber!.in_(StorageUnits.projectileDiameter),
      if (barrelLength != null)
        'barrelLength': barrelLength!.in_(StorageUnits.weaponBarrelLength),
    },
    if (notes != null) 'notes': notes,
  };

  factory WeaponData.fromJson(Map<String, dynamic> json) {
    final w = json['weapon'] as Map;
    final caliberRaw = w['caliberDiameter'] as num?;
    return WeaponData(
      id: json['id'] as String,
      name: json['name'] as String,
      vendor: json['vendor'] as String?,
      sightHeight: Distance(
        (w['sightHeight'] as num).toDouble(),
        StorageUnits.weaponSightHeight,
      ),
      twist: Distance((w['twist'] as num).toDouble(), StorageUnits.weaponTwist),
      zeroElevation: Angular(
        (w['zeroElevation'] as num).toDouble(),
        StorageUnits.weaponZeroElevation,
      ),
      caliber: caliberRaw != null
          ? Distance(caliberRaw.toDouble(), StorageUnits.projectileDiameter)
          : null,
      barrelLength: (w['barrelLength'] as num?) != null
          ? Distance(
              (w['barrelLength'] as num).toDouble(),
              StorageUnits.weaponBarrelLength,
            )
          : null,
      notes: json['notes'] as String?,
    );
  }
}
