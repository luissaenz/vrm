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

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'VRM App'**
  String get appTitle;

  /// Standard morning greeting
  ///
  /// In en, this message translates to:
  /// **'GOOD MORNING,'**
  String get goodMorning;

  /// The name of the app creator
  ///
  /// In en, this message translates to:
  /// **'Alex Rivera'**
  String get creator;

  /// Label for the user's daily activity streak
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// A count of days for the streak
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String days(String count);

  /// Label for video clips section
  ///
  /// In en, this message translates to:
  /// **'Clips'**
  String get clips;

  /// Button text to start a new project
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// Status message when voice control is active
  ///
  /// In en, this message translates to:
  /// **'Voice control active'**
  String get voiceControlActive;

  /// Title for the recent projects list
  ///
  /// In en, this message translates to:
  /// **'Recent Projects'**
  String get recentProjects;

  /// Link to view all projects
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// Call to action headline
  ///
  /// In en, this message translates to:
  /// **'Ready to create?'**
  String get readyToCreate;

  /// Subheadline for project creation
  ///
  /// In en, this message translates to:
  /// **'Capture your ideas, one fragment at a time.'**
  String get captureIdeas;

  /// Label for the recording streak widget
  ///
  /// In en, this message translates to:
  /// **'RECORDING\nSTREAK'**
  String get streakLabel;

  /// Label for the fragments count
  ///
  /// In en, this message translates to:
  /// **'FRAGMENTS'**
  String get fragments;

  /// Label for the calendar section
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Label for the control panel
  ///
  /// In en, this message translates to:
  /// **'PANEL'**
  String get panel;

  /// Label for the videos section
  ///
  /// In en, this message translates to:
  /// **'VIDEOS'**
  String get videos;

  /// Label for the script section
  ///
  /// In en, this message translates to:
  /// **'SCRIPT'**
  String get script;

  /// Label for the user profile section
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile;

  /// Status label for draft projects
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get draft;

  /// Status label for ready projects
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// Abbreviation for Wednesday
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get wed;

  /// Abbreviation for Thursday
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get thu;

  /// Abbreviation for Friday
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get fri;

  /// Abbreviation for Saturday
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get sat;

  /// Label for the project progress bar
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get progressLabel;

  /// Time reference for a project edited on the previous day
  ///
  /// In en, this message translates to:
  /// **'Edited yesterday'**
  String get editedYesterday;

  /// Time reference for a project edited a few hours ago
  ///
  /// In en, this message translates to:
  /// **'Edited {count} hours ago'**
  String editedHoursAgo(String count);

  /// A count of fragments in a project
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} Fragments'**
  String fragmentCount(String current, String total);

  /// Title for the new project creation screen
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProjectTitle;

  /// Title for the first step of onboarding
  ///
  /// In en, this message translates to:
  /// **'STEP 1: WRITE OR PASTE YOUR SCRIPT'**
  String get step1Title;

  /// A count of characters in a text field
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String charactersCount(String count);

  /// Abbreviation for seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsAbbreviation(String seconds);

  /// Estimated time duration
  ///
  /// In en, this message translates to:
  /// **'approximate duration {seconds}'**
  String totalTimeEstimate(String seconds);

  /// Label for the assistant section
  ///
  /// In en, this message translates to:
  /// **'ASSISTANT'**
  String get assistant;

  /// Button label to optimize script using AI
  ///
  /// In en, this message translates to:
  /// **'OPTIMIZE WITH AI'**
  String get optimize;

  /// Header for the fragment preview section
  ///
  /// In en, this message translates to:
  /// **'FRAGMENT PREVIEW'**
  String get fragmentPreview;

  /// A count of text blocks
  ///
  /// In en, this message translates to:
  /// **'{count} BLOCKS'**
  String blocksCount(int count);

  /// Action to split a script into multiple fragments
  ///
  /// In en, this message translates to:
  /// **'Split into Fragments'**
  String get splitIntoFragments;

  /// Action to paste text from clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Action to segment a fragment
  ///
  /// In en, this message translates to:
  /// **'SEGMENT'**
  String get segment;

  /// Title for the script writing assistant
  ///
  /// In en, this message translates to:
  /// **'Script Assistant'**
  String get scriptAssistantTitle;

  /// Headline for defining the video core idea
  ///
  /// In en, this message translates to:
  /// **'Define your Idea'**
  String get defineIdea;

  /// Instructional text about AI assistance
  ///
  /// In en, this message translates to:
  /// **'AI will help you structure the perfect content.'**
  String get iaHelperText;

  /// Label for the video idea input field
  ///
  /// In en, this message translates to:
  /// **'VIDEO IDEA'**
  String get videoIdeaLabel;

  /// Placeholder example for the video idea field
  ///
  /// In en, this message translates to:
  /// **'Ej: A video about how to organize your desk to be more productive in 5 steps...'**
  String get videoIdeaPlaceholder;

  /// Header for suggested script structures
  ///
  /// In en, this message translates to:
  /// **'Suggested Structures'**
  String get suggestedStructures;

  /// Label for premium AI features
  ///
  /// In en, this message translates to:
  /// **'PREMIUM AI'**
  String get premiumAi;

  /// Title for the script hook section
  ///
  /// In en, this message translates to:
  /// **'Introduction / Hook'**
  String get hookTitle;

  /// Description of the hook purpose
  ///
  /// In en, this message translates to:
  /// **'Hook your audience in the first 3 seconds with a common problem.'**
  String get hookDesc;

  /// Title for the value development section
  ///
  /// In en, this message translates to:
  /// **'Value Development'**
  String get valueTitle;

  /// Description of the value development purpose
  ///
  /// In en, this message translates to:
  /// **'Divide your explanation into 3 actionable and easy-to-follow key points.'**
  String get valueDesc;

  /// Title for the call to action section
  ///
  /// In en, this message translates to:
  /// **'Close (CTA)'**
  String get ctaTitle;

  /// Description of the CTA purpose
  ///
  /// In en, this message translates to:
  /// **'Ask your followers to like and share the content.'**
  String get ctaDesc;

  /// Action button to generate the complete script
  ///
  /// In en, this message translates to:
  /// **'Generate Full Script'**
  String get generateFullScript;

  /// Subtext indicating AI-powered generation
  ///
  /// In en, this message translates to:
  /// **'POWERED BY LATEST GENERATION AI'**
  String get poweredByAi;

  /// Title for the second step of onboarding
  ///
  /// In en, this message translates to:
  /// **'STEP 2: VALIDATE THE FRAGMENTS'**
  String get step2Title;

  /// Standard label for moving to the next step
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// Action button to restart recording
  ///
  /// In en, this message translates to:
  /// **'RE-RECORD'**
  String get reRecord;

  /// Header for the preparation screen
  ///
  /// In en, this message translates to:
  /// **'PREPARATION'**
  String get preparation;

  /// Status message while waiting for voice input
  ///
  /// In en, this message translates to:
  /// **'LISTENING...'**
  String get listening;

  /// Status text while the AI is reading
  ///
  /// In en, this message translates to:
  /// **'THE SYSTEM READS THE SCRIPT:'**
  String get systemReads;

  /// Status text before recording starts
  ///
  /// In en, this message translates to:
  /// **'GET READY'**
  String get getReady;

  /// Action button to play audio again
  ///
  /// In en, this message translates to:
  /// **'REPEAT'**
  String get repeat;

  /// Action button to start recording
  ///
  /// In en, this message translates to:
  /// **'RECORD'**
  String get record;

  /// General status for waiting state
  ///
  /// In en, this message translates to:
  /// **'WAITING...'**
  String get waiting;

  /// Status when the voice system is off
  ///
  /// In en, this message translates to:
  /// **'Voice control disabled'**
  String get voiceControlDisabled;

  /// Status text during active recording
  ///
  /// In en, this message translates to:
  /// **'RECORDING'**
  String get recordingStatus;

  /// Status while waiting for voice command to advance
  ///
  /// In en, this message translates to:
  /// **'Listening for voice to advance...'**
  String get listeningToAdvance;

  /// Label for the layout grid
  ///
  /// In en, this message translates to:
  /// **'GRID'**
  String get gridLabel;

  /// Label for the ghost frame overlay
  ///
  /// In en, this message translates to:
  /// **'GHOST'**
  String get ghostLabel;

  /// Header for the welcome Step
  ///
  /// In en, this message translates to:
  /// **'WELCOME'**
  String get welcomeTitle;

  /// Main question in the welcome step
  ///
  /// In en, this message translates to:
  /// **'What is your biggest obstacle today?'**
  String get welcomeHeadline;

  /// Button to start the onboarding flow
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get welcomeCta;

  /// Title for the identity selection step
  ///
  /// In en, this message translates to:
  /// **'Choose your Identity'**
  String get identityHeadline;

  /// Instruction for identity selection
  ///
  /// In en, this message translates to:
  /// **'Touch the mirror that best reflects your purpose today'**
  String get identitySubheadline;

  /// Confirmation button for identity selection
  ///
  /// In en, this message translates to:
  /// **'CONFIRM IDENTITY'**
  String get identityConfirm;

  /// Header for the personalized config step
  ///
  /// In en, this message translates to:
  /// **'Custom Configuration'**
  String get configTitle;

  /// Personalized coaching message for Leader profile
  ///
  /// In en, this message translates to:
  /// **'\"Welcome. I have configured the app in Efficiency Mode. Your scripts will be concise and the AI will automatically remove your silences.\"'**
  String get configGreetingLeader;

  /// Personalized coaching message for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'\"Hi! I have activated Flow Mode. The app will notify you if your smile or eye contact drops. Let\'s make them fall in love with your content.\"'**
  String get configGreetingInfluencer;

  /// Personalized coaching message for Seller profile
  ///
  /// In en, this message translates to:
  /// **'\"Ready. I have loaded Elevator Pitch templates and proven sales scripts. Your goal is clarity.\"'**
  String get configGreetingSeller;

  /// Default personalized coaching message
  ///
  /// In en, this message translates to:
  /// **'\"We are ready to start.\"'**
  String get configGreetingDefault;

  /// Label for the configuration summary section
  ///
  /// In en, this message translates to:
  /// **'CONFIGURATION SUMMARY'**
  String get configSummaryLabel;

  /// Label for the teleprompter speed indicator
  ///
  /// In en, this message translates to:
  /// **'Suggested speed for your profile'**
  String get configTeleprompterLabel;

  /// Button to finish onboarding and move to dashboard
  ///
  /// In en, this message translates to:
  /// **'CREATE MY FIRST VIDEO'**
  String get configCta;

  /// Final instructional hint at onboarding end
  ///
  /// In en, this message translates to:
  /// **'PRESS TO START YOUR EXPERIENCE'**
  String get configFooterLabel;

  /// Title label for Leader profile
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get profileLeaderTitle;

  /// Taglabel for Leader profile
  ///
  /// In en, this message translates to:
  /// **'EFFICIENCY'**
  String get profileLeaderTag;

  /// Representative quote for Leader profile
  ///
  /// In en, this message translates to:
  /// **'\"I have little time\"'**
  String get profileLeaderQuote;

  /// Title label for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'Influencer'**
  String get profileInfluencerTitle;

  /// Taglabel for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'ENERGY'**
  String get profileInfluencerTag;

  /// Representative quote for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'\"I want to connect\"'**
  String get profileInfluencerQuote;

  /// Title label for Seller profile
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get profileSellerTitle;

  /// Taglabel for Seller profile
  ///
  /// In en, this message translates to:
  /// **'CONFIDENCE'**
  String get profileSellerTag;

  /// Representative quote for Seller profile
  ///
  /// In en, this message translates to:
  /// **'\"I need to sell\"'**
  String get profileSellerQuote;

  /// Solution title for Leader profile
  ///
  /// In en, this message translates to:
  /// **'Take 1 Minute'**
  String get configSolutionLeaderTitle;

  /// Solution description for Leader profile
  ///
  /// In en, this message translates to:
  /// **'Fast and perfect recordings'**
  String get configSolutionLeaderSubtitle;

  /// Solution title for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'Find your Voice'**
  String get configSolutionInfluencerTitle;

  /// Solution description for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'Create a community that loves you'**
  String get configSolutionInfluencerSubtitle;

  /// Solution title for Seller profile
  ///
  /// In en, this message translates to:
  /// **'Absolute Clarity'**
  String get configSolutionSellerTitle;

  /// Solution description for Seller profile
  ///
  /// In en, this message translates to:
  /// **'Convert viewers into customers'**
  String get configSolutionSellerSubtitle;

  /// Default solution title
  ///
  /// In en, this message translates to:
  /// **'Optimized Solution'**
  String get configSolutionDefaultTitle;

  /// Default solution description
  ///
  /// In en, this message translates to:
  /// **'Custom configuration'**
  String get configSolutionDefaultSubtitle;

  /// Premium feature title for Leader profile
  ///
  /// In en, this message translates to:
  /// **'\"Magic Edit\" Mode'**
  String get configPremiumLeaderTitle;

  /// Premium feature description for Leader profile
  ///
  /// In en, this message translates to:
  /// **'Video ready in 30 seconds'**
  String get configPremiumLeaderSubtitle;

  /// Premium feature title for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'\"Charisma\" Filters'**
  String get configPremiumInfluencerTitle;

  /// Premium feature description for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'Emotional tone analysis'**
  String get configPremiumInfluencerSubtitle;

  /// Premium feature title for Seller profile
  ///
  /// In en, this message translates to:
  /// **'Sales Teleprompter'**
  String get configPremiumSellerTitle;

  /// Premium feature description for Seller profile
  ///
  /// In en, this message translates to:
  /// **'Premium scripts included'**
  String get configPremiumSellerSubtitle;

  /// Default premium feature title
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get configPremiumDefaultTitle;

  /// Default premium feature description
  ///
  /// In en, this message translates to:
  /// **'Unlock all potential'**
  String get configPremiumDefaultSubtitle;

  /// Personalized teleprompter speed message for Leader profile
  ///
  /// In en, this message translates to:
  /// **'Fast Teleprompter ({ppm} ppm)'**
  String profileTeleprompterLeader(String ppm);

  /// Personalized teleprompter speed message for Influencer profile
  ///
  /// In en, this message translates to:
  /// **'Dynamic Teleprompter ({ppm} ppm)'**
  String profileTeleprompterInfluencer(String ppm);

  /// Personalized teleprompter speed message for Seller profile
  ///
  /// In en, this message translates to:
  /// **'Persuasive Teleprompter ({ppm} ppm)'**
  String profileTeleprompterSeller(String ppm);

  /// URL for the coach welcome image
  ///
  /// In en, this message translates to:
  /// **'https://lh3.googleusercontent.com/aida-public/AB6AXuDtnj9X_8A4fpoltWeeCfJjOfdRir4lvqGiqtmMoT9Hvmws0Aq5DKAZCFTa9kXP_wgcDvg8PTDqEzCFC3zFii1Veuisu0XyAs9IOo0zP1n_QGqG1XnhUWb56CkgWZFSuxlcpsJtwkYwOP5ge53hCLRFqDiuBvmfFjY0vE1fNtLvZx3ZRMPsDPqcISCDlgnLfuVNNvfOC-Xo2Avc5bsJ4x6WTihF_dDNwh_ZMzgcGLr31IjmjExdO2MegRAE0LM3QxLehYpyI7bLo8dl'**
  String get welcomeCoachImage;

  /// URL for the Leader profile image
  ///
  /// In en, this message translates to:
  /// **'https://lh3.googleusercontent.com/aida-public/AB6AXuBaw-4btBBo8h8Eo_zdQlH4NB0-mfmLOvZBgRkZbeWySLCOZmlQPhwwpiZj9FnkAt0fPwEVLldrfe14cfiUOqLNRqtslNctV2P71HNv4Ywto6BKxgvVR_F6dhJK6SgO_Vl-JUeXPiuNXyMReFBwQ5jraxir0GslbZAvIWf2L18N28Uv4H1cE5531ATnModh2xsBVwzHxwuTv8gKh-tDhmDylWTS7TvIc7kdaw-2Y1Khuu0BVAzSRY56VbfrDY-EU8Eiif5qGpVnEHTG'**
  String get profileLeaderImage;

  /// URL for the Influencer profile image
  ///
  /// In en, this message translates to:
  /// **'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfHM-MBerpZJQCw1G3xkyUzZFtWHm1-mXt_BzAN78Zz5-iUC5HLbaQ6Hsf0u8oYKDUVO__A18MIz3ySJH3ssZ1G17Z5raOAK1hVKQNdfj8_ei7kjmmWZ_lDM2t3nzH5wHp8JrcbyyoH_1IGK7erPct4eaNzbgBsqenPoZe2CZi63PE8ftlb6WRkOIA8OKzqKwVeUwL-S_7Rl7pV0666CS5a1g1zTZAWo6DpQ6i06jyEngNHa-BVG39DOOc1Eq6XNMsziDBwVAn3qZ'**
  String get profileInfluencerImage;

  /// URL for the Seller profile image
  ///
  /// In en, this message translates to:
  /// **'https://lh3.googleusercontent.com/aida-public/AB6AXuAbHlQa2OUJlKn6gBpuhTPrs-Q0_qAIgIDsINsGm2LfDF76YoL3utRhVCQZBt6pFvVeMUMvQuAg_7-LwLeCMFJnJQ4l18fMu-jUX1w15MZt7mxklAwpcg1L6vUWXRZn2xc81UNL7g2IqMrNhBTCXDe9Y18yO1iYbt8tc8jU4KDoFeLKt5_qsgWKoGerm2puw0hCjNqb0TfvxixhDpay7OjTLm-u4IRnf_IbJ-Ezo-hvh5e4YPu2lHJS9o03e05lK4IxuPyCXfoCCU4d'**
  String get profileSellerImage;

  /// Title for the performance summary screen
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE SUMMARY'**
  String get performanceSummary;

  /// Headline for saved time
  ///
  /// In en, this message translates to:
  /// **'Time Saved!'**
  String get timeSavedTitle;

  /// Description of saved time and clips
  ///
  /// In en, this message translates to:
  /// **'You saved {minutes} min of editing by automatically joining {clips} clips.'**
  String timeSavedDescription(String minutes, String clips);

  /// Label for saved time metric
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get savedLabel;

  /// Label for tempo/rhythm metric
  ///
  /// In en, this message translates to:
  /// **'RHYTHM'**
  String get ritmoLabel;

  /// Status label for perfect performance
  ///
  /// In en, this message translates to:
  /// **'PERFECT'**
  String get perfectoLabel;

  /// Label for filler words detection
  ///
  /// In en, this message translates to:
  /// **'FILLER WORDS'**
  String get fillerWordsLabel;

  /// Count of detected items
  ///
  /// In en, this message translates to:
  /// **'{count} DETECTED'**
  String detectedLabel(String count);

  /// Status label for low detection
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowStatus;

  /// Label for pauses removed
  ///
  /// In en, this message translates to:
  /// **'PAUSES'**
  String get pausesLabel;

  /// Subtext for removed time/items
  ///
  /// In en, this message translates to:
  /// **'removed'**
  String get removedLabel;

  /// Title for the preview section
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// Action to edit manually
  ///
  /// In en, this message translates to:
  /// **'Edit manually'**
  String get editManually;

  /// Action to export the video
  ///
  /// In en, this message translates to:
  /// **'Export Video'**
  String get exportVideo;
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
