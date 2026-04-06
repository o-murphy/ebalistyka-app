import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

enum FocalPlane { ffp, sfp, lwir }

enum DragType { g1, g7, custom }

enum AdjustmentDisplayFormat { arrows, signs, letters }

@Entity()
class Owner {
  @Id()
  int id = 0;

  @Index()
  String? token;

  @Backlink('owner')
  final sights = ToMany<Sight>();

  @Backlink('owner')
  final cartridges = ToMany<Cartridge>();

  @Backlink('owner')
  final profiles = ToMany<Profile>();

  @Backlink('owner')
  final generalSettings = ToMany<GeneralSettings>();

  @Backlink('owner')
  final unitSettings = ToMany<UnitSettings>();

  @Backlink('owner')
  final tablesSettings = ToMany<TablesSettings>();

  @Backlink('owner')
  final convertorsState = ToMany<ConvertorsState>();
}

@Entity()
class Sight {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  @Transient()
  FocalPlane focalPlane = FocalPlane.ffp;

  String get focalPlaneValue => focalPlane.name;

  set focalPlaneValue(String value) {
    focalPlane = FocalPlane.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FocalPlane.ffp,
    );
  }

  double sightHeight = 0.0;
  double verticalClick = 0.1;
  double horizontalClick = 0.1;
  String verticalClickUnit = "mil";
  String horizontalClickUnit = "mil";
  double sightHorizontalOffset = 0.0;
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
class Cartridge {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  double caliber = 0.0;
  double weight = 0.0;
  double length = 0.0;

  @Transient()
  DragType dragType = DragType.g1;

  String get dragTypeValue => dragType.name;

  set dragTypeValue(String value) {
    dragType = DragType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DragType.g1,
    );
  }

  double bcG1 = 1.0;
  double bcG7 = 1.0;
  bool useMultiBcG1 = false;
  bool useMultiBcG7 = false;
  double? muzzleVelocity;
  double muzzleVelocityTemperature = 15.0;
  double powderTemperature = 15.0;
  double powderSensitivity = 0.0;

  Float64List? powderSensitivityTemperatures;
  Float64List? powderSensitivityVelocities;
  Float64List? multiBcTableG1Mv;
  Float64List? multiBcTableG1Bc;
  Float64List? multiBcTableG7Mv;
  Float64List? multiBcTableG7Bc;
  Float64List? cusomDragTableV;
  Float64List? cusomDragTableCd;

  double zeroDistance = 100.0;
  double zeroLookAngle = 0.0;
  double zeroTemperature = 15.0;
  double zeroPressure = 1013;
  double zeroHumidity = 0.0;
  double zeroPowdertemperature = 15.0;
  bool usePowderSensitivity = false;
  bool zeroUseDiffPowderTemperature = false;
  bool zeroUseCoriolis = false;
  double? zerolatitudeDeg;
  double? zeroAzimuthDeg;

  double zeroOffsetX = 0.0;
  double zeroOffsetY = 0.0;

  String? projectileName;
  String? vendor;
  String? image;

  @Backlink('cartridge')
  final profiles = ToMany<Profile>();

  final owner = ToOne<Owner>();
}

@Entity()
class Profile {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  double caliber = 0.0;
  double rTwist = 0.0;

  double? barrelLength;

  String? caliberName;
  String? vendor;
  String? image;

  final sight = ToOne<Sight>();
  final cartridge = ToOne<Cartridge>();

  final owner = ToOne<Owner>();
}

@Entity()
class GeneralSettings {
  @Id()
  int id = 0;

  String languageCode = "en";
  String themeMode = "system";

  @Transient()
  AdjustmentDisplayFormat adjustmentDisplayFormat =
      AdjustmentDisplayFormat.arrows;

  String get adjustmentDisplayFormatValue => adjustmentDisplayFormat.name;

  set adjustmentDisplayFormatValue(String value) {
    adjustmentDisplayFormat = AdjustmentDisplayFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdjustmentDisplayFormat.arrows,
    );
  }

  bool homeShowMil = false;
  bool homeShowMrad = false;
  bool homeShowMoa = false;
  bool homeShowCmPer100m = false;
  bool homeShowInPer100yd = false;
  double homeChartDistanceStep = 10;
  double homeTableDistanceStep = 10;
  bool homeShowSubsonicTransition = false;

  final activeProfile = ToOne<Profile>();

  final owner = ToOne<Owner>();
}

@Entity()
class TablesSettings {
  @Id()
  int id = 0;

  double distanceStart = 0.0;
  double distanceEnd = 2000.0;
  double distanceStep = 100.0;

  bool showZeros = true;
  bool showSubsonicTransition = true;
  List<String> hiddenCols = const [];
  List<String> hiddenAdjustmentCols = const [];

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
class ConvertorsState {
  @Id()
  int id = 0;

  double lengthValueInch = 100.0;
  String lengthUnit = "inch";
  double weightValueGrain = 100.0;
  String weight = "grain";
  double pressureValueMmHg = 1013.0;
  String pressure = "hPa";
  double temperatureValueFahrenheit = 68.0;
  String temperature = "celsius";
  double torqueValueNewtonMeter = 100.0;
  String torque = "newtonMeter";
  double anglesConvertorDistanceValueMeter = 100.0;
  String anglesConvertorDistance = "meter";
  double anglesConvertorAngularValueMil = 1.0;
  String anglesConvertorAngular = "mil";
  String anglesConvertorOutput = "centimeter";

  final owner = ToOne<Owner>();
}
