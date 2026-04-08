import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class Owner {
  @Id()
  int id = 0;

  @Index()
  String? token;

  @Backlink('owner')
  final weapons = ToMany<Weapon>();

  @Backlink('owner')
  final sights = ToMany<Sight>();

  @Backlink('owner')
  final cartridges = ToMany<Ammo>();

  @Backlink('owner')
  final profiles = ToMany<Profile>();

  final activeProfile = ToOne<Profile>();
}

@Entity()
class Weapon {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  double caliberInch = 0.0;
  String caliberName = "";
  double twistInch = 0.0;

  double? barrelLengthInch;

  double zeroElevationRad = 0.0;

  String? vendor;
  String? image;

  final owner = ToOne<Owner>();
}

@Entity()
class Sight {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  String focalPlaneValue = "ffp";

  double sightHeightInch = 0.0;
  double sightHorizontalOffsetInch = 0.0;
  double verticalClick = 0.1;
  double horizontalClick = 0.1;
  String verticalClickUnit = "mil";
  String horizontalClickUnit = "mil";
  double minMagnification = 0.0;
  double maxMagnification = 0.0;

  String? reticleImage;

  String? vendor;
  String? notes;
  String? image;

  @Backlink('sight')
  final profiles = ToMany<Profile>();

  final owner = ToOne<Owner>();
}

@Entity()
class Ammo {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  double caliberInch = 0.0;
  double weightGrain = 0.0;
  double lengthInch = 0.0;

  String dragTypeValue = "g1";

  double bcG1 = 1.0;
  double bcG7 = 1.0;
  bool useMultiBcG1 = false;
  bool useMultiBcG7 = false;
  double? muzzleVelocityMps;
  double muzzleVelocityTemperatureC = 15.0;
  double powderTemperatureC = 15.0;
  double powderSensitivityFrac = 0.0;

  bool usePowderSensitivity = false;
  bool usePowderTempForMv = false;

  Float64List? powderSensitivityTC;
  Float64List? powderSensitivityVMps;
  Float64List? multiBcTableG1VMps;
  Float64List? multiBcTableG1Bc;
  Float64List? multiBcTableG7VMps;
  Float64List? multiBcTableG7Bc;
  Float64List? cusomDragTableMach;
  Float64List? cusomDragTableCd;

  double zeroDistanceMeter = 100.0;
  double zeroLookAngleRad = 0.0;
  double zeroAltitudeMeter = 0.0;
  double zeroTemperatureC = 15.0;
  double zeroPressurehPa = 1013;
  double zeroHumidityFrac = 0.0;
  double zeroPowderTemperatureC = 15.0;

  bool zeroUseDiffPowderTemperature = false;
  bool zeroUseCoriolis = false;

  double zerolatitudeDeg = 0.0;
  double zeroAzimuthDeg = 0.0;

  double zeroOffsetXRad = 0.0;
  double zeroOffsetYRad = 0.0;

  String? projectileName;
  String? vendor;
  String? image;

  @Backlink('ammo')
  final profiles = ToMany<Profile>();

  final owner = ToOne<Owner>();
}

@Entity()
class Profile {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  int sortOrder = 0;

  final weapon = ToOne<Weapon>();
  final sight = ToOne<Sight>();
  final ammo = ToOne<Ammo>();

  final owner = ToOne<Owner>();
}

@Entity()
class GeneralSettings {
  @Id()
  int id = 0;

  String languageCode = "en";
  String themeMode = "system";

  String adjustmentDisplayFormatValue = "arrows";

  bool homeShowMil = false;
  bool homeShowMrad = false;
  bool homeShowMoa = false;
  bool homeShowCmPer100m = false;
  bool homeShowInPer100yd = false;
  double homeChartDistanceStep = 10;
  double homeTableDistanceStep = 10;
  bool homeShowSubsonicTransition = false;

  final owner = ToOne<Owner>();
}

@Entity()
class TablesSettings {
  @Id()
  int id = 0;

  double distanceStartMeter = 0.0;
  double distanceEndMeter = 2000.0;
  double distanceStepMeter = 100.0;

  bool showZeros = true;
  bool showSubsonicTransition = true;
  List<String> hiddenCols = const [];
  bool showMil = false;
  bool showMrad = false;
  bool showMoa = false;
  bool showCmPer100m = false;
  bool showInPer100yd = false;

  final owner = ToOne<Owner>();
}

@Entity()
class UnitSettings {
  @Id()
  int id = 0;

  String angular = "degree";
  String distance = "meter";
  String velocity = "mps";
  String pressure = "hPa";
  String temperature = "celsius";
  String diameter = "inch";
  String length = "inch";
  String weight = "grain";
  String adjustment = "mil";
  String drop = "cm";
  String energy = "joule";
  String sightHeight = "inch";
  String twist = "inch";
  String barrelLength = "inch";
  String time = "second";
  String torque = "newtonMeter";

  final owner = ToOne<Owner>();
}

@Entity()
class ShootingConditions {
  @Id()
  int id = 0;

  double distanceMeter = 100.0;
  double lookAngleRad = 0.0;
  double altitudeMeter = 0.0;
  double temperatureC = 15.0;
  double pressurehPa = 1013.25;
  double humidityFrac = 0.0;
  double powderTemperatureC = 15.0;
  bool usePowderSensitivity = false;
  bool useDiffPowderTemp = false;
  bool useCoriolis = false;
  double latitudeDeg = 0.0;
  double azimuthDeg = 0.0;
  double windDirectionDeg = 0.0;
  double windSpeedMps = 0.0;

  final owner = ToOne<Owner>();
}

@Entity()
class ConvertorsState {
  @Id()
  int id = 0;

  double lengthValueInch = 100.0;
  String lengthLastUnit = "inch";
  double weightValueGrain = 100.0;
  String weightLastUnit = "grain";
  double pressureValueMmHg = 1013.0;
  String pressureLastUnit = "hPa";
  double temperatureValueF = 68.0;
  String temperatureLastUnit = "celsius";
  double torqueValueNewtonMeter = 100.0;
  String torqueLastUnit = "newtonMeter";
  double anglesConvDistanceValueMeter = 100.0;
  String anglesConvDistanceLastUnit = "meter";
  double anglesConvAngularValueMil = 1.0;
  String anglesConvAngularLastUnit = "mil";
  String anglesConvOutputLastUnit = "centimeter";

  final owner = ToOne<Owner>();
}
