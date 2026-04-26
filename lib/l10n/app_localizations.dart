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

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitsImperial;
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
