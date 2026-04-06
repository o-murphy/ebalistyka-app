import 'package:ebalistyka/core/solver/munition.dart';
import 'package:ebalistyka/core/solver/unit.dart';
import 'package:uuid/uuid.dart';

import '_storage.dart';

class Rifle {
  final String id;
  final String name;
  final String? description;
  final Distance sightHeight;
  final Distance twist;
  final Angular zeroElevation;
  // Caliber diameter (inches) — used for filtering cartridges by caliber.
  // Optional: user-created rifles may not have this set.
  final Distance? caliberDiameter;
  // Barrel length — optional, must be > 0 if set.
  final Distance? barrelLength;
  final String? notes;

  Rifle({
    String? id,
    required this.name,
    this.description,
    required this.sightHeight,
    required this.twist,
    Angular? zeroElevation,
    this.caliberDiameter,
    this.barrelLength,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       zeroElevation = zeroElevation ?? Angular(0, Unit.radian);

  /// Right-hand twist when positive, left-hand when negative.
  bool get isRightHandTwist => twist.raw >= 0;

  Weapon toWeapon() => Weapon(
    sightHeight: sightHeight,
    twist: twist,
    zeroElevation: zeroElevation,
  );

  Rifle copyWith({
    String? name,
    String? description,
    Distance? sightHeight,
    Distance? twist,
    Angular? zeroElevation,
    Distance? caliberDiameter,
    Distance? barrelLength,
    String? notes,
  }) => Rifle(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    sightHeight: sightHeight ?? this.sightHeight,
    twist: twist ?? this.twist,
    zeroElevation: zeroElevation ?? this.zeroElevation,
    caliberDiameter: caliberDiameter ?? this.caliberDiameter,
    barrelLength: barrelLength ?? this.barrelLength,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'weapon': {
      'sightHeight': sightHeight.in_(StorageUnits.weaponSightHeight),
      'twist': twist.in_(StorageUnits.weaponTwist),
      'zeroElevation': zeroElevation.in_(StorageUnits.weaponZeroElevation),
      if (caliberDiameter != null)
        'caliberDiameter': caliberDiameter!.in_(
          StorageUnits.projectileDiameter,
        ),
      if (barrelLength != null)
        'barrelLength': barrelLength!.in_(StorageUnits.weaponBarrelLength),
    },
    if (notes != null) 'notes': notes,
  };

  factory Rifle.fromJson(Map<String, dynamic> json) {
    final w = json['weapon'] as Map;
    final caliberRaw = w['caliberDiameter'] as num?;
    return Rifle(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sightHeight: Distance(
        (w['sightHeight'] as num).toDouble(),
        StorageUnits.weaponSightHeight,
      ),
      twist: Distance((w['twist'] as num).toDouble(), StorageUnits.weaponTwist),
      zeroElevation: Angular(
        (w['zeroElevation'] as num).toDouble(),
        StorageUnits.weaponZeroElevation,
      ),
      caliberDiameter: caliberRaw != null
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
