import 'package:uuid/uuid.dart';

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';

import 'ammo_data.dart';
import 'conditions_data.dart';
import 'weapon_data.dart';
import 'sight_data.dart';

class ProfileData {
  final String id;
  final String name;

  // ── Embedded у JSON профілю ───────────────────────────────────────────────
  final WeaponData rifle;

  // ── References до бібліотек (тільки id у JSON) ────────────────────────────
  final String? cartridgeId;
  final String? sightId;

  // ── Resolved об'єкти (НЕ зберігаються в JSON) ────────────────────────────
  // Заповнюються тільки для активного профілю через shotProfileProvider.
  final AmmoData? cartridge;
  final SightData? sight;

  ProfileData({
    String? id,
    required this.name,
    required this.rifle,
    this.cartridgeId,
    this.sightId,
    this.cartridge,
    this.sight,
  }) : id = id ?? const Uuid().v4();

  // ── isReadyForCalculation ─────────────────────────────────────────────────

  bool get isReadyForCalculation =>
      cartridge != null &&
      cartridge!.mv.in_(Unit.mps) > 0 &&
      cartridge!.coefRows.isNotEmpty &&
      cartridge!.diameter.in_(Unit.inch) > 0 &&
      cartridge!.weight.in_(Unit.grain) > 0;

  // ── toShot ────────────────────────────────────────────────────────────────

  bclibc.Shot toZeroShot(Angular lookAngle, bclibc.Weapon weapon) {
    final zeroAmmo = bclibc.Ammo(
      dm: cartridge!.toDragModel(),
      mv: cartridge!.mv,
      powderTemp: cartridge!.powderTemp,
      tempModifier: cartridge!.powderSensitivity.in_(Unit.fraction),
      usePowderSensitivity: cartridge!.zeroConditions.usePowderSensitivity,
    );

    final zeroAtmo = cartridge!.zeroConditions.atmo;

    return bclibc.Shot(
      weapon: weapon,
      ammo: zeroAmmo,
      lookAngle: lookAngle,
      atmo: zeroAtmo.toAtmo(),
      winds: const [],
    );
  }

  bclibc.Shot toCurrentShot(Conditions conditions, bclibc.Weapon weapon) {
    final currentAmmo = bclibc.Ammo(
      dm: cartridge!.toDragModel(),
      mv: cartridge!.mv,
      powderTemp: cartridge!.powderTemp,
      tempModifier: cartridge!.powderSensitivity.in_(Unit.fraction),
      usePowderSensitivity: conditions.usePowderSensitivity,
    );

    return bclibc.Shot(
      weapon: weapon,
      ammo: currentAmmo,
      lookAngle: conditions.lookAngle,
      atmo: conditions.toAtmo(),
      winds: [conditions.wind.toWind()],
      latitudeDeg: conditions.latitudeDeg,
      azimuthDeg: conditions.azimuthDeg,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  ProfileData copyWith({
    String? name,
    WeaponData? rifle,
    AmmoData? cartridge,
    bool clearCartridge = false,
    SightData? sight,
    bool clearSight = false,
  }) => ProfileData(
    id: id,
    name: name ?? this.name,
    rifle: rifle ?? this.rifle,
    cartridgeId: clearCartridge ? null : (cartridge?.id ?? cartridgeId),
    cartridge: clearCartridge ? null : (cartridge ?? this.cartridge),
    sightId: clearSight ? null : (sight?.id ?? sightId),
    sight: clearSight ? null : (sight ?? this.sight),
  );

  // ── JSON ──────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rifle': rifle.toJson(),
    if (cartridgeId != null) 'cartridgeId': cartridgeId,
    if (sightId != null) 'sightId': sightId,
  };

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    // ── Sight: new format (sightId) або backward-compat (embedded sight) ────
    final sightIdNew = json['sightId'] as String?;
    SightData? inlineSight;
    String? resolvedSightId = sightIdNew;

    if (sightIdNew == null) {
      final sightJson = json['sight'] as Map<String, dynamic>?;
      if (sightJson != null) {
        inlineSight = SightData.fromJson(sightJson);
        resolvedSightId = inlineSight.id;
      }
    }

    // ── Cartridge: new format (cartridgeId) або backward-compat ─────────────
    final cartridgeIdNew = json['cartridgeId'] as String?;
    AmmoData? inlineCartridge;
    String? resolvedCartridgeId = cartridgeIdNew;

    if (cartridgeIdNew == null) {
      final cartridgeJson = json['cartridge'] as Map<String, dynamic>?;
      if (cartridgeJson != null) {
        inlineCartridge = AmmoData.fromJson(cartridgeJson);
        resolvedCartridgeId = inlineCartridge.id;
      }
    }

    return ProfileData(
      id: json['id'] as String,
      name: json['name'] as String,
      rifle: WeaponData.fromJson(json['rifle'] as Map<String, dynamic>),
      cartridgeId: resolvedCartridgeId,
      cartridge: inlineCartridge,
      sightId: resolvedSightId,
      sight: inlineSight,
    );
  }
}
