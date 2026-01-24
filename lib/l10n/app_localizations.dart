import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VRM App'**
  String get appTitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'GOOD MORNING,'**
  String get goodMorning;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Alex Rivera'**
  String get creator;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String days(String count);

  /// No description provided for @clips.
  ///
  /// In en, this message translates to:
  /// **'Clips'**
  String get clips;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @voiceControlActive.
  ///
  /// In en, this message translates to:
  /// **'Voice control active'**
  String get voiceControlActive;

  /// No description provided for @recentProjects.
  ///
  /// In en, this message translates to:
  /// **'Recent Projects'**
  String get recentProjects;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @readyToCreate.
  ///
  /// In en, this message translates to:
  /// **'Ready to create?'**
  String get readyToCreate;

  /// No description provided for @captureIdeas.
  ///
  /// In en, this message translates to:
  /// **'Capture your ideas, one fragment at a time.'**
  String get captureIdeas;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'RECORDING\nSTREAK'**
  String get streakLabel;

  /// No description provided for @fragments.
  ///
  /// In en, this message translates to:
  /// **'FRAGMENTS'**
  String get fragments;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @panel.
  ///
  /// In en, this message translates to:
  /// **'PANEL'**
  String get panel;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'VIDEOS'**
  String get videos;

  /// No description provided for @script.
  ///
  /// In en, this message translates to:
  /// **'SCRIPT'**
  String get script;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get draft;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get sat;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get progressLabel;

  /// No description provided for @editedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Edited yesterday'**
  String get editedYesterday;

  /// No description provided for @editedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Edited {count} hours ago'**
  String editedHoursAgo(String count);

  /// No description provided for @fragmentCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} Fragments'**
  String fragmentCount(String current, String total);

  /// No description provided for @newProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProjectTitle;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'STEP 1: WRITE OR PASTE YOUR SCRIPT'**
  String get step1Title;

  /// No description provided for @charactersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String charactersCount(String count);

  /// No description provided for @secondsAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsAbbreviation(String seconds);

  /// No description provided for @totalTimeEstimate.
  ///
  /// In en, this message translates to:
  /// **'approximate duration {seconds}'**
  String totalTimeEstimate(String seconds);

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'ASSISTANT'**
  String get assistant;

  /// No description provided for @optimize.
  ///
  /// In en, this message translates to:
  /// **'OPTIMIZE WITH AI'**
  String get optimize;

  /// No description provided for @fragmentPreview.
  ///
  /// In en, this message translates to:
  /// **'FRAGMENT PREVIEW'**
  String get fragmentPreview;

  /// No description provided for @blocksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} BLOCKS'**
  String blocksCount(int count);

  /// No description provided for @splitIntoFragments.
  ///
  /// In en, this message translates to:
  /// **'Split into Fragments'**
  String get splitIntoFragments;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @segment.
  ///
  /// In en, this message translates to:
  /// **'SEGMENT'**
  String get segment;

  /// No description provided for @scriptAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Script Assistant'**
  String get scriptAssistantTitle;

  /// No description provided for @defineIdea.
  ///
  /// In en, this message translates to:
  /// **'Define your Idea'**
  String get defineIdea;

  /// No description provided for @iaHelperText.
  ///
  /// In en, this message translates to:
  /// **'AI will help you structure the perfect content.'**
  String get iaHelperText;

  /// No description provided for @videoIdeaLabel.
  ///
  /// In en, this message translates to:
  /// **'VIDEO IDEA'**
  String get videoIdeaLabel;

  /// No description provided for @videoIdeaPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ej: A video about how to organize your desk to be more productive in 5 steps...'**
  String get videoIdeaPlaceholder;

  /// No description provided for @suggestedStructures.
  ///
  /// In en, this message translates to:
  /// **'Suggested Structures'**
  String get suggestedStructures;

  /// No description provided for @premiumAi.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM AI'**
  String get premiumAi;

  /// No description provided for @hookTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduction / Hook'**
  String get hookTitle;

  /// No description provided for @hookDesc.
  ///
  /// In en, this message translates to:
  /// **'Hook your audience in the first 3 seconds with a common problem.'**
  String get hookDesc;

  /// No description provided for @valueTitle.
  ///
  /// In en, this message translates to:
  /// **'Value Development'**
  String get valueTitle;

  /// No description provided for @valueDesc.
  ///
  /// In en, this message translates to:
  /// **'Divide your explanation into 3 actionable and easy-to-follow key points.'**
  String get valueDesc;

  /// No description provided for @ctaTitle.
  ///
  /// In en, this message translates to:
  /// **'Close (CTA)'**
  String get ctaTitle;

  /// No description provided for @ctaDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask your followers to like and share the content.'**
  String get ctaDesc;

  /// No description provided for @generateFullScript.
  ///
  /// In en, this message translates to:
  /// **'Generate Full Script'**
  String get generateFullScript;

  /// No description provided for @poweredByAi.
  ///
  /// In en, this message translates to:
  /// **'POWERED BY LATEST GENERATION AI'**
  String get poweredByAi;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'STEP 2: VALIDATE THE FRAGMENTS'**
  String get step2Title;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// No description provided for @reRecord.
  ///
  /// In en, this message translates to:
  /// **'RE-RECORD'**
  String get reRecord;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
