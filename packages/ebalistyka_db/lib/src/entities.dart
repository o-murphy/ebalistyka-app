import 'dart:typed_data';

import 'package:ebalistyka_db/src/clonable.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Owner with Cloneable<Owner> {
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

  @override
  Owner copyWith({int? id, String? token}) {
    return Owner()
      ..id = id ?? this.id
      ..token = token ?? this.token;
  }
}

@Entity()
class Weapon with Cloneable<Weapon> {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  double caliberInch = -1.0;
  String caliberName = "";
  double twistInch = 0.0;

  double barrelLengthInch = -1.0;

  double zeroElevationRad = 0.0;

  String? vendor;
  String? notes;
  String? image;

  final owner = ToOne<Owner>();

  @override
  Weapon copyWith({
    int? id,
    String? name,
    double? caliberInch,
    String? caliberName,
    double? twistInch,
    double? barrelLengthInch,
    double? zeroElevationRad,
    String? vendor,
    String? notes,
    String? image,
  }) {
    return Weapon()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..caliberInch = caliberInch ?? this.caliberInch
      ..caliberName = caliberName ?? this.caliberName
      ..twistInch = twistInch ?? this.twistInch
      ..barrelLengthInch = barrelLengthInch ?? this.barrelLengthInch
      ..zeroElevationRad = zeroElevationRad ?? this.zeroElevationRad
      ..vendor = vendor ?? this.vendor
      ..notes = notes ?? this.notes
      ..image = image ?? this.image;
  }
}

@Entity()
class Sight with Cloneable<Sight> {
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
  double minMagnification = 1.0;
  double maxMagnification = 1.0;

  String? reticleImage;
  double calibratedMagnification = -1.0;

  String? vendor;
  String? notes;
  String? image;

  @Backlink('sight')
  final profiles = ToMany<Profile>();

  final owner = ToOne<Owner>();

  @override
  Sight copyWith({
    int? id,
    String? name,
    String? focalPlaneValue,
    double? sightHeightInch,
    double? sightHorizontalOffsetInch,
    double? verticalClick,
    double? horizontalClick,
    String? verticalClickUnit,
    String? horizontalClickUnit,
    double? minMagnification,
    double? maxMagnification,
    String? reticleImage,
    double? calibratedMagnification,
    String? vendor,
    String? notes,
    String? image,
  }) {
    return Sight()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..focalPlaneValue = focalPlaneValue ?? this.focalPlaneValue
      ..sightHeightInch = sightHeightInch ?? this.sightHeightInch
      ..sightHorizontalOffsetInch =
          sightHorizontalOffsetInch ?? this.sightHorizontalOffsetInch
      ..verticalClick = verticalClick ?? this.verticalClick
      ..horizontalClick = horizontalClick ?? this.horizontalClick
      ..verticalClickUnit = verticalClickUnit ?? this.verticalClickUnit
      ..horizontalClickUnit = horizontalClickUnit ?? this.horizontalClickUnit
      ..minMagnification = minMagnification ?? this.minMagnification
      ..maxMagnification = maxMagnification ?? this.maxMagnification
      ..reticleImage = reticleImage ?? this.reticleImage
      ..calibratedMagnification =
          calibratedMagnification ?? this.calibratedMagnification
      ..vendor = vendor ?? this.vendor
      ..notes = notes ?? this.notes
      ..image = image ?? this.image;
  }
}

@Entity()
class Ammo with Cloneable<Ammo> {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  double caliberInch = -1.0;
  double weightGrain = -1.0;
  double lengthInch = -1.0;

  String dragTypeValue = "g1";

  double bcG1 = -1.0;
  double bcG7 = -1.0;
  bool useMultiBcG1 = false;
  bool useMultiBcG7 = false;

  double muzzleVelocityMps = -1.0;
  double muzzleVelocityTemperatureC = 15.0;

  bool usePowderSensitivity = false;
  double powderSensitivityFrac = 0.0;

  Float64List? powderSensitivityTC;
  Float64List? powderSensitivityVMps;
  Float64List? multiBcTableG1VMps;
  Float64List? multiBcTableG1Bc;
  Float64List? multiBcTableG7VMps;
  Float64List? multiBcTableG7Bc;
  Float64List? customDragTableMach;
  Float64List? customDragTableCd;

  double zeroDistanceMeter = 100.0;
  double zeroLookAngleRad = 0.0;
  double zeroAltitudeMeter = 0.0;
  double zeroTemperatureC = 15.0;
  double zeroPressurehPa = 1013;
  double zeroHumidityFrac = 0.0;

  bool zeroUseDiffPowderTemperature = false;
  bool zeroUseCoriolis = false;
  double zeroPowderTemperatureC = 15.0;

