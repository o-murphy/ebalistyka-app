import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class WeaponWizardState {
  const WeaponWizardState({
    this.name = '',
    this.vendor = '',
    this.caliberName = '',
    required this.caliberRaw,
    required this.twistRaw,
    this.rightHand = true,
    this.showExtraFields = false,
    this.barrelLengthRaw,
    this.initial,
  });

  final String name;
  final String vendor;
  final String caliberName;
  final double caliberRaw; // FC.projectileDiameter.rawUnit = mm
  final double
  twistRaw; // FC.twist.rawUnit = inch, always ≥ 0; direction via rightHand
  final bool rightHand;
  final bool showExtraFields;
  final double?
  barrelLengthRaw; // FC.barrelLength.rawUnit = inch; null = not set
  final Weapon?
  initial; // non-null in edit mode; buildWeapon() mutates and returns it

  bool get isValid => name.trim().isNotEmpty && caliberRaw > 0 && twistRaw >= 0;

  static WeaponWizardState fromWeapon(Weapon? w) {
    if (w == null) {
      return WeaponWizardState(
        caliberRaw: Distance.inch(0.338).in_(FC.projectileDiameter.rawUnit),
        twistRaw: FC.twist.minRaw,
      );
    }
    final caliberRaw = w.caliberInch > 0
        ? w.caliber.in_(FC.projectileDiameter.rawUnit)
        : Distance.inch(0.338).in_(FC.projectileDiameter.rawUnit);
    final twistAbs = w.twist.in_(FC.twist.rawUnit).abs();
    final barrelLengthRaw = w.barrelLength?.in_(FC.barrelLength.rawUnit);
    return WeaponWizardState(
      name: w.name,
      vendor: w.vendor ?? '',
      caliberName: w.caliberName,
      caliberRaw: caliberRaw,
      twistRaw: twistAbs > 0 ? twistAbs : FC.twist.minRaw,
      rightHand: w.isRightHandTwist,
      showExtraFields: barrelLengthRaw != null,
      barrelLengthRaw: barrelLengthRaw,
      initial: w,
    );
  }

  Weapon buildWeapon() {
    final weapon = initial ?? Weapon();
    weapon.name = name.trim();
    weapon.vendor = vendor.trim().isEmpty ? null : vendor.trim();
    weapon.caliberName = caliberName.trim();
    weapon.caliber = Distance(caliberRaw, FC.projectileDiameter.rawUnit);
    weapon.twist = Distance(rightHand ? twistRaw : -twistRaw, FC.twist.rawUnit);
    weapon.barrelLength = (showExtraFields && barrelLengthRaw != null)
        ? Distance(barrelLengthRaw!, FC.barrelLength.rawUnit)
        : null;
    return weapon;
  }

  WeaponWizardState copyWith({
    String? name,
    String? vendor,
    String? caliberName,
    double? caliberRaw,
    double? twistRaw,
    bool? rightHand,
    bool? showExtraFields,
    Object? barrelLengthRaw = _absent,
  }) => WeaponWizardState(
    name: name ?? this.name,
    vendor: vendor ?? this.vendor,
    caliberName: caliberName ?? this.caliberName,
    caliberRaw: caliberRaw ?? this.caliberRaw,
    twistRaw: twistRaw ?? this.twistRaw,
    rightHand: rightHand ?? this.rightHand,
    showExtraFields: showExtraFields ?? this.showExtraFields,
    barrelLengthRaw: barrelLengthRaw == _absent
        ? this.barrelLengthRaw
        : barrelLengthRaw as double?,
    initial: initial,
  );

  static const _absent = Object();
}

typedef WeaponWizardArg = ({Weapon? initial});

final weaponWizardProvider =
    NotifierProvider.family<
      WeaponWizardNotifier,
      WeaponWizardState,
      WeaponWizardArg
    >((arg) => WeaponWizardNotifier(arg));

class WeaponWizardNotifier extends Notifier<WeaponWizardState> {
  WeaponWizardNotifier(this._arg);
  final WeaponWizardArg _arg;

  @override
  WeaponWizardState build() => WeaponWizardState.fromWeapon(_arg.initial);

  void updateName(String v) => state = state.copyWith(name: v);
  void updateVendor(String v) => state = state.copyWith(vendor: v);
  void updateCaliberName(String v) => state = state.copyWith(caliberName: v);
  void updateCaliberRaw(double v) => state = state.copyWith(caliberRaw: v);
  void updateTwistRaw(double v) => state = state.copyWith(twistRaw: v);
  void updateRightHand(bool v) => state = state.copyWith(rightHand: v);
  void updateShowExtraFields(bool v) =>
      state = state.copyWith(showExtraFields: v);
  void updateBarrelLengthRaw(double? v) =>
      state = state.copyWith(barrelLengthRaw: v);
}
