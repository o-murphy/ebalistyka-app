import 'package:bclibc_ffi/bclibc.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

class VelocityConvertorUiState {
  final GenericConvertorField mps;
  final GenericConvertorField kmh;
  final GenericConvertorField fps;
  final GenericConvertorField mph;
  final GenericConvertorField mach;
  final double? rawValue;
  final Unit inputUnit;

  final bool useCustomAtmo;
  final double atmoTemperatureC;
  final double atmoPressureHPa;
  final double atmoHumidityFrac;
  final double atmoAltitudeMeter;

  const VelocityConvertorUiState({
    required this.mps,
    required this.kmh,
    required this.fps,
    required this.mph,
    required this.mach,
    required this.rawValue,
    required this.inputUnit,
    required this.useCustomAtmo,
    required this.atmoTemperatureC,
    required this.atmoPressureHPa,
    required this.atmoHumidityFrac,
    required this.atmoAltitudeMeter,
  });
}

class VelocityConvertorViewModel extends Notifier<VelocityConvertorUiState> {
  @override
  VelocityConvertorUiState build() {
    final s = ref.watch(convertorStateProvider);
    return _buildState(s);
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final s = ref.read(convertorStateProvider);
    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateVelocityValue(null);
      return;
    }
    if (s.velocityUnit == Unit.mach) {
      // Store the mach number; mps is derived on the fly from mach + atmo.
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityMachInputValue(rawValueInInputUnit);
    } else {
      final mpsValue = rawValueInInputUnit.convert(s.velocityUnit, Unit.mps);
      if (mpsValue >= 0) {
        ref.read(convertorsProvider.notifier).updateVelocityValue(mpsValue);
      }
    }
  }

  /// Switches the input unit, converting the stored value so the displayed
  /// number stays consistent after the switch.
  void changeInputUnit(Unit newUnit) {
    final s = ref.read(convertorStateProvider);
    final atmo = _buildAtmo(s);

    if (newUnit == Unit.mach && s.velocityUnit != Unit.mach) {
      // Switching TO mach: sync mach from current stored mps.
      final machValue = s.velocityValue.inMach(atmo);
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityMachInputValue(machValue);
    } else if (newUnit != Unit.mach && s.velocityUnit == Unit.mach) {
      // Switching FROM mach: sync mps from stored mach + current atmo.
      final mpsValue = s.velocityMachInputValue
          .toVelocityFromMach(atmo)
          .in_(Unit.mps);
      ref.read(convertorsProvider.notifier).updateVelocityValue(mpsValue);
    }

    ref.read(convertorsProvider.notifier).updateVelocityUnit(newUnit);
  }

  void toggleCustomAtmo(bool value) {
    ref
        .read(convertorsProvider.notifier)
        .updateVelocityMachUseCustomAtmo(value);
  }

  void updateAtmoTemperature(double rawCelsius) {
    ref
        .read(convertorsProvider.notifier)
        .updateVelocityAtmoTemperature(Temperature.celsius(rawCelsius));
  }

  void updateAtmoPressure(double rawHPa) {
    ref
        .read(convertorsProvider.notifier)
        .updateVelocityAtmoPressure(Pressure.hPa(rawHPa));
  }

  void updateAtmoHumidity(double rawFrac) {
    ref
        .read(convertorsProvider.notifier)
        .updateVelocityAtmoHumidityFrac(rawFrac);
  }

  void updateAtmoAltitude(double rawMeter) {
    ref
        .read(convertorsProvider.notifier)
        .updateVelocityAtmoAltitude(Distance.meter(rawMeter));
  }

  Atmo _buildAtmo(ConvertorsState s) => s.velocityMachUseCustomAtmo
      ? Atmo(
          temperature: s.velocityAtmoTemperature,
          pressure: s.velocityAtmoPressure,
          humidity: s.velocityAtmoHumidityFrac,
          altitude: s.velocityAtmoAltitude,
        )
      : Atmo.icao();

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

  VelocityConvertorUiState _buildState(ConvertorsState s) {
    final inputUnit = s.velocityUnit;
    final useCustom = s.velocityMachUseCustomAtmo;
    final atmo = _buildAtmo(s);
    final speedOfSoundMps = atmo.mach.in_(Unit.mps);

    // When mach is the input unit, the stored mach number is source of truth;
    // all other units are derived from mach × speed-of-sound.
    final double rawMps;
    final double machRaw;
    if (inputUnit == Unit.mach) {
      machRaw = s.velocityMachInputValue;
      rawMps = machRaw * speedOfSoundMps;
    } else {
      rawMps = s.velocityValue.in_(Unit.mps);
      machRaw = speedOfSoundMps > 0 ? rawMps / speedOfSoundMps : 0.0;
    }

    final kmhRaw = rawMps.convert(Unit.mps, Unit.kmh);
    final fpsRaw = rawMps.convert(Unit.mps, Unit.fps);
    final mphRaw = rawMps.convert(Unit.mps, Unit.mph);

    final mpsAccuracy = FC.convertorVelocity.accuracyFor(Unit.mps);
    final kmhAccuracy = FC.convertorVelocity.accuracyFor(Unit.kmh);
    final fpsAccuracy = FC.convertorVelocity.accuracyFor(Unit.fps);
    final mphAccuracy = FC.convertorVelocity.accuracyFor(Unit.mph);

    final double displayRawValue = inputUnit == Unit.mach
        ? machRaw
        : rawMps.convert(Unit.mps, inputUnit);

    return VelocityConvertorUiState(
      rawValue: displayRawValue,
      inputUnit: inputUnit,
      useCustomAtmo: useCustom,
      atmoTemperatureC: s.velocityAtmoTemperature.in_(Unit.celsius),
      atmoPressureHPa: s.velocityAtmoPressure.in_(Unit.hPa),
      atmoHumidityFrac: s.velocityAtmoHumidityFrac,
      atmoAltitudeMeter: s.velocityAtmoAltitude.in_(Unit.meter),
      mps: GenericConvertorField(
        label: 'Meters per second',
        formattedValue: _formatValue(rawMps, mpsAccuracy, Unit.mps.symbol),
        value: rawMps,
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
        label: useCustom ? 'Mach (custom atmo)' : 'Mach (ICAO)',
        formattedValue: _formatValue(machRaw, 3, Unit.mach.symbol),
        value: machRaw,
        symbol: Unit.mach.symbol,
        decimals: 3,
      ),
    );
  }
}

final velocityConvertorVmProvider =
    NotifierProvider<VelocityConvertorViewModel, VelocityConvertorUiState>(
      VelocityConvertorViewModel.new,
    );