  double zeroLatitudeDeg = 0.0;
  double zeroAzimuthDeg = 0.0;

  double zeroOffsetXRad = 0.0;
  double zeroOffsetYRad = 0.0;

  String? projectileName;
  String? vendor;
  String? image;

  @Backlink('ammo')
  final profiles = ToMany<Profile>();

  final owner = ToOne<Owner>();

  @override
  Ammo copyWith({
    int? id,
    String? name,
    double? caliberInch,
    double? weightGrain,
    double? lengthInch,
    String? dragTypeValue,
    double? bcG1,
    double? bcG7,
    bool? useMultiBcG1,
    bool? useMultiBcG7,
    double? muzzleVelocityMps,
    double? muzzleVelocityTemperatureC,
    bool? usePowderSensitivity,
    double? powderSensitivityFrac,
    Float64List? powderSensitivityTC,
    Float64List? powderSensitivityVMps,
    Float64List? multiBcTableG1VMps,
    Float64List? multiBcTableG1Bc,
    Float64List? multiBcTableG7VMps,
    Float64List? multiBcTableG7Bc,
    Float64List? customDragTableMach,
    Float64List? customDragTableCd,
    double? zeroDistanceMeter,
    double? zeroLookAngleRad,
    double? zeroAltitudeMeter,
    double? zeroTemperatureC,
    double? zeroPressurehPa,
    double? zeroHumidityFrac,
    bool? zeroUseDiffPowderTemperature,
    bool? zeroUseCoriolis,
    double? zeroPowderTemperatureC,
    double? zeroLatitudeDeg,
    double? zeroAzimuthDeg,
    double? zeroOffsetXRad,
    double? zeroOffsetYRad,
    String? projectileName,
    String? vendor,
    String? image,
  }) {
    return Ammo()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..caliberInch = caliberInch ?? this.caliberInch
      ..weightGrain = weightGrain ?? this.weightGrain
      ..lengthInch = lengthInch ?? this.lengthInch
      ..dragTypeValue = dragTypeValue ?? this.dragTypeValue
      ..bcG1 = bcG1 ?? this.bcG1
      ..bcG7 = bcG7 ?? this.bcG7
      ..useMultiBcG1 = useMultiBcG1 ?? this.useMultiBcG1
      ..useMultiBcG7 = useMultiBcG7 ?? this.useMultiBcG7
      ..muzzleVelocityMps = muzzleVelocityMps ?? this.muzzleVelocityMps
      ..muzzleVelocityTemperatureC =
          muzzleVelocityTemperatureC ?? this.muzzleVelocityTemperatureC
      ..usePowderSensitivity = usePowderSensitivity ?? this.usePowderSensitivity
      ..powderSensitivityFrac =
          powderSensitivityFrac ?? this.powderSensitivityFrac
      ..powderSensitivityTC = powderSensitivityTC ?? this.powderSensitivityTC
      ..powderSensitivityVMps =
          powderSensitivityVMps ?? this.powderSensitivityVMps
      ..multiBcTableG1VMps = multiBcTableG1VMps ?? this.multiBcTableG1VMps
      ..multiBcTableG1Bc = multiBcTableG1Bc ?? this.multiBcTableG1Bc
      ..multiBcTableG7VMps = multiBcTableG7VMps ?? this.multiBcTableG7VMps
      ..multiBcTableG7Bc = multiBcTableG7Bc ?? this.multiBcTableG7Bc
      ..customDragTableMach = customDragTableMach ?? this.customDragTableMach
      ..customDragTableCd = customDragTableCd ?? this.customDragTableCd
      ..zeroDistanceMeter = zeroDistanceMeter ?? this.zeroDistanceMeter
      ..zeroLookAngleRad = zeroLookAngleRad ?? this.zeroLookAngleRad
      ..zeroAltitudeMeter = zeroAltitudeMeter ?? this.zeroAltitudeMeter
      ..zeroTemperatureC = zeroTemperatureC ?? this.zeroTemperatureC
      ..zeroPressurehPa = zeroPressurehPa ?? this.zeroPressurehPa
      ..zeroHumidityFrac = zeroHumidityFrac ?? this.zeroHumidityFrac
      ..zeroUseDiffPowderTemperature =
          zeroUseDiffPowderTemperature ?? this.zeroUseDiffPowderTemperature
      ..zeroUseCoriolis = zeroUseCoriolis ?? this.zeroUseCoriolis
      ..zeroPowderTemperatureC =
          zeroPowderTemperatureC ?? this.zeroPowderTemperatureC
      ..zeroLatitudeDeg = zeroLatitudeDeg ?? this.zeroLatitudeDeg
      ..zeroAzimuthDeg = zeroAzimuthDeg ?? this.zeroAzimuthDeg
      ..zeroOffsetXRad = zeroOffsetXRad ?? this.zeroOffsetXRad
      ..zeroOffsetYRad = zeroOffsetYRad ?? this.zeroOffsetYRad
      ..projectileName = projectileName ?? this.projectileName
      ..vendor = vendor ?? this.vendor
      ..image = image ?? this.image;
  }
}

