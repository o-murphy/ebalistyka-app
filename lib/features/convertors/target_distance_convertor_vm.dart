import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:riverpod/riverpod.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class TargetAtDistanceConvertorUiState {
  /// Physical size of the target in [sizeUnit] (for input display).
  final double? rawSizeValue;
  final Unit sizeUnit;

  /// Observed angular size in [angularUnit] (for input display).
  final double? rawAngularValue;
  final Unit angularUnit;

  /// Angular size in MIL — passed directly to ReticleView as targetSizeMil.
  final double targetSizeMil;

  /// Reticle image from active profile's sight; null → default.
  final String? reticleImageId;

  /// Target image from ReticleSettings; null → default.
  final String? targetImageId;

  /// Computed distance outputs (read-only).
  final GenericConvertorField meters;
  final GenericConvertorField yards;
  final GenericConvertorField feet;

  const TargetAtDistanceConvertorUiState({
    required this.rawSizeValue,
    required this.sizeUnit,
    required this.rawAngularValue,
    required this.angularUnit,
    required this.targetSizeMil,
    required this.reticleImageId,
    required this.targetImageId,
    required this.meters,
    required this.yards,
    required this.feet,
  });
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class TargetAtDistanceConvertorViewModel
    extends Notifier<TargetAtDistanceConvertorUiState> {
  @override
  TargetAtDistanceConvertorUiState build() {
    final s = ref.watch(convertorStateProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final reticleImage = ref
        .watch(shotContextProvider)
        .value
        ?.profile
        .sight
        .target
        ?.reticleImage;
    final targetImage = ref.watch(reticleSettingsProvider).targetImage;
    return _buildState(
      sizeInch: s.distanceConvTargetSizeInch,
      sizeUnit: s.distanceConvTargetSizeUnitValue,
      angularMil: s.distanceConvTargetSizeAngularMil,
      angularUnit: s.distanceConvTargetSizeAngularUnitValue,
      reticleImageId: reticleImage,
      targetImageId: targetImage,
      l10n: l10n,
    );
  }

  void updateSizeValue(double? rawInInputUnit) {
    final s = ref.read(convertorStateProvider);
    if (rawInInputUnit == null) return;
    final inchValue = rawInInputUnit.convert(
      s.distanceConvTargetSizeUnitValue,
      Unit.inch,
    );
    if (inchValue >= 0) {
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateDistanceConvTargetSize(inchValue),
      );
    }
  }

  void changeSizeUnit(Unit newUnit) {
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateDistanceConvTargetSizeUnit(newUnit),
    );
  }

  void updateAngularValue(double? rawInInputUnit) {
    final s = ref.read(convertorStateProvider);
    if (rawInInputUnit == null) return;
    final milValue = rawInInputUnit.convert(
      s.distanceConvTargetSizeAngularUnitValue,
      Unit.mil,
    );
    if (milValue > 0) {
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateDistanceConvTargetSizeAngular(milValue),
      );
    }
  }

  void changeAngularUnit(Unit newUnit) {
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateDistanceConvTargetSizeAngularUnit(newUnit),
    );
  }

  FieldConstraints getSizeConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.convertorTargetPhysicalSize.minRaw.convert(Unit.inch, unit),
      maxRaw: FC.convertorTargetPhysicalSize.maxRaw.convert(Unit.inch, unit),
      stepRaw: FC.convertorTargetPhysicalSize.stepRaw.convert(Unit.inch, unit),
      rawUnit: unit,
      accuracy: FC.convertorTargetPhysicalSize.accuracyFor(unit),
    );
  }

  FieldConstraints getAngularConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.targetSize.minRaw.convert(Unit.mil, unit),
      maxRaw: FC.targetSize.maxRaw.convert(Unit.mil, unit),
      stepRaw: FC.targetSize.stepRaw.convert(Unit.mil, unit),
      rawUnit: unit,
      accuracy: FC.targetSize.accuracyFor(unit),
    );
  }

  String _fmt(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite || value <= 0) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  TargetAtDistanceConvertorUiState _buildState({
    required double sizeInch,
    required Unit sizeUnit,
    required double angularMil,
    required Unit angularUnit,
    required String? reticleImageId,
    required String? targetImageId,
    required AppLocalizations l10n,
  }) {
    // Mil-relation: 1 mil = 1 mm at 1 m → distance_m = size_mm / angular_mil
    final sizeMm = sizeInch.convert(Unit.inch, Unit.millimeter);
    final distanceM = angularMil > 0 ? sizeMm / angularMil : double.infinity;
    final distanceYd = distanceM.convert(Unit.meter, Unit.yard);
    final distanceFt = distanceM.convert(Unit.meter, Unit.foot);

    final mAcc = FC.targetDistance.accuracyFor(Unit.meter);
    final ydAcc = FC.targetDistance.accuracyFor(Unit.yard);
    final ftAcc = FC.targetDistance.accuracyFor(Unit.foot);

    return TargetAtDistanceConvertorUiState(
      rawSizeValue: sizeInch.convert(Unit.inch, sizeUnit),
      sizeUnit: sizeUnit,
      rawAngularValue: angularMil.convert(Unit.mil, angularUnit),
      angularUnit: angularUnit,
      targetSizeMil: angularMil,
      reticleImageId: reticleImageId,
      targetImageId: targetImageId,
      meters: GenericConvertorField(
        labelBuilder: (l10n) => l10n.unitMeters,
        formattedValue: _fmt(distanceM, mAcc, Unit.meter.localizedSymbol(l10n)),
        value: distanceM,
        symbol: Unit.meter.localizedSymbol(l10n),
        decimals: mAcc,
      ),
      yards: GenericConvertorField(
        labelBuilder: (l10n) => l10n.unitYards,
        formattedValue: _fmt(
          distanceYd,
          ydAcc,
          Unit.yard.localizedSymbol(l10n),
        ),
        value: distanceYd,
        symbol: Unit.yard.localizedSymbol(l10n),
        decimals: ydAcc,
      ),
      feet: GenericConvertorField(
        labelBuilder: (l10n) => l10n.unitFeet,
        formattedValue: _fmt(
          distanceFt,
          ftAcc,
          Unit.foot.localizedSymbol(l10n),
        ),
        value: distanceFt,
        symbol: Unit.foot.localizedSymbol(l10n),
        decimals: ftAcc,
      ),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final targetAtDistanceConvertorVmProvider =
    NotifierProvider<
      TargetAtDistanceConvertorViewModel,
      TargetAtDistanceConvertorUiState
    >(TargetAtDistanceConvertorViewModel.new);
