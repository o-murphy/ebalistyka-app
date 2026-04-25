import 'dart:async';

import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:bclibc_ffi/unit.dart';

class AnglesConvertorField {
  final String label;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const AnglesConvertorField({
    required this.label,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}

class AnglesConvertorUiState {
  // All possible angle units
  final AnglesConvertorField mil;
  final AnglesConvertorField moa;
  final AnglesConvertorField cmPer100m;
  final AnglesConvertorField inchPer100Yd;
  final AnglesConvertorField mrad;
  final AnglesConvertorField degrees;

  // Distance
  final AnglesConvertorField meters;
  final AnglesConvertorField yards;

  // Distance calculations in the selected unit
  final String oneMilAtDistance;
  final String angleInMoaAtDistance;
  final String oneMoaAtDistance;
  final String angleInMilAtDistance;

  final double? rawDistanceValue;
  final double? rawAngularValue;
  final Unit distanceInputUnit;
  final Unit angularInputUnit;
  final Unit distanceOutputUnit;

  const AnglesConvertorUiState({
    required this.mil,
    required this.moa,
    required this.cmPer100m,
    required this.inchPer100Yd,
    required this.mrad,
    required this.degrees,
    required this.meters,
    required this.yards,
    required this.oneMilAtDistance,
    required this.angleInMoaAtDistance,
    required this.oneMoaAtDistance,
    required this.angleInMilAtDistance,
    required this.rawDistanceValue,
    required this.rawAngularValue,
    required this.distanceInputUnit,
    required this.angularInputUnit,
    required this.distanceOutputUnit,
  });
}

class AnglesConvertorViewModel extends Notifier<AnglesConvertorUiState> {
  @override
  AnglesConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.anglesConvDistanceValueMeter,
      convertorsState.anglesConvDistanceUnit,
      convertorsState.anglesConvAngularValueMil,
      convertorsState.anglesConvAngularUnit,
      convertorsState.anglesConvOutputUnit,
    );
  }

