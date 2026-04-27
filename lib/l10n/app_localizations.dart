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

  /// No description provided for @homeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeScreenTitle;

  /// No description provided for @conditionsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditionsScreenTitle;

  /// Title of the tables screen
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tablesScreenTitle;

  /// No description provided for @tableConfigScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Table Configuration'**
  String get tableConfigScreenTitle;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @convertorsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Convertors'**
  String get convertorsScreenTitle;

  /// No description provided for @lengthConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Length Converter'**
  String get lengthConvertorTitle;

  /// No description provided for @weightConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight Converter'**
  String get weightConvertorTitle;

  /// No description provided for @pressureConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Pressure Converter'**
  String get pressureConvertorTitle;

  /// No description provided for @temperatureConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Temperature Converter'**
  String get temperatureConvertorTitle;

  /// No description provided for @torqueConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Torque Converter'**
  String get torqueConvertorTitle;

  /// No description provided for @velocityConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Velocity Converter'**
  String get velocityConvertorTitle;

  /// No description provided for @anglesConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Angles Converter'**
  String get anglesConvertorTitle;

  /// No description provided for @targetDistanceConvertorTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Distance'**
  String get targetDistanceConvertorTitle;

  /// No description provided for @enterLength.
  ///
  /// In en, this message translates to:
  /// **'Enter length'**
  String get enterLength;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// No description provided for @enterPressure.
  ///
  /// In en, this message translates to:
  /// **'Enter pressure'**
  String get enterPressure;

  /// No description provided for @enterTemperature.
  ///
  /// In en, this message translates to:
  /// **'Enter temperature'**
  String get enterTemperature;

  /// No description provided for @enterTorque.
  ///
  /// In en, this message translates to:
  /// **'Enter torque'**
  String get enterTorque;

  /// No description provided for @enterVelocity.
  ///
  /// In en, this message translates to:
  /// **'Enter velocity'**
  String get enterVelocity;

  /// No description provided for @inputDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance Input'**
  String get inputDistance;

  /// No description provided for @inputAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle Input'**
  String get inputAngle;

  /// No description provided for @outputUnit.
  ///
  /// In en, this message translates to:
  /// **'Output Unit'**
  String get outputUnit;

  /// No description provided for @inputTargetSize.
  ///
  /// In en, this message translates to:
  /// **'Target Size'**
  String get inputTargetSize;

  /// No description provided for @inputAngularSize.
  ///
  /// In en, this message translates to:
  /// **'Angular Size'**
  String get inputAngularSize;

  /// No description provided for @sectionMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get sectionMetric;

  /// No description provided for @sectionImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get sectionImperial;

  /// No description provided for @sectionCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get sectionCommon;

  /// No description provided for @sectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sectionOther;

  /// No description provided for @sectionAngles.
  ///
  /// In en, this message translates to:
  /// **'Angles'**
  String get sectionAngles;

  /// No description provided for @sectionAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get sectionAtmosphere;

  /// No description provided for @sectionAdjustmentAtDistance.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Value at Distance'**
  String get sectionAdjustmentAtDistance;

  /// No description provided for @sectionDistanceMetric.
  ///
  /// In en, this message translates to:
  /// **'Distance metric'**
  String get sectionDistanceMetric;

  /// No description provided for @sectionDistanceImperial.
  ///
  /// In en, this message translates to:
  /// **'Distance imperial'**
  String get sectionDistanceImperial;

  /// No description provided for @customAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Custom atmosphere'**
  String get customAtmosphere;

  /// No description provided for @usingCustomConditions.
  ///
  /// In en, this message translates to:
  /// **'Using custom conditions'**
  String get usingCustomConditions;

  /// No description provided for @usingIcaoAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Using ICAO standard atmosphere'**
  String get usingIcaoAtmosphere;

  /// No description provided for @unitMillimeters.
  ///
  /// In en, this message translates to:
  /// **'Millimeters'**
  String get unitMillimeters;

  /// No description provided for @unitCentimeters.
  ///
  /// In en, this message translates to:
  /// **'Centimeters'**
  String get unitCentimeters;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'Meters'**
  String get unitMeters;

  /// No description provided for @unitInches.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get unitInches;

  /// No description provided for @unitFeet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get unitFeet;

  /// No description provided for @unitYards.
  ///
  /// In en, this message translates to:
  /// **'Yards'**
  String get unitYards;

  /// No description provided for @unitGrams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get unitGrams;

  /// No description provided for @unitKilograms.
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get unitKilograms;

  /// No description provided for @unitGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get unitGrains;

  /// No description provided for @unitPounds.
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get unitPounds;

  /// No description provided for @unitOunces.
  ///
  /// In en, this message translates to:
  /// **'Ounces'**
  String get unitOunces;

  /// No description provided for @unitAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Atmosphere'**
  String get unitAtmosphere;

  /// No description provided for @unitHPa.
  ///
  /// In en, this message translates to:
  /// **'hPa'**
  String get unitHPa;

  /// No description provided for @unitBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get unitBar;

  /// No description provided for @unitPsi.
  ///
  /// In en, this message translates to:
  /// **'PSI'**
  String get unitPsi;

  /// No description provided for @unitInHg.
  ///
  /// In en, this message translates to:
  /// **'inHg'**
  String get unitInHg;

  /// No description provided for @unitMmHg.
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get unitMmHg;

  /// No description provided for @unitCelsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get unitCelsius;

  /// No description provided for @unitFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get unitFahrenheit;

  /// No description provided for @unitNewtonMeter.
  ///
  /// In en, this message translates to:
  /// **'Newton-meter'**
  String get unitNewtonMeter;

  /// No description provided for @unitFootPound.
  ///
  /// In en, this message translates to:
  /// **'Foot-pound'**
  String get unitFootPound;

  /// No description provided for @unitInchPound.
  ///
  /// In en, this message translates to:
  /// **'Inch-pound'**
  String get unitInchPound;

  /// No description provided for @unitMps.
  ///
  /// In en, this message translates to:
  /// **'Meters per second'**
  String get unitMps;

  /// No description provided for @unitKmh.
  ///
  /// In en, this message translates to:
  /// **'Kilometers per hour'**
  String get unitKmh;

  /// No description provided for @unitFps.
  ///
  /// In en, this message translates to:
  /// **'Feet per second'**
  String get unitFps;

  /// No description provided for @unitMph.
  ///
  /// In en, this message translates to:
  /// **'Miles per hour'**
  String get unitMph;

  /// No description provided for @unitMachIcao.
  ///
  /// In en, this message translates to:
  /// **'Mach (ICAO)'**
  String get unitMachIcao;

  /// No description provided for @unitMachCustom.
  ///
  /// In en, this message translates to:
  /// **'Mach (custom atmo)'**
  String get unitMachCustom;

  /// No description provided for @unitMil.
  ///
  /// In en, this message translates to:
  /// **'MIL'**
  String get unitMil;

  /// No description provided for @unitMoa.
  ///
  /// In en, this message translates to:
  /// **'MOA'**
  String get unitMoa;

  /// No description provided for @unitMrad.
  ///
  /// In en, this message translates to:
  /// **'MRAD'**
  String get unitMrad;

  /// No description provided for @unitCmPer100m.
  ///
  /// In en, this message translates to:
  /// **'cm/100m'**
  String get unitCmPer100m;

  /// No description provided for @unitInPer100Yd.
  ///
  /// In en, this message translates to:
  /// **'in/100yd'**
  String get unitInPer100Yd;

  /// No description provided for @unitDegrees.
  ///
  /// In en, this message translates to:
  /// **'Degrees'**
  String get unitDegrees;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionUnitsSettings.
  ///
  /// In en, this message translates to:
  /// **'Units settings'**
  String get sectionUnitsSettings;

  /// No description provided for @unitsSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units of Measurement'**
  String get unitsSettingsLabel;

  /// No description provided for @sectionHomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get sectionHomeSettings;

  /// No description provided for @adjustmentDisplayScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Display'**
  String get adjustmentDisplayScreenTitle;

  /// No description provided for @switchShowSubsonicTransition.
  ///
  /// In en, this message translates to:
  /// **'Show subsonic transition'**
  String get switchShowSubsonicTransition;

  /// No description provided for @switchShowSubsonicTransitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Displays on trajectory chart'**
  String get switchShowSubsonicTransitionSubtitle;

  /// No description provided for @labelTrajectoryTableStep.
  ///
  /// In en, this message translates to:
  /// **'Table distance step'**
  String get labelTrajectoryTableStep;

  /// No description provided for @labelTrajectoryChartStep.
  ///
  /// In en, this message translates to:
  /// **'Chart distance step'**
  String get labelTrajectoryChartStep;

  /// No description provided for @sectionBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get sectionBackup;

  /// No description provided for @actionExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExportBackup;

  /// No description provided for @actionImportBackup.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImportBackup;

  /// No description provided for @errorImportBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup import failed'**
  String get errorImportBackupFailed;

  /// No description provided for @sectionLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get sectionLinks;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @labelTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get labelTermsOfUse;

  /// No description provided for @labelPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get labelPrivacyPolicy;

  /// No description provided for @labelVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// No description provided for @labelChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get labelChangelog;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @adjustmentDisplayFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get adjustmentDisplayFormat;

  /// No description provided for @unitClicks.
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get unitClicks;

  /// No description provided for @sectionShowAdjustmentsIn.
  ///
  /// In en, this message translates to:
  /// **'Show units'**
  String get sectionShowAdjustmentsIn;

  /// No description provided for @labelVelocity.
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get labelVelocity;

  /// No description provided for @labelDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get labelDistance;

  /// No description provided for @labelSightHeight.
  ///
  /// In en, this message translates to:
  /// **'Sight Height'**
  String get labelSightHeight;

  /// No description provided for @labelPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get labelPressure;

  /// No description provided for @labelTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get labelTemperature;

  /// No description provided for @labelDropWindage.
  ///
  /// In en, this message translates to:
  /// **'Drop / Windage'**
  String get labelDropWindage;

  /// No description provided for @labelDropWindageAngle.
  ///
  /// In en, this message translates to:
  /// **'Drop / Windage angle'**
  String get labelDropWindageAngle;

  /// No description provided for @labelEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get labelEnergy;

  /// No description provided for @labelProjectileWeight.
  ///
  /// In en, this message translates to:
  /// **'Projectile Weight'**
  String get labelProjectileWeight;

  /// No description provided for @labelProjectileLength.
  ///
  /// In en, this message translates to:
  /// **'Projectile Length'**
  String get labelProjectileLength;

  /// No description provided for @labelProjectileDiameter.
  ///
  /// In en, this message translates to:
  /// **'Projectile Diameter'**
  String get labelProjectileDiameter;

  /// No description provided for @labelTargetSize.
  ///
  /// In en, this message translates to:
  /// **'Target size'**
  String get labelTargetSize;

  /// Tab label for trajectory table
  ///
  /// In en, this message translates to:
  /// **'Trajectory'**
  String get tabTrajectory;

  /// Tab label for details table
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tabDetails;

  /// Tooltip for configure button
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get tooltipConfigure;

  /// Tooltip for share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tooltipShare;

  /// Column header for range/distance
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get columnRange;

  /// Column header for time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get columnTime;

  /// Column header for velocity
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get columnVelocity;

  /// Column header for height
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get columnHeight;

  /// Column header for drop
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get columnDrop;

  /// Column header for drop angle in degrees
  ///
  /// In en, this message translates to:
  /// **'Drop°'**
  String get columnDropAngle;

  /// Column header for drop in clicks
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get columnDropClicks;

  /// Column header for wind
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get columnWind;

  /// Column header for wind angle in degrees
  ///
  /// In en, this message translates to:
  /// **'Wind°'**
  String get columnWindAngle;

  /// Column header for wind in clicks
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get columnWindClicks;

  /// Column header for Mach number
  ///
  /// In en, this message translates to:
  /// **'Mach'**
  String get columnMach;

  /// No description provided for @columnDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag'**
  String get columnDrag;

  /// Column header for energy
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get columnEnergy;

  /// No description provided for @tablesConfigSectionDistance.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get tablesConfigSectionDistance;

  /// No description provided for @tablesConfigDistanceStart.
  ///
  /// In en, this message translates to:
  /// **'Start distance'**
  String get tablesConfigDistanceStart;

  /// No description provided for @tablesConfigDistanceEnd.
  ///
  /// In en, this message translates to:
  /// **'End distance'**
  String get tablesConfigDistanceEnd;

  /// No description provided for @tablesConfigDistanceStep.
  ///
  /// In en, this message translates to:
  /// **'Distance step'**
  String get tablesConfigDistanceStep;

  /// No description provided for @tablesConfigSectionExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get tablesConfigSectionExtra;

  /// No description provided for @tablesConfigShowZeroCrossingTable.
  ///
  /// In en, this message translates to:
  /// **'Show zero crossings table'**
  String get tablesConfigShowZeroCrossingTable;

  /// No description provided for @tablesConfigShowSubsonicTransition.
  ///
  /// In en, this message translates to:
  /// **'Show subsonic transition'**
  String get tablesConfigShowSubsonicTransition;

  /// No description provided for @tablesConfigSectionVisibleColumns.
  ///
  /// In en, this message translates to:
  /// **'Visible columns'**
  String get tablesConfigSectionVisibleColumns;

  /// No description provided for @tablesConfigSectionAdjustmentColumns.
  ///
  /// In en, this message translates to:
  /// **'Adjustment columns'**
  String get tablesConfigSectionAdjustmentColumns;

  /// No description provided for @tablesSectionTrajectory.
  ///
  /// In en, this message translates to:
  /// **'Trajectory'**
  String get tablesSectionTrajectory;

  /// No description provided for @tablesSectionZeroCrossing.
  ///
  /// In en, this message translates to:
  /// **'Zero Crossings'**
  String get tablesSectionZeroCrossing;

  /// Weapon section title
  ///
  /// In en, this message translates to:
  /// **'Weapon'**
  String get weapon;

  /// Weapon name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Caliber field label
  ///
  /// In en, this message translates to:
  /// **'Caliber'**
  String get caliber;

  /// Twist rate field label
  ///
  /// In en, this message translates to:
  /// **'Twist'**
  String get twist;

  /// Zero distance field label
  ///
  /// In en, this message translates to:
  /// **'Zero distance'**
  String get zeroDistance;

  /// Cartridge section title
  ///
  /// In en, this message translates to:
  /// **'Cartridge'**
  String get cartridge;

  /// Zero muzzle velocity field label
  ///
  /// In en, this message translates to:
  /// **'Zero MV'**
  String get zeroMv;

  /// Current muzzle velocity field label
  ///
  /// In en, this message translates to:
  /// **'Current MV'**
  String get currentMv;

  /// Projectile section title
  ///
  /// In en, this message translates to:
  /// **'Projectile'**
  String get projectile;

  /// Drag model field label
  ///
  /// In en, this message translates to:
  /// **'Drag model'**
  String get dragModel;

  /// Ballistic coefficient field label
  ///
  /// In en, this message translates to:
  /// **'BC'**
  String get bc;

  /// Bullet length field label
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// Bullet diameter field label
  ///
  /// In en, this message translates to:
  /// **'Diameter'**
  String get diameter;

  /// Bullet weight field label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Form factor field label
  ///
  /// In en, this message translates to:
  /// **'Form factor'**
  String get formFactor;

  /// Sectional density field label
  ///
  /// In en, this message translates to:
  /// **'Sectional density'**
  String get sectionalDensity;

  /// Gyroscopic stability factor field label
  ///
  /// In en, this message translates to:
  /// **'Gyrostability (Sg)'**
  String get gyrostabilitySg;

  /// Conditions section title
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// Temperature field label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Humidity field label
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// Pressure field label
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Висота'**
  String get altitude;

  /// No description provided for @powderTemperature.
  ///
  /// In en, this message translates to:
  /// **'Powder temperature'**
  String get powderTemperature;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @azimuth.
  ///
  /// In en, this message translates to:
  /// **'Azimuth'**
  String get azimuth;

  /// Wind speed field label
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get windSpeed;

  /// Wind direction field label
  ///
  /// In en, this message translates to:
  /// **'Wind direction'**
  String get windDirection;

  /// No description provided for @powderSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Powder temperature sensitivity'**
  String get powderSensitivity;

  /// No description provided for @velocityChangePer15C.
  ///
  /// In en, this message translates to:
  /// **'Velocity change per 15°C temperature delta'**
  String get velocityChangePer15C;

  /// No description provided for @useDifferentPowderTemperature.
  ///
  /// In en, this message translates to:
  /// **'Use different powder temperature'**
  String get useDifferentPowderTemperature;

  /// No description provided for @usePowderSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Enable powder temperature sensitivity'**
  String get usePowderSensitivity;

  /// No description provided for @usesPowderTemperature.
  ///
  /// In en, this message translates to:
  /// **'Uses powder temperature'**
  String get usesPowderTemperature;

  /// No description provided for @usesAtmoTemperature.
  ///
  /// In en, this message translates to:
  /// **'Uses atmospheric temperature'**
  String get usesAtmoTemperature;

  /// No description provided for @mvAtPowderTemp.
  ///
  /// In en, this message translates to:
  /// **'Muzzle velocity at powder temperature'**
  String get mvAtPowderTemp;

  /// No description provided for @mvAtAtmoTemp.
  ///
  /// In en, this message translates to:
  /// **'Muzzle velocity at atmospheric temperature'**
  String get mvAtAtmoTemp;

  /// No description provided for @sectionCoriolisEffect.
  ///
  /// In en, this message translates to:
  /// **'Coriolis effect'**
  String get sectionCoriolisEffect;

  /// No description provided for @errorZeroCrossingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Zero crossings not found in the current trajectory range!'**
  String get errorZeroCrossingNotFound;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @discardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @printButton.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printButton;
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