@Entity()
class Profile with Cloneable<Profile> {
  @Id()
  int id = 0;

  @Index()
  String name = "";

  final weapon = ToOne<Weapon>();
  final sight = ToOne<Sight>();
  final ammo = ToOne<Ammo>();

  final owner = ToOne<Owner>();

  @override
  Profile copyWith({int? id, String? name}) {
    return Profile()
      ..id = id ?? this.id
      ..name = name ?? this.name;
  }
}

@Entity()
class GeneralSettings with Cloneable<GeneralSettings> {
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

  @override
  GeneralSettings copyWith({
    int? id,
    String? languageCode,
    String? themeMode,
    String? adjustmentDisplayFormatValue,
    bool? homeShowMil,
    bool? homeShowMrad,
    bool? homeShowMoa,
    bool? homeShowCmPer100m,
    bool? homeShowInPer100yd,
    double? homeChartDistanceStep,
    double? homeTableDistanceStep,
    bool? homeShowSubsonicTransition,
  }) {
    return GeneralSettings()
      ..id = id ?? this.id
      ..languageCode = languageCode ?? this.languageCode
      ..themeMode = themeMode ?? this.themeMode
      ..adjustmentDisplayFormatValue =
          adjustmentDisplayFormatValue ?? this.adjustmentDisplayFormatValue
      ..homeShowMil = homeShowMil ?? this.homeShowMil
      ..homeShowMrad = homeShowMrad ?? this.homeShowMrad
      ..homeShowMoa = homeShowMoa ?? this.homeShowMoa
      ..homeShowCmPer100m = homeShowCmPer100m ?? this.homeShowCmPer100m
      ..homeShowInPer100yd = homeShowInPer100yd ?? this.homeShowInPer100yd
      ..homeChartDistanceStep =
          homeChartDistanceStep ?? this.homeChartDistanceStep
      ..homeTableDistanceStep =
          homeTableDistanceStep ?? this.homeTableDistanceStep
      ..homeShowSubsonicTransition =
          homeShowSubsonicTransition ?? this.homeShowSubsonicTransition;
  }
}

@Entity()
class TablesSettings with Cloneable<TablesSettings> {
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

  @override
  TablesSettings copyWith({
    int? id,
    double? distanceStartMeter,
    double? distanceEndMeter,
    double? distanceStepMeter,
    bool? showZeros,
    bool? showSubsonicTransition,
    List<String>? hiddenCols,
    bool? showMil,
    bool? showMrad,
    bool? showMoa,
    bool? showCmPer100m,
    bool? showInPer100yd,
  }) {
    return TablesSettings()
      ..id = id ?? this.id
      ..distanceStartMeter = distanceStartMeter ?? this.distanceStartMeter
      ..distanceEndMeter = distanceEndMeter ?? this.distanceEndMeter
      ..distanceStepMeter = distanceStepMeter ?? this.distanceStepMeter
      ..showZeros = showZeros ?? this.showZeros
      ..showSubsonicTransition =
          showSubsonicTransition ?? this.showSubsonicTransition
      ..hiddenCols = hiddenCols ?? this.hiddenCols
      ..showMil = showMil ?? this.showMil
      ..showMrad = showMrad ?? this.showMrad
      ..showMoa = showMoa ?? this.showMoa
      ..showCmPer100m = showCmPer100m ?? this.showCmPer100m
      ..showInPer100yd = showInPer100yd ?? this.showInPer100yd;
  }
}

@Entity()
class UnitSettings with Cloneable<UnitSettings> {
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

  @override
  UnitSettings copyWith({
    int? id,
    String? angular,
    String? distance,
    String? velocity,
    String? pressure,
    String? temperature,
    String? diameter,
    String? length,
    String? weight,
    String? adjustment,
    String? drop,
    String? energy,
    String? sightHeight,
    String? twist,
    String? barrelLength,
    String? time,
    String? torque,
  }) {
    return UnitSettings()
      ..id = id ?? this.id
      ..angular = angular ?? this.angular
      ..distance = distance ?? this.distance
      ..velocity = velocity ?? this.velocity
      ..pressure = pressure ?? this.pressure
      ..temperature = temperature ?? this.temperature
      ..diameter = diameter ?? this.diameter
      ..length = length ?? this.length
      ..weight = weight ?? this.weight
      ..adjustment = adjustment ?? this.adjustment
      ..drop = drop ?? this.drop
      ..energy = energy ?? this.energy
      ..sightHeight = sightHeight ?? this.sightHeight
      ..twist = twist ?? this.twist
      ..barrelLength = barrelLength ?? this.barrelLength
      ..time = time ?? this.time
      ..torque = torque ?? this.torque;
  }
}

