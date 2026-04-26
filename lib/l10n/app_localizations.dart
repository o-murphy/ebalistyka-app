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

  /// No description provided for @convertorsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Convertor'**
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

  /// No description provided for @atmoTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get atmoTemperature;

  /// No description provided for @atmoPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get atmoPressure;

  /// No description provided for @atmoHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get atmoHumidity;

  /// No description provided for @atmoAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get atmoAltitude;

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
