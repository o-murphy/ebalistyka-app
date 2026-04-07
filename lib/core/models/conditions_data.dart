import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';

import '_storage.dart';

// ── AtmoData ──────────────────────────────────────────────────────────────────

class AtmoData {
  final Distance altitude;
  final Pressure pressure;
  final Temperature temperature;
  final double humidity; // fraction 0.0–1.0
  final Temperature powderTemp;

  const AtmoData({
    required this.altitude,
    required this.pressure,
    required this.temperature,
    required this.humidity,
    required this.powderTemp,
  });

  bclibc.Atmo toAtmo() => bclibc.Atmo(
    altitude: altitude,
    pressure: pressure,
    temperature: temperature,
    humidity: humidity,
    powderTemperature: powderTemp,
  );

  factory AtmoData.icao() {
    final atmo = bclibc.Atmo.icao();
    return AtmoData(
      altitude: atmo.altitude,
      pressure: atmo.pressure,
      temperature: atmo.temperature,
      humidity: atmo.humidity,
      powderTemp: atmo.powderTemp,
    );
  }

  AtmoData copyWith({
    Distance? altitude,
    Pressure? pressure,
    Temperature? temperature,
    double? humidity,
    Temperature? powderTemp,
  }) {
    return AtmoData(
      altitude: altitude ?? this.altitude,
      pressure: pressure ?? this.pressure,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      powderTemp: powderTemp ?? this.powderTemp,
    );
  }

  Map<String, dynamic> toJson() => {
    'altitude': altitude.in_(StorageUnits.atmoAltitude),
    'pressure': pressure.in_(StorageUnits.atmoPressure),
    'temperature': temperature.in_(StorageUnits.atmoTemperature),
    'humidity': humidity,
    'powderTemp': powderTemp.in_(StorageUnits.atmoPowderTemp),
  };

  factory AtmoData.fromJson(Map m) => AtmoData(
    altitude: Distance(
      (m['altitude'] as num).toDouble(),
      StorageUnits.atmoAltitude,
    ),
    pressure: Pressure(
      (m['pressure'] as num).toDouble(),
      StorageUnits.atmoPressure,
    ),
    temperature: Temperature(
      (m['temperature'] as num).toDouble(),
      StorageUnits.atmoTemperature,
    ),
    humidity: (m['humidity'] as num).toDouble(),
    powderTemp: Temperature(
      (m['powderTemp'] as num).toDouble(),
      StorageUnits.atmoPowderTemp,
    ),
  );
}

// ── WindData ──────────────────────────────────────────────────────────────────

class WindData {
  final Velocity velocity;
  final Angular directionFrom;

  const WindData({required this.velocity, required this.directionFrom});

  factory WindData.empty() =>
      WindData(velocity: Velocity.mps(0.0), directionFrom: Angular.radian(0.0));

  bclibc.Wind toWind() =>
      bclibc.Wind(velocity: velocity, directionFrom: directionFrom);

  Map<String, dynamic> toJson() => {
    'velocity': velocity.in_(StorageUnits.windVelocity),
    'directionFrom': directionFrom.in_(StorageUnits.windDirectionFrom),
  };

  factory WindData.fromJson(Map w) => WindData(
    velocity: Velocity(
      (w['velocity'] as num).toDouble(),
      StorageUnits.windVelocity,
    ),
    directionFrom: Angular(
      (w['directionFrom'] as num).toDouble(),
      StorageUnits.windDirectionFrom,
    ),
  );
}

class Conditions {
  final AtmoData atmo;
  final Distance distance;
  final Angular lookAngle;
  final WindData wind;
  final bool usePowderSensitivity;
  final bool useDiffPowderTemp;
  final bool useCoriolis;
  final double? latitudeDeg;
  final double? azimuthDeg;

  const Conditions({
    required this.atmo,
    required this.distance,
    required this.lookAngle,
    required this.wind,
    required this.usePowderSensitivity,
    required this.useDiffPowderTemp,
    required this.useCoriolis,
    this.latitudeDeg,
    this.azimuthDeg,
  });

  factory Conditions.withDefaults({
    WindData? wind,
    bool usePowderSensitivity = false,
    bool useDiffPowderTemp = false,
    bool useCoriolis = false,
    double? latitudeDeg,
    double? azimuthDeg,
    AtmoData? atmo,
    Distance? distance,
    Angular? lookAngle,
  }) {
    return Conditions(
      wind: WindData.empty(),
      useCoriolis: useCoriolis,
      usePowderSensitivity: usePowderSensitivity,
      useDiffPowderTemp: useDiffPowderTemp,
      atmo: atmo ?? AtmoData.icao(),
      distance: distance ?? Distance.meter(100.0),
      lookAngle: lookAngle ?? Angular.radian(0.0),
    );
  }

  bclibc.Atmo toAtmo() => bclibc.Atmo(
    altitude: atmo.altitude,
    pressure: atmo.pressure,
    temperature: atmo.temperature,
    humidity: atmo.humidity,
    powderTemperature: useDiffPowderTemp ? atmo.powderTemp : atmo.temperature,
  );

  Map<String, dynamic> toJson() => {
    'atmo': atmo.toJson(),
    'wind': wind,
    'lookAngle': lookAngle.in_(StorageUnits.profileLookAngle),
    'targetDistance': distance.in_(StorageUnits.profileTargetDistance),
    'usePowderSensitivity': usePowderSensitivity,
    'useDiffPowderTemp': useDiffPowderTemp,
    'useCoriolis': useCoriolis,
    if (latitudeDeg != null) 'latitudeDeg': latitudeDeg,
    if (azimuthDeg != null) 'azimuthDeg': azimuthDeg,
  };

  Conditions copyWith({
    AtmoData? atmo,
    WindData? wind,
    Angular? lookAngle,
    double? latitudeDeg,
    double? azimuthDeg,
    bool? usePowderSensitivity,
    bool? useDiffPowderTemp,
    bool? useCoriolis,
    Distance? distance,
  }) {
    return Conditions(
      atmo: atmo ?? this.atmo,
      wind: wind ?? this.wind,
      lookAngle: lookAngle ?? this.lookAngle,
      latitudeDeg: latitudeDeg ?? this.latitudeDeg,
      azimuthDeg: azimuthDeg ?? this.azimuthDeg,
      usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
      useDiffPowderTemp: useDiffPowderTemp ?? this.useDiffPowderTemp,
      useCoriolis: useCoriolis ?? this.useCoriolis,
      distance: distance ?? this.distance,
    );
  }

  static Conditions fromJson(Map<String, dynamic> json) {
    final atmo = json['atmo'] as Map;

    return Conditions.withDefaults(
      atmo: AtmoData.fromJson(atmo),
      wind: WindData.fromJson(json['wind'] as Map),
      lookAngle: Angular(
        (json['lookAngle'] as num).toDouble(),
        StorageUnits.profileLookAngle,
      ),
      latitudeDeg: (json['latitudeDeg'] as num?)?.toDouble(),
      azimuthDeg: (json['azimuthDeg'] as num?)?.toDouble(),
      distance: json['targetDistance'] != null
          ? Distance(
              (json['targetDistance'] as num).toDouble(),
              StorageUnits.profileTargetDistance,
            )
          : null,
      usePowderSensitivity: json['usePowderSensitivity'] as bool? ?? false,
      useDiffPowderTemp: json['useDiffPowderTemp'] as bool? ?? false,
      useCoriolis: json['useCoriolis'] as bool? ?? false,
    );
  }
}
