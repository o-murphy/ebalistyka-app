import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SightWizardState {
  const SightWizardState({
    this.name = '',
    this.vendor = '',
    this.sightHeightRaw = 0.0,
    this.horizontalOffsetRaw = 0.0,
    this.focalPlane = FocalPlane.ffp,
    required this.vClickRaw,
    this.vClickUnit = Unit.mil,
    required this.hClickRaw,
    this.hClickUnit = Unit.mil,
    required this.minMagRaw,
    required this.maxMagRaw,
    this.reticleImage,
    this.initial,
  });

  final String name;
  final String vendor;
  final double sightHeightRaw; // FC.sightHeight.rawUnit = mm
  final double horizontalOffsetRaw; // FC.sightHeight.rawUnit = mm
  final FocalPlane focalPlane;
  final double vClickRaw; // FC.adjustment.rawUnit = mil
  final Unit vClickUnit;
  final double hClickRaw; // FC.adjustment.rawUnit = mil
  final Unit hClickUnit;
  final double minMagRaw; // FC.magnification.rawUnit = scalar
  final double maxMagRaw; // FC.magnification.rawUnit = scalar
  final String? reticleImage;
  final Sight?
  initial; // non-null in edit mode; buildSight() mutates and returns it

  bool get isValid =>
      name.trim().isNotEmpty &&
      minMagRaw > 0 &&
      maxMagRaw > 0 &&
      vClickRaw > 0 &&
      hClickRaw > 0;

  static SightWizardState fromSight(Sight? s) {
    if (s == null) {
      final defaultClick = Angular.mil(0.1).in_(FC.adjustment.rawUnit);
      return SightWizardState(
        vClickRaw: defaultClick,
        hClickRaw: defaultClick,
        minMagRaw: 1.0,
        maxMagRaw: 1.0,
      );
    }
    final vClickUnit = s.verticalClickUnitValue;
    final hClickUnit = s.horizontalClickUnitValue;
    return SightWizardState(
      name: s.name,
      vendor: s.vendor ?? '',
      sightHeightRaw: s.sightHeight.in_(FC.sightHeight.rawUnit),
      horizontalOffsetRaw: s.horizontalOffset.in_(FC.sightHeight.rawUnit),
      focalPlane: s.focalPlane,
      vClickRaw: Angular(
        s.verticalClick,
        vClickUnit,
      ).in_(FC.adjustment.rawUnit),
      vClickUnit: vClickUnit,
      hClickRaw: Angular(
        s.horizontalClick,
        hClickUnit,
      ).in_(FC.adjustment.rawUnit),
      hClickUnit: hClickUnit,
      minMagRaw: s.minMagnification > 0 ? s.minMagnification : 1.0,
      maxMagRaw: s.maxMagnification > 0 ? s.maxMagnification : 1.0,
      reticleImage: s.reticleImage,
      initial: s,
    );
  }

  Sight buildSight() {
    final sight = initial ?? Sight();
    sight.name = name.trim();
    sight.vendor = vendor.trim().isEmpty ? null : vendor.trim();
    sight.sightHeight = Distance(sightHeightRaw, FC.sightHeight.rawUnit);
    sight.horizontalOffset = Distance(
      horizontalOffsetRaw,
      FC.sightHeight.rawUnit,
    );
    sight.focalPlane = focalPlane;
    sight.verticalClickUnitValue = vClickUnit;
    sight.verticalClick = Angular(
      vClickRaw,
      FC.adjustment.rawUnit,
    ).in_(vClickUnit);
    sight.horizontalClickUnitValue = hClickUnit;
    sight.horizontalClick = Angular(
      hClickRaw,
      FC.adjustment.rawUnit,
    ).in_(hClickUnit);
    sight.minMagnification = minMagRaw;
    sight.maxMagnification = maxMagRaw;
    sight.reticleImage = reticleImage;
    return sight;
  }

  SightWizardState copyWith({
    String? name,
    String? vendor,
    double? sightHeightRaw,
    double? horizontalOffsetRaw,
    FocalPlane? focalPlane,
    double? vClickRaw,
    Unit? vClickUnit,
    double? hClickRaw,
    Unit? hClickUnit,
    double? minMagRaw,
    double? maxMagRaw,
    Object? reticleImage = _absent,
  }) => SightWizardState(
    name: name ?? this.name,
    vendor: vendor ?? this.vendor,
    sightHeightRaw: sightHeightRaw ?? this.sightHeightRaw,
    horizontalOffsetRaw: horizontalOffsetRaw ?? this.horizontalOffsetRaw,
    focalPlane: focalPlane ?? this.focalPlane,
    vClickRaw: vClickRaw ?? this.vClickRaw,
    vClickUnit: vClickUnit ?? this.vClickUnit,
    hClickRaw: hClickRaw ?? this.hClickRaw,
    hClickUnit: hClickUnit ?? this.hClickUnit,
    minMagRaw: minMagRaw ?? this.minMagRaw,
    maxMagRaw: maxMagRaw ?? this.maxMagRaw,
    reticleImage: reticleImage == _absent
        ? this.reticleImage
        : reticleImage as String?,
    initial: initial,
  );

  static const _absent = Object();
}

typedef SightWizardArg = ({Sight? initial});

final sightWizardProvider =
    NotifierProvider.family<
      SightWizardNotifier,
      SightWizardState,
      SightWizardArg
    >((arg) => SightWizardNotifier(arg));

class SightWizardNotifier extends Notifier<SightWizardState> {
  SightWizardNotifier(this._arg);
  final SightWizardArg _arg;

  @override
  SightWizardState build() => SightWizardState.fromSight(_arg.initial);

  void updateName(String v) => state = state.copyWith(name: v);
  void updateVendor(String v) => state = state.copyWith(vendor: v);
  void updateSightHeightRaw(double v) =>
      state = state.copyWith(sightHeightRaw: v);
  void updateHorizontalOffsetRaw(double v) =>
      state = state.copyWith(horizontalOffsetRaw: v);
  void updateFocalPlane(FocalPlane v) => state = state.copyWith(focalPlane: v);
  void updateVClickRaw(double v) => state = state.copyWith(vClickRaw: v);
  void updateVClickUnit(Unit v) => state = state.copyWith(vClickUnit: v);
  void updateHClickRaw(double v) => state = state.copyWith(hClickRaw: v);
  void updateHClickUnit(Unit v) => state = state.copyWith(hClickUnit: v);
  void updateMinMagRaw(double v) => state = state.copyWith(minMagRaw: v);
  void updateMaxMagRaw(double v) => state = state.copyWith(maxMagRaw: v);
  void updateReticleImage(String? v) => state = state.copyWith(reticleImage: v);
}
