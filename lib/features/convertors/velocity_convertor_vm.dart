import 'dart:async';

import 'package:bclibc_ffi/bclibc.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
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
    final l10n = ref.watch(appLocalizationsProvider);
    return _buildState(s, l10n);
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final s = ref.read(convertorStateProvider);
    if (rawValueInInputUnit == null) {
      unawaited(
        ref.read(convertorsProvider.notifier).updateVelocityValue(null),
      );
      return;
    }
    if (s.velocityUnit == Unit.mach) {
      // Store the mach number; mps is derived on the fly from mach + atmo.
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateVelocityMachInputValue(rawValueInInputUnit),
      );
    } else {
      final mpsValue = rawValueInInputUnit.convert(s.velocityUnit, Unit.mps);
      if (mpsValue >= 0) {
        unawaited(
          ref.read(convertorsProvider.notifier).updateVelocityValue(mpsValue),
        );
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
      unawaited(
        ref
            .read(convertorsProvider.notifier)
            .updateVelocityMachInputValue(machValue),
      );
    } else if (newUnit != Unit.mach && s.velocityUnit == Unit.mach) {
      // Switching FROM mach: sync mps from stored mach + current atmo.
      final mpsValue = s.velocityMachInputValue
          .toVelocityFromMach(atmo)
          .in_(Unit.mps);
      unawaited(
        ref.read(convertorsProvider.notifier).updateVelocityValue(mpsValue),
      );
    }

    unawaited(
      ref.read(convertorsProvider.notifier).updateVelocityUnit(newUnit),
    );
  }

  void toggleCustomAtmo(bool value) {
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityMachUseCustomAtmo(value),
    );
  }

  void updateAtmoTemperature(double rawValue) {
    final units = ref.read(unitSettingsProvider);
    final celsiusValue = rawValue.convert(units.temperatureUnit, Unit.celsius);
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityAtmoTemperature(Temperature.celsius(celsiusValue)),
    );
  }

  void updateAtmoPressure(double rawValue) {
    final units = ref.read(unitSettingsProvider);
    final hPaValue = rawValue.convert(units.pressureUnit, Unit.hPa);
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityAtmoPressure(Pressure.hPa(hPaValue)),
    );
  }

  void updateAtmoHumidity(double rawFrac) {
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityAtmoHumidityFrac(rawFrac),
    );
  }

  void updateAtmoAltitude(double rawValue) {
    final units = ref.read(unitSettingsProvider);
    final meterValue = rawValue.convert(units.distanceUnit, Unit.meter);
    unawaited(
      ref
          .read(convertorsProvider.notifier)
          .updateVelocityAtmoAltitude(Distance.meter(meterValue)),
    );
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

  VelocityConvertorUiState _buildState(
    ConvertorsState s,
    AppLocalizations l10n,
  ) {
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
        labelBuilder: (l10n) => l10n.unitMps,
        formattedValue: _formatValue(
          rawMps,
          mpsAccuracy,
          Unit.mps.localizedSymbol(l10n),
        ),
        value: rawMps,
        symbol: Unit.mps.localizedSymbol(l10n),
        decimals: mpsAccuracy,
      ),
      kmh: GenericConvertorField(
        labelBuilder: (l10n) => l10n.unitKmh,
        formattedValue: _formatValue(
          kmhRaw,
          kmhAccuracy,
          Unit.kmh.localizedSymbol(l10n),
        ),
        value: kmhRaw,
        symbol: Unit.kmh.localizedSymbol(l10n),
        decimals: kmhAccuracy,
      ),
      fps: GenericConvertorField(
        labelBuilder: (l10n) => l10n.unitFps,
        formattedValue: _formatValue(
          fpsRaw,
          fpsAccuracy,
          Unit.fps.localizedSymbol(l10n),
        ),
        value: fpsRaw,
        symbol: Unit.fps.localizedSymbol(l10n),
        decimals: fpsAccuracy,
      ),
      mph: GenericConvertorField(
        labelBuilder: (l10n) => l10n.unitMph,
        formattedValue: _formatValue(
          mphRaw,
          mphAccuracy,
          Unit.mph.localizedSymbol(l10n),
        ),
        value: mphRaw,
        symbol: Unit.mph.localizedSymbol(l10n),
        decimals: mphAccuracy,
      ),
      mach: GenericConvertorField(
        labelBuilder: (l10n) =>
            useCustom ? l10n.unitMachCustom : l10n.unitMachIcao,
        formattedValue: _formatValue(
          machRaw,
          3,
          Unit.mach.localizedSymbol(l10n),
        ),
        value: machRaw,
        symbol: Unit.mach.localizedSymbol(l10n),
        decimals: 3,
      ),
    );
  }
}

final velocityConvertorVmProvider =
    NotifierProvider<VelocityConvertorViewModel, VelocityConvertorUiState>(
      VelocityConvertorViewModel.new,
    );
