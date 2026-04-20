import 'package:bclibc_ffi/bclibc.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';

class VelocityConvertorUiState {
  final GenericConvertorField mps;
  final GenericConvertorField kmh;
  final GenericConvertorField fps;
  final GenericConvertorField mph;
  final GenericConvertorField mach;
  final double? rawValue;
  final Unit inputUnit;

  const VelocityConvertorUiState({
    required this.mps,
    required this.kmh,
    required this.fps,
    required this.mph,
    required this.mach,
    required this.rawValue,
    required this.inputUnit,
  });
}

class VelocityConvertorViewModel extends Notifier<VelocityConvertorUiState> {
  @override
  VelocityConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.velocityValueMps,
      convertorsState.velocityUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateVelocityValue(null);
      return;
    }

    final mpsValue = rawValueInInputUnit.convert(
      convertorsState.velocityUnit,
      Unit.mps,
    );
    if (mpsValue >= 0) {
      ref.read(convertorsProvider.notifier).updateVelocityValue(mpsValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateVelocityUnit(newUnit);
  }

  double? _getDisplayValue(double? rawMps, Unit inputUnit) {
    if (rawMps == null) return null;
    return rawMps.convert(Unit.mps, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    return FieldConstraints(
      minRaw: FC.convertorVelocity.minRaw.convert(Unit.mps, unit),
      maxRaw: FC.convertorVelocity.maxRaw.convert(Unit.mps, unit),
      stepRaw: FC.convertorVelocity.stepRaw.convert(Unit.mps, unit),
      rawUnit: unit,
      accuracy: FC.convertorVelocity.accuracyFor(unit),
    );
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  VelocityConvertorUiState _buildState(double rawMps, Unit inputUnit) {
    final mpsRaw = rawMps;
    final kmhRaw = mpsRaw.convert(Unit.mps, Unit.kmh);
    final fpsRaw = mpsRaw.convert(Unit.mps, Unit.fps);
    final mphRaw = mpsRaw.convert(Unit.mps, Unit.mph);

    final speedOfSoundMps = Atmo.icao().mach.in_(Unit.mps);
    final machRaw = speedOfSoundMps > 0 ? mpsRaw / speedOfSoundMps : 0.0;

    final mpsAccuracy = FC.convertorVelocity.accuracyFor(Unit.mps);
    final kmhAccuracy = FC.convertorVelocity.accuracyFor(Unit.kmh);
    final fpsAccuracy = FC.convertorVelocity.accuracyFor(Unit.fps);
    final mphAccuracy = FC.convertorVelocity.accuracyFor(Unit.mph);

    return VelocityConvertorUiState(
      rawValue: _getDisplayValue(rawMps, inputUnit),
      inputUnit: inputUnit,
      mps: GenericConvertorField(
        label: 'Meters per second',
        formattedValue: _formatValue(mpsRaw, mpsAccuracy, Unit.mps.symbol),
        value: mpsRaw,
        symbol: Unit.mps.symbol,
        decimals: mpsAccuracy,
      ),
      kmh: GenericConvertorField(
        label: 'Kilometers per hour',
        formattedValue: _formatValue(kmhRaw, kmhAccuracy, Unit.kmh.symbol),
        value: kmhRaw,
        symbol: Unit.kmh.symbol,
        decimals: kmhAccuracy,
      ),
      fps: GenericConvertorField(
        label: 'Feet per second',
        formattedValue: _formatValue(fpsRaw, fpsAccuracy, Unit.fps.symbol),
        value: fpsRaw,
        symbol: Unit.fps.symbol,
        decimals: fpsAccuracy,
      ),
      mph: GenericConvertorField(
        label: 'Miles per hour',
        formattedValue: _formatValue(mphRaw, mphAccuracy, Unit.mph.symbol),
        value: mphRaw,
        symbol: Unit.mph.symbol,
        decimals: mphAccuracy,
      ),
      mach: GenericConvertorField(
        label: 'Mach (ICAO)',
        formattedValue: _formatValue(machRaw, 3, 'Ma'),
        value: machRaw,
        symbol: 'Ma',
        decimals: 3,
      ),
    );
  }
}

final velocityConvertorVmProvider =
    NotifierProvider<VelocityConvertorViewModel, VelocityConvertorUiState>(
      VelocityConvertorViewModel.new,
    );