@Entity()
class ShootingConditions with Cloneable<ShootingConditions> {
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

  @override
  ShootingConditions copyWith({
    int? id,
    double? distanceMeter,
    double? lookAngleRad,
    double? altitudeMeter,
    double? temperatureC,
    double? pressurehPa,
    double? humidityFrac,
    double? powderTemperatureC,
    bool? usePowderSensitivity,
    bool? useDiffPowderTemp,
    bool? useCoriolis,
    double? latitudeDeg,
    double? azimuthDeg,
    double? windDirectionDeg,
    double? windSpeedMps,
  }) {
    return ShootingConditions()
      ..id = id ?? this.id
      ..distanceMeter = distanceMeter ?? this.distanceMeter
      ..lookAngleRad = lookAngleRad ?? this.lookAngleRad
      ..altitudeMeter = altitudeMeter ?? this.altitudeMeter
      ..temperatureC = temperatureC ?? this.temperatureC
      ..pressurehPa = pressurehPa ?? this.pressurehPa
      ..humidityFrac = humidityFrac ?? this.humidityFrac
      ..powderTemperatureC = powderTemperatureC ?? this.powderTemperatureC
      ..usePowderSensitivity = usePowderSensitivity ?? this.usePowderSensitivity
      ..useDiffPowderTemp = useDiffPowderTemp ?? this.useDiffPowderTemp
      ..useCoriolis = useCoriolis ?? this.useCoriolis
      ..latitudeDeg = latitudeDeg ?? this.latitudeDeg
      ..azimuthDeg = azimuthDeg ?? this.azimuthDeg
      ..windDirectionDeg = windDirectionDeg ?? this.windDirectionDeg
      ..windSpeedMps = windSpeedMps ?? this.windSpeedMps;
  }
}

@Entity()
class ConvertorsState with Cloneable<ConvertorsState> {
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

  @override
  ConvertorsState copyWith({
    int? id,
    double? lengthValueInch,
    String? lengthLastUnit,
    double? weightValueGrain,
    String? weightLastUnit,
    double? pressureValueMmHg,
    String? pressureLastUnit,
    double? temperatureValueF,
    String? temperatureLastUnit,
    double? torqueValueNewtonMeter,
    String? torqueLastUnit,
    double? anglesConvDistanceValueMeter,
    String? anglesConvDistanceLastUnit,
    double? anglesConvAngularValueMil,
    String? anglesConvAngularLastUnit,
    String? anglesConvOutputLastUnit,
  }) {
    return ConvertorsState()
      ..id = id ?? this.id
      ..lengthValueInch = lengthValueInch ?? this.lengthValueInch
      ..lengthLastUnit = lengthLastUnit ?? this.lengthLastUnit
      ..weightValueGrain = weightValueGrain ?? this.weightValueGrain
      ..weightLastUnit = weightLastUnit ?? this.weightLastUnit
      ..pressureValueMmHg = pressureValueMmHg ?? this.pressureValueMmHg
      ..pressureLastUnit = pressureLastUnit ?? this.pressureLastUnit
      ..temperatureValueF = temperatureValueF ?? this.temperatureValueF
      ..temperatureLastUnit = temperatureLastUnit ?? this.temperatureLastUnit
      ..torqueValueNewtonMeter =
          torqueValueNewtonMeter ?? this.torqueValueNewtonMeter
      ..torqueLastUnit = torqueLastUnit ?? this.torqueLastUnit
      ..anglesConvDistanceValueMeter =
          anglesConvDistanceValueMeter ?? this.anglesConvDistanceValueMeter
      ..anglesConvDistanceLastUnit =
          anglesConvDistanceLastUnit ?? this.anglesConvDistanceLastUnit
      ..anglesConvAngularValueMil =
          anglesConvAngularValueMil ?? this.anglesConvAngularValueMil
      ..anglesConvAngularLastUnit =
          anglesConvAngularLastUnit ?? this.anglesConvAngularLastUnit
      ..anglesConvOutputLastUnit =
          anglesConvOutputLastUnit ?? this.anglesConvOutputLastUnit;
  }
}