  void updateDistanceValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);
    if (rawValueInInputUnit == null) {
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateAnglesConvDistanceValue(null),
      );
      return;
    }
    final metersValue = rawValueInInputUnit.convert(
      convertorsState.anglesConvDistanceUnit,
      Unit.meter,
    );
    if (metersValue >= 0) {
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateAnglesConvDistanceValue(metersValue),
      );
    }
  }

  void updateAngularValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);
    if (rawValueInInputUnit == null) {
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateAnglesConvAngularValue(null),
      );
      return;
    }
    final milValue = rawValueInInputUnit.convert(
      convertorsState.anglesConvAngularUnit,
      Unit.mil,
    );
    if (milValue >= 0) {
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateAnglesConvAngularValue(milValue),
      );
    }
  }

  void changeDistanceUnit(Unit newUnit) {
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateAnglesConvDistanceUnit(newUnit),
    );
  }

  void changeAngularUnit(Unit newUnit) {
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateAnglesConvAngularUnit(newUnit),
    );
  }

  void changeOutputUnit(Unit newUnit) {
    unawaited(
      ref.read(convertorsProvider.notifier).updateAnglesConvOutputUnit(newUnit),
    );
  }

  FieldConstraints getDistanceConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.convertorDistance.minRaw.convert(
        FC.convertorDistance.rawUnit,
        unit,
      ),
      maxRaw: FC.convertorDistance.maxRaw.convert(
        FC.convertorDistance.rawUnit,
        unit,
      ),
      stepRaw: FC.convertorDistance.stepRaw.convert(
        FC.convertorDistance.rawUnit,
        unit,
      ),
      rawUnit: unit,
      accuracy: FC.convertorDistance.accuracyFor(unit),
    );
  }

  FieldConstraints getAngularConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.convertorAngular.minRaw.convert(
        FC.convertorAngular.rawUnit,
        unit,
      ),
      maxRaw: FC.convertorAngular.maxRaw.convert(
        FC.convertorAngular.rawUnit,
        unit,
      ),
      stepRaw: FC.convertorAngular.stepRaw.convert(
        FC.convertorAngular.rawUnit,
        unit,
      ),
      rawUnit: unit,
      accuracy: FC.convertorAngular.accuracyFor(unit),
    );
  }

  FieldConstraints getOutputConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: 0.0,
      maxRaw: 100000.0,
      stepRaw: 1.0,
      rawUnit: unit,
      accuracy: 1,
    );
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  AnglesConvertorUiState _buildState(
    double rawMeters,
    Unit distanceUnit,
    double rawMil,
    Unit angularUnit,
    Unit outputUnit,
  ) {
    // Distance
    final metersRaw = rawMeters;
    final yardsRaw = metersRaw.convert(Unit.meter, Unit.yard);

    // Convert angle to different units
    final milRaw = rawMil;
    final moaRaw = milRaw.convert(Unit.mil, Unit.moa);
    final mradRaw = milRaw.convert(Unit.mil, Unit.mRad);
    final degreesRaw = milRaw.convert(Unit.mil, Unit.degree);

    // cm/100m and inch/100yd for angle
    final cmPer100mRaw = milRaw * 10;
    final inchPer100YdRaw = milRaw * 3.6;

    // Distance calculations in the selected output unit
    final distanceInMeters = rawMeters;

    // 1 MIL on distance
    final oneMilValue = (0.1 * distanceInMeters).convert(
      Unit.meter,
      outputUnit,
    );

    // Angle in MOA at distance
    final angleMoaValue = (moaRaw * 0.0291 * distanceInMeters).convert(
      Unit.meter,
      outputUnit,
    );

    // 1 MOA at range
    final oneMoaValue = (0.0291 * distanceInMeters).convert(
      Unit.meter,
      outputUnit,
    );

    // Angle in MIL at distance
    final angleMilValue = (rawMil * 0.1 * distanceInMeters).convert(
      Unit.meter,
      outputUnit,
    );

    return AnglesConvertorUiState(
      rawDistanceValue: rawMeters.convert(Unit.meter, distanceUnit),
      rawAngularValue: rawMil.convert(Unit.mil, angularUnit),
      distanceInputUnit: distanceUnit,
      angularInputUnit: angularUnit,
      distanceOutputUnit: outputUnit,

      // Distance
      meters: AnglesConvertorField(
        label: 'Meters',
        formattedValue: _formatValue(metersRaw, 0, Unit.meter.symbol),
        value: metersRaw,
        symbol: Unit.meter.symbol,
        decimals: 0,
      ),
      yards: AnglesConvertorField(
        label: 'Yards',
        formattedValue: _formatValue(yardsRaw, 0, Unit.yard.symbol),
        value: yardsRaw,
        symbol: Unit.yard.symbol,
        decimals: 0,
      ),

      // Angle conversion
      mil: AnglesConvertorField(
        label: 'MIL',
        formattedValue: _formatValue(milRaw, 1, Unit.mil.symbol),
        value: milRaw,
        symbol: Unit.mil.symbol,
        decimals: 1,
      ),
      moa: AnglesConvertorField(
        label: 'MOA',
        formattedValue: _formatValue(moaRaw, 1, Unit.moa.symbol),
        value: moaRaw,
        symbol: Unit.moa.symbol,
        decimals: 1,
      ),
      cmPer100m: AnglesConvertorField(
        label: 'cm/100m',
        formattedValue: _formatValue(cmPer100mRaw, 1, 'cm/100m'),
        value: cmPer100mRaw,
        symbol: 'cm/100m',
        decimals: 1,
      ),
      inchPer100Yd: AnglesConvertorField(
        label: 'in/100yd',
        formattedValue: _formatValue(inchPer100YdRaw, 2, 'in/100yd'),
        value: inchPer100YdRaw,
        symbol: 'in/100yd',
        decimals: 2,
      ),
      mrad: AnglesConvertorField(
        label: 'MRAD',
        formattedValue: _formatValue(mradRaw, 2, Unit.mRad.symbol),
        value: mradRaw,
        symbol: Unit.mRad.symbol,
        decimals: 2,
      ),
      degrees: AnglesConvertorField(
        label: 'Degrees',
        formattedValue: _formatValue(degreesRaw, 2, Unit.degree.symbol),
        value: degreesRaw,
        symbol: Unit.degree.symbol,
        decimals: 2,
      ),

      // Distance calculations in the selected unit
      oneMilAtDistance: _formatValue(oneMilValue, 1, outputUnit.symbol),
      angleInMoaAtDistance: _formatValue(angleMoaValue, 1, outputUnit.symbol),
      oneMoaAtDistance: _formatValue(oneMoaValue, 1, outputUnit.symbol),
      angleInMilAtDistance: _formatValue(angleMilValue, 1, outputUnit.symbol),
    );
  }
}

final anglesConvertorVmProvider =
    NotifierProvider<AnglesConvertorViewModel, AnglesConvertorUiState>(
      AnglesConvertorViewModel.new,
    );
