import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// App bar title and bottom navigation label for the home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeScreenTitle;

  /// App bar title and bottom navigation label for the conditions/atmosphere screen
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditionsScreenTitle;

  /// App bar title and bottom navigation label for the trajectory tables screen
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tablesScreenTitle;

  /// App bar title for the tables settings/configuration screen
  ///
  /// In en, this message translates to:
  /// **'Table Configuration'**
  String get tableConfigScreenTitle;

  /// App bar title and bottom navigation label for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// App bar title and bottom navigation label for the unit converters screen
  ///
  /// In en, this message translates to:
  /// **'Convertors'**
  String get convertorsScreenTitle;

  /// App bar title for the notes screen
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesScreenTitle;

  /// App bar title for the tools screen
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsScreenTitle;

  /// App bar title for the shot details/info screen
  ///
  /// In en, this message translates to:
  /// **'Shot info'**
  String get shotInfoScreenTitle;

  /// App bar title for the adjustment display settings sub-screen
  ///
  /// In en, this message translates to:
  /// **'Adjustment Display'**
  String get adjustmentDisplayScreenTitle;

  /// App bar title for the user's saved ammo list screen
  ///
  /// In en, this message translates to:
  /// **'My Ammo'**
  String get myAmmoScreenTitle;

  /// App bar title for the user's saved sights list screen
  ///
  /// In en, this message translates to:
  /// **'My Sights'**
  String get mySights;

  /// App bar title for the user's saved profiles list screen
  ///
  /// In en, this message translates to:
  /// **'My Profiles'**
  String get myProfiles;

  /// App bar title when creating a new weapon
  ///
  /// In en, this message translates to:
  /// **'New Weapon'**
  String get newWeaponScreenTitle;

  /// App bar title for the built-in weapon collection browser
  ///
  /// In en, this message translates to:
  /// **'Weapon Collection'**
  String get weaponCollectionScreenTitle;

  /// App bar title for the built-in bullet collection browser
  ///
  /// In en, this message translates to:
  /// **'Bullet Collection'**
  String get bulletCollectionScreenTitle;

  /// App bar title for the built-in cartridge collection browser
  ///
  /// In en, this message translates to:
  /// **'Cartridge Collection'**
  String get cartridgeCollectionScreenTitle;

  /// App bar title for the built-in sight collection browser
  ///
  /// In en, this message translates to:
  /// **'Sight Collection'**
  String get sightCollectionScreenTitle;

  /// App bar title for the reticle view / fullscreen reticle screen
  ///
  /// In en, this message translates to:
  /// **'Reticle'**
  String get reticleScreenTitle;

  /// App bar title for the powder temperature sensitivity table editor
  ///
  /// In en, this message translates to:
  /// **'Powder Temperature Sensitivity Table'**
  String get powderSensTableEditorTitle;

  /// App bar title for the length unit converter
  ///
  /// In en, this message translates to:
  /// **'Length Converter'**
  String get lengthConvertorTitle;

  /// App bar title for the weight unit converter
  ///
  /// In en, this message translates to:
  /// **'Weight Converter'**
  String get weightConvertorTitle;

  /// App bar title for the pressure unit converter
  ///
  /// In en, this message translates to:
  /// **'Pressure Converter'**
  String get pressureConvertorTitle;

  /// App bar title for the temperature unit converter
  ///
  /// In en, this message translates to:
  /// **'Temperature Converter'**
  String get temperatureConvertorTitle;

  /// App bar title for the torque unit converter
  ///
  /// In en, this message translates to:
  /// **'Torque Converter'**
  String get torqueConvertorTitle;

  /// App bar title for the velocity unit converter
  ///
  /// In en, this message translates to:
  /// **'Velocity Converter'**
  String get velocityConvertorTitle;

  /// App bar title for the angular units converter
  ///
  /// In en, this message translates to:
  /// **'Angles Converter'**
  String get anglesConvertorTitle;

  /// App bar title for the target distance / angular size converter
  ///
  /// In en, this message translates to:
  /// **'Target Distance'**
  String get targetDistanceConvertorTitle;

  /// Tab label for the trajectory data table
  ///
  /// In en, this message translates to:
  /// **'Trajectory'**
  String get tabTrajectory;

  /// Tab label for the shot details table
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tabDetails;

  /// Home screen page label for the holdovers / reticle page
  ///
  /// In en, this message translates to:
  /// **'Holdovers'**
  String get pageHoldovers;

  /// Home screen page label for the trajectory info / table page
  ///
  /// In en, this message translates to:
  /// **'Trajectory info'**
  String get pageTrajectoryInfo;

  /// Home screen page label for the trajectory chart page
  ///
  /// In en, this message translates to:
  /// **'Trajectory chart'**
  String get pageTrajectoryChart;

  /// Section header for metric units group
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get sectionMetric;

  /// Section header for imperial units group
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get sectionImperial;

  /// Section header for commonly used units
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get sectionCommon;

  /// Section header for miscellaneous items
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sectionOther;

  /// Section header for angular units group
  ///
  /// In en, this message translates to:
  /// **'Angles'**
  String get sectionAngles;

  /// Section header for atmospheric conditions
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get sectionAtmosphere;

  /// Section header for adjustment value computed at a given distance
  ///
  /// In en, this message translates to:
  /// **'Adjustment Value at Distance'**
  String get sectionAdjustmentAtDistance;

  /// Section header for metric distance units
  ///
  /// In en, this message translates to:
  /// **'Distance metric'**
  String get sectionDistanceMetric;

  /// Section header for imperial distance units
  ///
  /// In en, this message translates to:
  /// **'Distance imperial'**
  String get sectionDistanceImperial;

  /// Settings section header for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// Settings section header for theme and appearance options
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// Settings section header for units of measurement settings
  ///
  /// In en, this message translates to:
  /// **'Units settings'**
  String get sectionUnitsSettings;

  /// Settings section header for home screen options
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get sectionHomeSettings;

  /// Settings section header for backup (export/import) options
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get sectionBackup;

  /// Settings section header for external links
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get sectionLinks;

  /// Settings section header for app version and info
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// Settings sub-section header for choosing which units to display adjustments in
  ///
  /// In en, this message translates to:
  /// **'Show units'**
  String get sectionShowAdjustmentsIn;

  /// Section header for Coriolis effect parameters (latitude, azimuth)
  ///
  /// In en, this message translates to:
  /// **'Coriolis effect'**
  String get sectionCoriolisEffect;

  /// Section header for energy data in shot details
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get sectionEnergy;

  /// Section header for trajectory data in shot details
  ///
  /// In en, this message translates to:
  /// **'Trajectory'**
  String get sectionTrajectory;

  /// Section header for gyroscopic stability (Sg) data
  ///
  /// In en, this message translates to:
  /// **'Gyroscopic stability'**
  String get sectionGyrostabilitySg;

  /// Section header for ballistic parameters in weapon wizard
  ///
  /// In en, this message translates to:
  /// **'Ballistics'**
  String get sectionBallistics;

  /// Section header for physical hardware parameters (barrel, mounting)
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get sectionHardware;

  /// Section header for click value settings in sight wizard and reticle view
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get sectionClicks;

  /// Section header for reticle parameters in sight wizard and reticle view
  ///
  /// In en, this message translates to:
  /// **'Reticle'**
  String get sectionReticle;

  /// Section header for sight mounting parameters (offsets)
  ///
  /// In en, this message translates to:
  /// **'Mounting'**
  String get sectionMounting;

  /// Section header for manual click adjustments in reticle view
  ///
  /// In en, this message translates to:
  /// **'Manual Adjustments'**
  String get sectionManualAdjustments;

  /// Section header for holdover values in reticle view
  ///
  /// In en, this message translates to:
  /// **'Holdovers'**
  String get sectionHoldovers;

  /// Section header for target image / size parameters in reticle view
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get sectionTarget;

  /// Section header for magnification settings
  ///
  /// In en, this message translates to:
  /// **'Magnification'**
  String get sectionMagnification;

  /// Trajectory table column header for distance / range
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get columnRange;

  /// Trajectory table column header for time of flight
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get columnTime;

  /// Trajectory table column header for bullet velocity
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get columnVelocity;

  /// Trajectory table column header for bullet height above bore
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get columnHeight;

  /// Trajectory table column header for vertical drop in distance units
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get columnDrop;

  /// Trajectory table column header for vertical drop in angular units (degrees)
  ///
  /// In en, this message translates to:
  /// **'Drop°'**
  String get columnDropAngle;

  /// Trajectory table column header for vertical drop in clicks
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get columnDropClicks;

  /// Trajectory table column header for horizontal wind drift in distance units
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get columnWind;

  /// Trajectory table column header for wind drift in angular units (degrees)
  ///
  /// In en, this message translates to:
  /// **'Wind°'**
  String get columnWindAngle;

  /// Trajectory table column header for wind drift in clicks
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get columnWindClicks;

  /// Trajectory table column header for Mach number
  ///
  /// In en, this message translates to:
  /// **'Mach'**
  String get columnMach;

  /// Trajectory table column header for drag coefficient
  ///
  /// In en, this message translates to:
  /// **'Drag'**
  String get columnDrag;

  /// Trajectory table column header for kinetic energy
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get columnEnergy;

  /// Trajectory table column header for elevation
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get columnElevation;

  /// Tables config section header for distance/range settings
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get tablesConfigSectionDistance;

  /// Tables config field label for trajectory start distance
  ///
  /// In en, this message translates to:
  /// **'Start distance'**
  String get tablesConfigDistanceStart;

  /// Tables config field label for trajectory end distance
  ///
  /// In en, this message translates to:
  /// **'End distance'**
  String get tablesConfigDistanceEnd;

  /// Tables config field label for distance increment between rows
  ///
  /// In en, this message translates to:
  /// **'Distance step'**
  String get tablesConfigDistanceStep;

  /// Tables config section header for extra display options
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get tablesConfigSectionExtra;

  /// Tables config toggle to display the zero crossings table
  ///
  /// In en, this message translates to:
  /// **'Show zero crossings table'**
  String get tablesConfigShowZeroCrossingTable;

  /// Tables config toggle to highlight subsonic transition row
  ///
  /// In en, this message translates to:
  /// **'Show subsonic transition'**
  String get tablesConfigShowSubsonicTransition;

  /// Tables config section header for choosing which columns to show
  ///
  /// In en, this message translates to:
  /// **'Visible columns'**
  String get tablesConfigSectionVisibleColumns;

  /// Tables config section header for adjustment column unit selection
  ///
  /// In en, this message translates to:
  /// **'Adjustment columns'**
  String get tablesConfigSectionAdjustmentColumns;

  /// Tables screen section title for the main trajectory table
  ///
  /// In en, this message translates to:
  /// **'Trajectory'**
  String get tablesSectionTrajectory;

  /// Tables screen section title for the zero crossings table
  ///
  /// In en, this message translates to:
  /// **'Zero Crossings'**
  String get tablesSectionZeroCrossing;

  /// Unit name: millimeters
  ///
  /// In en, this message translates to:
  /// **'Millimeters'**
  String get unitMillimeters;

  /// Unit name: centimeters
  ///
  /// In en, this message translates to:
  /// **'Centimeters'**
  String get unitCentimeters;

  /// Unit name: meters
  ///
  /// In en, this message translates to:
  /// **'Meters'**
  String get unitMeters;

  /// Unit name: inches
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get unitInches;

  /// Unit name: feet
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get unitFeet;

  /// Unit name: yards
  ///
  /// In en, this message translates to:
  /// **'Yards'**
  String get unitYards;

  /// Unit name: grams
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get unitGrams;

  /// Unit name: kilograms
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get unitKilograms;

  /// Unit name: grains (weight)
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get unitGrains;

  /// Unit name: pounds
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get unitPounds;

  /// Unit name: ounces
  ///
  /// In en, this message translates to:
  /// **'Ounces'**
  String get unitOunces;

  /// Unit name: standard atmosphere (atm)
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get unitAtmosphere;

  /// Unit abbreviation: hectopascal
  ///
  /// In en, this message translates to:
  /// **'hPa'**
  String get unitHPa;

  /// Unit name: bar (pressure)
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get unitBar;

  /// Unit abbreviation: pounds per square inch
  ///
  /// In en, this message translates to:
  /// **'PSI'**
  String get unitPsi;

  /// Unit abbreviation: inches of mercury
  ///
  /// In en, this message translates to:
  /// **'inHg'**
  String get unitInHg;

  /// Unit abbreviation: millimeters of mercury
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get unitMmHg;

  /// Unit name: degrees Celsius
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get unitCelsius;

  /// Unit name: degrees Fahrenheit
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get unitFahrenheit;

  /// Unit name: Newton-meter (torque)
  ///
  /// In en, this message translates to:
  /// **'Newton-meter'**
  String get unitNewtonMeter;

  /// Unit name: foot-pound (torque or energy)
  ///
  /// In en, this message translates to:
  /// **'Foot-pound'**
  String get unitFootPound;

  /// Unit name: inch-pound (torque)
  ///
  /// In en, this message translates to:
  /// **'Inch-pound'**
  String get unitInchPound;

  /// Unit name: meters per second (velocity)
  ///
  /// In en, this message translates to:
  /// **'Meters per second'**
  String get unitMps;

  /// Unit name: kilometers per hour
  ///
  /// In en, this message translates to:
  /// **'Kilometers per hour'**
  String get unitKmh;

  /// Unit name: feet per second (velocity)
  ///
  /// In en, this message translates to:
  /// **'Feet per second'**
  String get unitFps;

  /// Unit name: miles per hour
  ///
  /// In en, this message translates to:
  /// **'Miles per hour'**
  String get unitMph;

  /// Unit name: Mach number (ratio to speed of sound)
  ///
  /// In en, this message translates to:
  /// **'Mach'**
  String get unitMach;

  /// Unit name: Mach calculated using ICAO standard atmosphere
  ///
  /// In en, this message translates to:
  /// **'Mach (ICAO)'**
  String get unitMachIcao;

  /// Unit name: Mach calculated using custom atmosphere conditions
  ///
  /// In en, this message translates to:
  /// **'Mach (custom atmo)'**
  String get unitMachCustom;

  /// Unit abbreviation: milliradians (MIL)
  ///
  /// In en, this message translates to:
  /// **'MIL'**
  String get unitMil;

  /// Unit abbreviation: minutes of angle
  ///
  /// In en, this message translates to:
  /// **'MOA'**
  String get unitMoa;

  /// Unit abbreviation: milliradians (MRAD)
  ///
  /// In en, this message translates to:
  /// **'MRAD'**
  String get unitMrad;

  /// Unit: centimeters per 100 meters (angular spread)
  ///
  /// In en, this message translates to:
  /// **'cm/100m'**
  String get unitCmPer100m;

  /// Unit: inches per 100 yards (angular spread)
  ///
  /// In en, this message translates to:
  /// **'in/100yd'**
  String get unitInPer100Yd;

  /// Unit name: degrees (angle)
  ///
  /// In en, this message translates to:
  /// **'Degrees'**
  String get unitDegrees;

  /// Unit name: scope adjustment clicks
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get unitClicks;

  /// Pluralized click count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{click} other{clicks}}'**
  String nClicks(int count);

  /// Unit name: joule (energy)
  ///
  /// In en, this message translates to:
  /// **'Joule'**
  String get unitJoule;

  /// Unit symbol: millimeter
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get unitMillimeterSym;

  /// Unit symbol: centimeter
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCentimeterSym;

  /// Unit symbol: meter
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMeterSym;

  /// Unit symbol: inch
  ///
  /// In en, this message translates to:
  /// **'inch'**
  String get unitInchSym;

  /// Unit symbol: foot
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get unitFootSym;

  /// Unit symbol: yard
  ///
  /// In en, this message translates to:
  /// **'yd'**
  String get unitYardSym;

  /// Unit symbol: grain
  ///
  /// In en, this message translates to:
  /// **'gr'**
  String get unitGrainSym;

  /// Unit symbol: gram
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGramSym;

  /// Unit symbol: kilogram
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKilogramSym;

  /// Unit symbol: pound
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitPoundSym;

  /// Unit symbol: ounce
  ///
  /// In en, this message translates to:
  /// **'oz'**
  String get unitOunceSym;

  /// Unit symbol: meters per second
  ///
  /// In en, this message translates to:
  /// **'m/s'**
  String get unitMpsSym;

  /// Unit symbol: feet per second
  ///
  /// In en, this message translates to:
  /// **'ft/s'**
  String get unitFpsSym;

  /// Unit symbol: kilometers per hour
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKmhSym;

  /// Unit symbol: miles per hour
  ///
  /// In en, this message translates to:
  /// **'mph'**
  String get unitMphSym;

  /// Unit symbol: Mach number
  ///
  /// In en, this message translates to:
  /// **'Mach'**
  String get unitMachSym;

  /// Unit symbol: joule
  ///
  /// In en, this message translates to:
  /// **'J'**
  String get unitJouleSym;

  /// Unit symbol: foot-pound
  ///
  /// In en, this message translates to:
  /// **'ft·lb'**
  String get unitFootPoundSym;

  /// Unit symbol: newton-meter
  ///
  /// In en, this message translates to:
  /// **'N·m'**
  String get unitNewtonMeterSym;

  /// Unit symbol: inch-pound
  ///
  /// In en, this message translates to:
  /// **'in·lb'**
  String get unitInchPoundSym;

  /// Unit symbol: hectopascal
  ///
  /// In en, this message translates to:
  /// **'hPa'**
  String get unitHPaSym;

  /// Unit symbol: millimeters of mercury
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get unitMmHgSym;

  /// Unit symbol: inches of mercury
  ///
  /// In en, this message translates to:
  /// **'inHg'**
  String get unitInHgSym;

  /// Unit symbol: pounds per square inch
  ///
  /// In en, this message translates to:
  /// **'psi'**
  String get unitPsiSym;

  /// Unit symbol: bar (pressure)
  ///
  /// In en, this message translates to:
  /// **'bar'**
  String get unitBarSym;

  /// Unit symbol: standard atmosphere
  ///
  /// In en, this message translates to:
  /// **'atm'**
  String get unitAtmSym;

  /// Unit symbol: degrees Celsius
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get unitCelsiusSym;

  /// Unit symbol: degrees Fahrenheit
  ///
  /// In en, this message translates to:
  /// **'°F'**
  String get unitFahrenheitSym;

  /// Unit symbol: milliradians (MIL)
  ///
  /// In en, this message translates to:
  /// **'MIL'**
  String get unitMilSym;

  /// Unit symbol: minutes of angle
  ///
  /// In en, this message translates to:
  /// **'MOA'**
  String get unitMoaSym;

  /// Unit symbol: milliradians (MRAD)
  ///
  /// In en, this message translates to:
  /// **'MRAD'**
  String get unitMradSym;

  /// Unit symbol: cm per 100 meters
  ///
  /// In en, this message translates to:
  /// **'cm/100m'**
  String get unitCmPer100mSym;

  /// Unit symbol: inches per 100 yards
  ///
  /// In en, this message translates to:
  /// **'in/100yd'**
  String get unitInPer100YdSym;

  /// Unit symbol: degrees (angle)
  ///
  /// In en, this message translates to:
  /// **'°'**
  String get unitDegreesSym;

  /// Unit symbol: seconds (time)
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSecondSym;

  /// Hint text for a length input field in converters
  ///
  /// In en, this message translates to:
  /// **'Enter length'**
  String get enterLength;

  /// Hint text for a weight input field in converters
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// Hint text for a pressure input field in converters
  ///
  /// In en, this message translates to:
  /// **'Enter pressure'**
  String get enterPressure;

  /// Hint text for a temperature input field in converters
  ///
  /// In en, this message translates to:
  /// **'Enter temperature'**
  String get enterTemperature;

  /// Hint text for a torque input field in converters
  ///
  /// In en, this message translates to:
  /// **'Enter torque'**
  String get enterTorque;

  /// Hint text for a velocity input field in converters
  ///
  /// In en, this message translates to:
  /// **'Enter velocity'**
  String get enterVelocity;

  /// Label for the distance input section in the angular converter
  ///
  /// In en, this message translates to:
  /// **'Distance Input'**
  String get inputDistance;

  /// Label for the angle input section in the angular converter
  ///
  /// In en, this message translates to:
  /// **'Angle Input'**
  String get inputAngle;

  /// Label for the output unit selector in converters
  ///
  /// In en, this message translates to:
  /// **'Output Unit'**
  String get outputUnit;

  /// Label for the target size input in the target distance converter
  ///
  /// In en, this message translates to:
  /// **'Target Size'**
  String get inputTargetSize;

  /// Label for the angular size input in the target distance converter
  ///
  /// In en, this message translates to:
  /// **'Angular Size'**
  String get inputAngularSize;

  /// Label for the custom atmosphere toggle option
  ///
  /// In en, this message translates to:
  /// **'Custom atmosphere'**
  String get customAtmosphere;

  /// Status indicator: custom atmospheric conditions are active
  ///
  /// In en, this message translates to:
  /// **'Using custom conditions'**
  String get usingCustomConditions;

  /// Status indicator: ICAO standard atmosphere is active
  ///
  /// In en, this message translates to:
  /// **'Using ICAO standard atmosphere'**
  String get usingIcaoAtmosphere;

  /// Button label to save changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Button label to discard unsaved changes and cancel
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// Button label to close a dialog or panel
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Button label to confirm an action (OK / Yes)
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// Button label to proceed to the next step in a multi-step dialog
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Button label to dismiss / cancel a dialog without saving
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissButton;

  /// Button label to print / export as PDF
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printButton;

  /// Button label / tooltip for the help action
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpButton;

  /// Help dialog title
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// Button label to confirm a selection
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectButton;

  /// Tooltip for the back navigation button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// Tooltip for the configure / settings icon button
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get tooltipConfigure;

  /// Tooltip for the share icon button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// Context action label to edit an item
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// Context action label to duplicate / copy an item
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateAction;

  /// Context action label to export an item
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// Context action label to import an item
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// Context action button label in confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// Context action label to create a new item
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// Action sheet item label to create a brand-new item
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNewAction;

  /// Verb used in confirmation dialog body text (e.g. 'Remove "item name"?')
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Sheet / menu title for the context actions list
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Action to add / import ammo into the current profile
  ///
  /// In en, this message translates to:
  /// **'Add Ammo'**
  String get actionAddAmmo;

  /// Action to add / import a sight into the current profile
  ///
  /// In en, this message translates to:
  /// **'Add Sight'**
  String get actionAddSight;

  /// Settings action to export a full backup of all data
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExportBackup;

  /// Settings action to import a full backup
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImportBackup;

  /// Action sheet item to import an entity from a file
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get actionImportFromFile;

  /// Action sheet item to pick a sight from the built-in collection
  ///
  /// In en, this message translates to:
  /// **'Select sight from collection'**
  String get actionSelectSightFromCollection;

  /// Action sheet item to pick a cartridge from the built-in collection
  ///
  /// In en, this message translates to:
  /// **'Select cartridge from collection'**
  String get selectCartridgeFromCollection;

  /// Action sheet item to pick a bullet from the built-in collection
  ///
  /// In en, this message translates to:
  /// **'Select bullet from collection'**
  String get selectBulletFromCollection;

  /// Button to navigate from a profile to the home/calculations screen
  ///
  /// In en, this message translates to:
  /// **'Go to calculations'**
  String get goToCalculationsButton;

  /// Settings label for the app theme selector
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme option: follow system dark/light mode
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option: always dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme option: always light mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Label for the adjustment direction indicator format selector (arrows / signs / letters)
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get adjustmentDisplayFormat;

  /// Title for the units of measurement settings screen
  ///
  /// In en, this message translates to:
  /// **'Units of Measurement'**
  String get unitsSettingsLabel;

  /// Settings toggle label to display the subsonic transition marker on the trajectory chart
  ///
  /// In en, this message translates to:
  /// **'Show subsonic transition'**
  String get switchShowSubsonicTransition;

  /// Subtitle for the subsonic transition toggle
  ///
  /// In en, this message translates to:
  /// **'Displays on trajectory chart'**
  String get switchShowSubsonicTransitionSubtitle;

  /// Settings label for the trajectory table row distance increment
  ///
  /// In en, this message translates to:
  /// **'Table distance step'**
  String get labelTrajectoryTableStep;

  /// Settings label for the trajectory chart distance increment
  ///
  /// In en, this message translates to:
  /// **'Chart distance step'**
  String get labelTrajectoryChartStep;

  /// Settings link label for Terms of Use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get labelTermsOfUse;

  /// Settings link label for Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get labelPrivacyPolicy;

  /// Settings label showing the current app version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// Settings link label for the changelog
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get labelChangelog;

  /// Settings label for the velocity unit selector
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get labelVelocity;

  /// Settings label for the distance unit selector
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get labelDistance;

  /// Settings label for the sight height unit selector
  ///
  /// In en, this message translates to:
  /// **'Sight Height'**
  String get labelSightHeight;

  /// Settings label for the pressure unit selector
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get labelPressure;

  /// Settings label for the temperature unit selector
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get labelTemperature;

  /// Settings label for the drop and windage display unit selector (distance units)
  ///
  /// In en, this message translates to:
  /// **'Drop / Windage'**
  String get labelDropWindage;

  /// Settings label for the drop and windage angular unit selector
  ///
  /// In en, this message translates to:
  /// **'Drop / Windage angle'**
  String get labelDropWindageAngle;

  /// Settings label for the energy unit selector
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get labelEnergy;

  /// Settings label for the projectile weight unit selector
  ///
  /// In en, this message translates to:
  /// **'Projectile Weight'**
  String get labelProjectileWeight;

  /// Settings label for the projectile length unit selector
  ///
  /// In en, this message translates to:
  /// **'Projectile Length'**
  String get labelProjectileLength;

  /// Settings label for the projectile diameter unit selector
  ///
  /// In en, this message translates to:
  /// **'Projectile Diameter'**
  String get labelProjectileDiameter;

  /// Label for the target size field in reticle view
  ///
  /// In en, this message translates to:
  /// **'Target size'**
  String get labelTargetSize;

  /// Section / field label for a weapon entity
  ///
  /// In en, this message translates to:
  /// **'Weapon'**
  String get weapon;

  /// Input field label for the weapon name
  ///
  /// In en, this message translates to:
  /// **'Weapon name'**
  String get weaponName;

  /// Field label for the caliber of the weapon
  ///
  /// In en, this message translates to:
  /// **'Caliber'**
  String get caliber;

  /// Input field label for a custom caliber name
  ///
  /// In en, this message translates to:
  /// **'Caliber name'**
  String get caliberName;

  /// Field label for the barrel rifling twist rate
  ///
  /// In en, this message translates to:
  /// **'Twist'**
  String get twistRate;

  /// Field label for the barrel twist direction (left / right hand)
  ///
  /// In en, this message translates to:
  /// **'Twist direction'**
  String get twistDirection;

  /// Twist direction value: right-hand (clockwise) twist
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get rightHand;

  /// Twist direction value: left-hand (counter-clockwise) twist
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get leftHand;

  /// Field label for the barrel length parameter
  ///
  /// In en, this message translates to:
  /// **'Barrel length'**
  String get barrelLength;

  /// Field label for the sight height above bore (mounting height)
  ///
  /// In en, this message translates to:
  /// **'Sight height'**
  String get sightHeight;

  /// Field label for the zeroing distance
  ///
  /// In en, this message translates to:
  /// **'Zero distance'**
  String get zeroDistance;

  /// Section / field label for manual scope drum adjustments
  ///
  /// In en, this message translates to:
  /// **'Manual adjustments'**
  String get drumAdjustment;

  /// Field label for the manufacturer / vendor name
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// Section / field label for a cartridge entity
  ///
  /// In en, this message translates to:
  /// **'Cartridge'**
  String get cartridge;

  /// Input field label for the cartridge name
  ///
  /// In en, this message translates to:
  /// **'Cartridge name'**
  String get cartridgeName;

  /// Section / field label for an ammo entity (complete round)
  ///
  /// In en, this message translates to:
  /// **'Ammo'**
  String get ammo;

  /// Input field label for the ammo name
  ///
  /// In en, this message translates to:
  /// **'Ammo name'**
  String get ammoName;

  /// Field label for the muzzle velocity used during zeroing
  ///
  /// In en, this message translates to:
  /// **'Zero MV'**
  String get zeroMv;

  /// Field label for the current (shooting day) muzzle velocity
  ///
  /// In en, this message translates to:
  /// **'Current MV'**
  String get currentMv;

  /// Label for muzzle velocity shown in profile sections
  ///
  /// In en, this message translates to:
  /// **'Muzzle velocity'**
  String get muzzleVelocity;

  /// Section / field label for a projectile / bullet entity
  ///
  /// In en, this message translates to:
  /// **'Projectile'**
  String get projectile;

  /// Input field label for the projectile name
  ///
  /// In en, this message translates to:
  /// **'Projectile name'**
  String get projectileName;

  /// Field label for the ballistic drag model (G1, G7, Custom)
  ///
  /// In en, this message translates to:
  /// **'Drag model'**
  String get dragModel;

  /// Full label for ballistic coefficient
  ///
  /// In en, this message translates to:
  /// **'Ballistic coefficient'**
  String get bc;

  /// Short abbreviation for ballistic coefficient
  ///
  /// In en, this message translates to:
  /// **'BC'**
  String get bcShort;

  /// Field label for bullet / projectile length
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// Field label for bullet / projectile weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Field label for projectile form factor
  ///
  /// In en, this message translates to:
  /// **'Form factor'**
  String get formFactor;

  /// Field label for projectile sectional density
  ///
  /// In en, this message translates to:
  /// **'Sectional density'**
  String get sectionalDensity;

  /// Field label for the gyroscopic stability factor Sg
  ///
  /// In en, this message translates to:
  /// **'Gyroscopic stability factor (Sg)'**
  String get gyrostabilitySg;

  /// Short abbreviation for the gyroscopic stability factor
  ///
  /// In en, this message translates to:
  /// **'Sg'**
  String get sgAbbr;

  /// Label for a user-defined custom drag function table
  ///
  /// In en, this message translates to:
  /// **'Custom Drag Table'**
  String get customDragTable;

  /// Label for a multi-BC (velocity-dependent BC) table
  ///
  /// In en, this message translates to:
  /// **'Multi-BC Table'**
  String get multiBcTable;

  /// Footer hint in the two-column table editor (multi-BC / drag table)
  ///
  /// In en, this message translates to:
  /// **'Rows where any value is 0 are ignored on save.'**
  String get twoColumnEditorFooter;

  /// Hint text shown in the powder temperature sensitivity table editor
  ///
  /// In en, this message translates to:
  /// **'Rows with non-positive velocity are ignored.\nTemperature may be negative, zero, or positive.\nSensitivity is averaged across all valid pairs.'**
  String get nonPositiveRowsHint;

  /// Section / field label for atmospheric conditions
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// Field label for atmospheric temperature
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Field label for relative humidity
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// Field label for atmospheric pressure
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// Field label for altitude above sea level
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// Field label for propellant / powder temperature
  ///
  /// In en, this message translates to:
  /// **'Powder temperature'**
  String get powderTemperature;

  /// Field label for geographic latitude (Coriolis effect)
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// Field label for shooting azimuth (Coriolis effect)
  ///
  /// In en, this message translates to:
  /// **'Azimuth'**
  String get azimuth;

  /// Field label for wind speed
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get windSpeed;

  /// Feedback message on quick action 'Wind Speed' long press
  ///
  /// In en, this message translates to:
  /// **'Wind Speed was reset to 0'**
  String get windSpeedWasReset;

  /// Field label for wind direction
  ///
  /// In en, this message translates to:
  /// **'Wind direction'**
  String get windDirection;

  /// Section / field label for powder temperature sensitivity (MV change per temperature delta)
  ///
  /// In en, this message translates to:
  /// **'Powder temperature sensitivity'**
  String get powderSensitivity;

  /// Field label for MV change per 15°C in powder sensitivity settings
  ///
  /// In en, this message translates to:
  /// **'Velocity change per 15°C temperature delta'**
  String get velocityChangePer15C;

  /// Toggle label to enter a separate powder temperature different from ambient
  ///
  /// In en, this message translates to:
  /// **'Use different powder temperature'**
  String get useDifferentPowderTemperature;

  /// Toggle label to enable powder temperature sensitivity compensation
  ///
  /// In en, this message translates to:
  /// **'Enable powder temperature sensitivity'**
  String get usePowderSensitivity;

  /// Read-only status label: MV is calculated using powder temperature
  ///
  /// In en, this message translates to:
  /// **'Uses powder temperature'**
  String get usesPowderTemperature;

  /// Read-only status label: MV is calculated using atmospheric temperature
  ///
  /// In en, this message translates to:
  /// **'Uses atmospheric temperature'**
  String get usesAtmoTemperature;

  /// Label for the MV value corrected to powder temperature
  ///
  /// In en, this message translates to:
  /// **'Muzzle velocity at powder temperature'**
  String get mvAtPowderTemp;

  /// Label for the MV value corrected to atmospheric temperature
  ///
  /// In en, this message translates to:
  /// **'Muzzle velocity at atmospheric temperature'**
  String get mvAtAtmoTemp;

  /// Section / field label for a sight / optic entity
  ///
  /// In en, this message translates to:
  /// **'Sight'**
  String get sight;

  /// Input field label for the sight name
  ///
  /// In en, this message translates to:
  /// **'Sight name'**
  String get sightName;

  /// Label for the sight image / photo field
  ///
  /// In en, this message translates to:
  /// **'Sight Image'**
  String get sightImage;

  /// Field label for the reticle assigned to a sight
  ///
  /// In en, this message translates to:
  /// **'Reticle'**
  String get reticle;

  /// Label for the reticle SVG pattern selector
  ///
  /// In en, this message translates to:
  /// **'Reticle pattern'**
  String get reticlePattern;

  /// Label for the target SVG pattern selector
  ///
  /// In en, this message translates to:
  /// **'Target pattern'**
  String get targetPattern;

  /// Field label for the focal plane type (FFP / SFP / LWIR)
  ///
  /// In en, this message translates to:
  /// **'Focal plane'**
  String get focalPlane;

  /// Focal plane option: First Focal Plane
  ///
  /// In en, this message translates to:
  /// **'FFP'**
  String get focalPlaneFFP;

  /// Focal plane option: Second Focal Plane
  ///
  /// In en, this message translates to:
  /// **'SFP'**
  String get focalPlaneSFP;

  /// Focal plane option: Long Wave Infrared
  ///
  /// In en, this message translates to:
  /// **'LWIR'**
  String get focalPlaneLWIR;

  /// Fallback label shown when no image/pattern is selected
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get defaultLabel;

  /// Field label for optical magnification power
  ///
  /// In en, this message translates to:
  /// **'Magnification'**
  String get magnification;

  /// Field label for maximum magnification of a variable-power scope
  ///
  /// In en, this message translates to:
  /// **'Max Magnification'**
  String get maxMagnification;

  /// Field label for minimum magnification of a variable-power scope
  ///
  /// In en, this message translates to:
  /// **'Min Magnification'**
  String get minMagnification;

  /// Field label for the vertical (elevation) click value
  ///
  /// In en, this message translates to:
  /// **'Vertical click'**
  String get verticalClick;

  /// Field label for the horizontal (windage) click value
  ///
  /// In en, this message translates to:
  /// **'Horizontal click'**
  String get horizontalClick;

  /// Label for the click unit selector (MIL, MOA, MRAD, etc.)
  ///
  /// In en, this message translates to:
  /// **'Click Unit'**
  String get clickUnit;

  /// Field label for the horizontal mounting offset
  ///
  /// In en, this message translates to:
  /// **'Horizontal Offset'**
  String get horizontalOffset;

  /// Field label for the vertical mounting offset
  ///
  /// In en, this message translates to:
  /// **'Vertical Offset'**
  String get verticalOffset;

  /// Label for the adjustment unit display in reticle view
  ///
  /// In en, this message translates to:
  /// **'Adjustment Unit'**
  String get adjustmentUnit;

  /// Field label for horizontal manual adjustment in reticle view
  ///
  /// In en, this message translates to:
  /// **'Horizontal Adjustment'**
  String get horizontalAdjustment;

  /// Field label for vertical manual adjustment in reticle view
  ///
  /// In en, this message translates to:
  /// **'Vertical Adjustment'**
  String get verticalAdjustment;

  /// Button / action label to open the reticle picker
  ///
  /// In en, this message translates to:
  /// **'Select Reticle'**
  String get selectReticle;

  /// Label for the calculated powder sensitivity value derived from the measurement table
  ///
  /// In en, this message translates to:
  /// **'Calculated Sensitivity'**
  String get calculatedSensitivity;

  /// Placeholder shown when the sensitivity measurement table is empty
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get noMeasurementsYet;

  /// Field label for the target look angle (inclination / slope)
  ///
  /// In en, this message translates to:
  /// **'Look angle'**
  String get lookAngle;

  /// Feedback message on quick action 'Look Angle' long press
  ///
  /// In en, this message translates to:
  /// **'Look angle was reset to 0°'**
  String get lookAngleWasReset;

  /// Field label for the distance to the target
  ///
  /// In en, this message translates to:
  /// **'Target range'**
  String get targetRange;

  /// Label for the speed of sound value in shot details
  ///
  /// In en, this message translates to:
  /// **'Speed of sound'**
  String get speedOfSound;

  /// Label for the bullet velocity at the target distance
  ///
  /// In en, this message translates to:
  /// **'Velocity at target'**
  String get velocityAtTarget;

  /// Label for the kinetic energy at the target distance
  ///
  /// In en, this message translates to:
  /// **'Energy at target'**
  String get energyAtTarget;

  /// Label for the kinetic energy at the muzzle
  ///
  /// In en, this message translates to:
  /// **'Energy at muzzle velocity'**
  String get energyAtMuzzle;

  /// Label for the maximum height of the trajectory (apex)
  ///
  /// In en, this message translates to:
  /// **'Trajectory apex'**
  String get apexHeight;

  /// Label for the horizontal distance at which the trajectory reaches its apex
  ///
  /// In en, this message translates to:
  /// **'Trajectory apex distance'**
  String get apexDistance;

  /// Label for wind-induced horizontal drift
  ///
  /// In en, this message translates to:
  /// **'Windage'**
  String get windage;

  /// Label for the time of flight to the target
  ///
  /// In en, this message translates to:
  /// **'Time to target'**
  String get timeToTarget;

  /// Adjustment panel header for vertical holdover
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get holdoversVertical;

  /// Adjustment panel header for horizontal windage holdover
  ///
  /// In en, this message translates to:
  /// **'Windage'**
  String get holdoversHorizontal;

  /// Error message shown in the adjustment panel when no adjustment unit is configured
  ///
  /// In en, this message translates to:
  /// **'Adjustment Display disabled!'**
  String get adjustmentDisplayDisabled;

  /// Button label to navigate to adjustment settings from the disabled-panel state
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get adjustmentDisplayDisabledHint;

  /// Section label for additional/miscellaneous parameters in ammo wizard
  ///
  /// In en, this message translates to:
  /// **'Additional parameters'**
  String get additionalParameters;

  /// Subtitle for the additional parameters section (hints at barrel length)
  ///
  /// In en, this message translates to:
  /// **'Barrel length, etc.'**
  String get additionalParametersBarelLen;

  /// Warning shown when selected ammo caliber does not match the weapon caliber
  ///
  /// In en, this message translates to:
  /// **'Ammo caliber differs from weapon caliber'**
  String get caliberMatchingError;

  /// Default name for a newly created sight
  ///
  /// In en, this message translates to:
  /// **'New Sight'**
  String get newSight;

  /// Default name for a newly created profile
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get newProfile;

  /// Default name for a newly created ammo entry
  ///
  /// In en, this message translates to:
  /// **'New Ammo'**
  String get newAmmo;

  /// Default name for a newly created cartridge
  ///
  /// In en, this message translates to:
  /// **'New Cartridge'**
  String get newCartridge;

  /// Default name for a newly created projectile
  ///
  /// In en, this message translates to:
  /// **'New Projectile'**
  String get newProjectile;

  /// Default name for a newly created bullet
  ///
  /// In en, this message translates to:
  /// **'New Bullet'**
  String get newBullet;

  /// Prefix prepended to the name when duplicating an entity (e.g. 'Copy of My Ammo')
  ///
  /// In en, this message translates to:
  /// **'Copy of'**
  String get copyOf;

  /// Screen title / action label when editing an existing profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Input field label for the profile name
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// Dialog title for renaming a profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Name'**
  String get editProfileName;

  /// Action label to select / activate a profile
  ///
  /// In en, this message translates to:
  /// **'Select Profile'**
  String get selectProfile;

  /// Action label to delete a profile
  ///
  /// In en, this message translates to:
  /// **'Remove Profile'**
  String get removeProfile;

  /// Empty-state message shown when the profile list is empty
  ///
  /// In en, this message translates to:
  /// **'No profiles. Tap + to add one.'**
  String get noProfiles;

  /// Error message when importing a file that contains no sight data
  ///
  /// In en, this message translates to:
  /// **'No sights found in file'**
  String get noSightsFoundInFile;

  /// Dialog title for confirming ammo duplication
  ///
  /// In en, this message translates to:
  /// **'Duplicate Ammo'**
  String get ammoDuplicateDialogTitle;

  /// Dialog title for confirming ammo removal
  ///
  /// In en, this message translates to:
  /// **'Remove Ammo'**
  String get ammoRemoveDialogTitle;

  /// Dialog title for confirming sight duplication
  ///
  /// In en, this message translates to:
  /// **'Duplicate Sight'**
  String get sightDuplicateDialogTitle;

  /// Dialog title for confirming sight removal
  ///
  /// In en, this message translates to:
  /// **'Remove Sight'**
  String get sightRemoveDialogTitle;

  /// Hint shown on the profile card when neither ammo nor sight is selected
  ///
  /// In en, this message translates to:
  /// **'Select ammo and sight first'**
  String get selectAmmoSightHint;

  /// Hint shown on the profile card when no sight is selected
  ///
  /// In en, this message translates to:
  /// **'Select sight'**
  String get selectSightHint;

  /// Hint shown on the profile card when no ammo is selected
  ///
  /// In en, this message translates to:
  /// **'Select ammo'**
  String get selectAmmoHint;

  /// Placeholder text for search input fields
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get placeholderSearch;

  /// Placeholder text for features not yet implemented
  ///
  /// In en, this message translates to:
  /// **'not yet available'**
  String get notYetAvaliable;

  /// Validation error message for required input fields
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredFieldError;

  /// Error when no zero crossing exists within the computed trajectory range
  ///
  /// In en, this message translates to:
  /// **'Zero crossings not found in the current trajectory range!'**
  String get errorZeroCrossingNotFound;

  /// Error message when importing a backup file fails
  ///
  /// In en, this message translates to:
  /// **'Backup import failed'**
  String get errorImportBackupFailed;

  /// Error message when importing a file that contains no ammo data
  ///
  /// In en, this message translates to:
  /// **'No ammo found in file'**
  String get errorNoAmmoFoundInFile;

  /// Generic error message when an import operation fails
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get errorImportFailed;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Section header for zeroing parameters in ammo wizard
  ///
  /// In en, this message translates to:
  /// **'Zeroing'**
  String get sectionZeroing;

  /// Action label to calculate powder sensitivity from the measurement table
  ///
  /// In en, this message translates to:
  /// **'Calculate from measurements'**
  String get calculateFromMeasurementsAction;

  /// SnackBar action label to update caliber to match weapon caliber
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// List tile title to open the custom drag table editor
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Drag Table'**
  String get editCustomDragTableTitle;

  /// Switch tile title to enable multi-BC mode for a given drag model
  ///
  /// In en, this message translates to:
  /// **'Enable {model} Multi-BC'**
  String enableMultiBcTitle(String model);

  /// List tile title to open the multi-BC table editor for a given drag model
  ///
  /// In en, this message translates to:
  /// **'Edit {model} Multi-BC table'**
  String editMultiBcTableTitle(String model);

  /// Field label for the ballistic coefficient of a given drag model
  ///
  /// In en, this message translates to:
  /// **'Ballistic coefficient {model}'**
  String ballisticCoefficientLabel(String model);

  /// Field label for the powder temperature at the time MV was measured
  ///
  /// In en, this message translates to:
  /// **'Muzzle velocity temperature'**
  String get mvTemperatureLabel;

  /// Subtitle for the MV temperature field
  ///
  /// In en, this message translates to:
  /// **'Powder temperature at the time of measurement'**
  String get mvTemperatureSubtitle;

  /// Subtitle for the muzzle velocity field indicating it is measured or vendor-provided
  ///
  /// In en, this message translates to:
  /// **'Measured / Vendor provided'**
  String get measuredOrVendorSubtitle;

  /// Subtitle for the zeroing distance input field
  ///
  /// In en, this message translates to:
  /// **'Zeroing distance'**
  String get zeroingDistanceSubtitle;

  /// Subtitle for the zeroing look angle input field
  ///
  /// In en, this message translates to:
  /// **'Zeroing look angle'**
  String get zeroingLookAngleSubtitle;

  /// Subtitle for the zeroing temperature input field
  ///
  /// In en, this message translates to:
  /// **'Zeroing atmospheric temperature'**
  String get zeroingTemperatureSubtitle;

  /// Subtitle for the zeroing pressure input field
  ///
  /// In en, this message translates to:
  /// **'Zeroing atmospheric pressure'**
  String get zeroingPressureSubtitle;

  /// Subtitle for the zeroing humidity input field
  ///
  /// In en, this message translates to:
  /// **'Zeroing atmospheric humidity'**
  String get zeroingHumiditySubtitle;

  /// Subtitle for the zeroing altitude input field
  ///
  /// In en, this message translates to:
  /// **'Zeroing altitude'**
  String get zeroingAltitudeSubtitle;

  /// Unit suffix for powder temperature sensitivity values
  ///
  /// In en, this message translates to:
  /// **'%/15°C'**
  String get powderSensUnit;

  /// Action sheet title when choosing how to add a new profile
  ///
  /// In en, this message translates to:
  /// **'Add Profile'**
  String get addProfileDialogTitle;

  /// Action sheet item to create a profile using a weapon from the built-in collection
  ///
  /// In en, this message translates to:
  /// **'From collection'**
  String get fromCollectionAction;

  /// Confirmation dialog body when removing a profile and its associated weapon
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" and its weapon?'**
  String removeProfileContent(String name);

  /// Action sheet title for choosing the export file format
  ///
  /// In en, this message translates to:
  /// **'Export format'**
  String get exportFormatDialogTitle;

  /// Action sheet title for choosing the trajectory range when exporting to .a7p
  ///
  /// In en, this message translates to:
  /// **'Select range'**
  String get selectRangeDialogTitle;

  /// Range option: subsonic (25–400 m)
  ///
  /// In en, this message translates to:
  /// **'Subsonic'**
  String get rangeSubsonic;

  /// Range option: low / short range (100–700 m)
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get rangeLow;

  /// Range option: medium range (100–1000 m)
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get rangeMiddle;

  /// Range option: long range (100–1700 m)
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get rangeLong;

  /// Range option: ultra long range (100–2000 m)
  ///
  /// In en, this message translates to:
  /// **'Ultra long'**
  String get rangeUltraLong;

  /// SnackBar message shown when a newer GitHub release exists
  ///
  /// In en, this message translates to:
  /// **'New version {version} is available'**
  String updateAvailable(String version);

  /// SnackBar action button label to open the GitHub release page
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewReleaseAction;

  /// Button label to open the Google Play Store page for the update
  ///
  /// In en, this message translates to:
  /// **'Open in Google Play'**
  String get openInPlayStoreAction;

  /// Button label to download and sideload the APK update
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get downloadAndInstallAction;

  /// Progress label shown while downloading the APK
  ///
  /// In en, this message translates to:
  /// **'Downloading… {progress}%'**
  String downloadingUpdate(int progress);

  /// Label shown while the APK installer is running
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get installingUpdate;

  /// Error message shown when APK download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed. Tap to retry.'**
  String get downloadFailed;

  /// Settings list tile label for the manual update check button
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdatesLabel;

  /// SnackBar message shown when no newer version is available
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get upToDateMessage;

  /// Title of the filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// Button label to reset all active filters
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterResetAction;

  /// Label for the minimum weight filter input
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get filterWeightMin;

  /// Label for the maximum weight filter input
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get filterWeightMax;

  /// Button label to apply the current filter selection
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApplyAction;

  /// Settings section header for collection management
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get sectionCollection;

  /// Settings tile label showing the current collection commit SHA
  ///
  /// In en, this message translates to:
  /// **'Collection version'**
  String get collectionVersionLabel;

  /// Settings tile label for manual collection update check
  ///
  /// In en, this message translates to:
  /// **'Update collection'**
  String get checkForCollectionUpdatesLabel;

  /// Snackbar shown after a successful collection download
  ///
  /// In en, this message translates to:
  /// **'Collection updated'**
  String get collectionUpdatedMessage;

  /// Snackbar shown when no collection update is available
  ///
  /// In en, this message translates to:
  /// **'Collection is up to date'**
  String get collectionUpToDateMessage;

  /// Title of the caliber mismatch action sheet
  ///
  /// In en, this message translates to:
  /// **'Caliber mismatch'**
  String get caliberMismatchTitle;

  /// Subtitle showing ammo vs weapon caliber values in mismatch sheet
  ///
  /// In en, this message translates to:
  /// **'Ammo: {ammo} · Weapon: {weapon}'**
  String caliberMismatchWarning(String ammo, String weapon);

  /// Action sheet option to set the ammo caliber to match the weapon
  ///
  /// In en, this message translates to:
  /// **'Update ammo caliber'**
  String get updateAmmoCaliberAction;

  /// Action sheet option to set the weapon caliber to match the ammo
  ///
  /// In en, this message translates to:
  /// **'Update weapon caliber'**
  String get updateWeaponCaliberAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
