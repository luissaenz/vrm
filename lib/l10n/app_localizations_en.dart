// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VRM App';

  @override
  String get goodMorning => 'GOOD MORNING,';

  @override
  String get creator => 'Alex Rivera';

  @override
  String get streak => 'Streak';

  @override
  String days(String count) {
    return '$count Days';
  }

  @override
  String get clips => 'Clips';

  @override
  String get newProject => 'New Project';

  @override
  String get voiceControlActive => 'Voice control active';

  @override
  String get recentProjects => 'Recent Projects';

  @override
  String get viewAll => 'View all';

  @override
  String get readyToCreate => 'Ready to create?';

  @override
  String get captureIdeas => 'Capture your ideas, one fragment at a time.';

  @override
  String get streakLabel => 'RECORDING\nSTREAK';

  @override
  String get fragments => 'FRAGMENTS';

  @override
  String get calendar => 'Calendar';

  @override
  String get panel => 'PANEL';

  @override
  String get videos => 'VIDEOS';

  @override
  String get script => 'SCRIPT';

  @override
  String get profile => 'PROFILE';

  @override
  String get draft => 'DRAFT';

  @override
  String get ready => 'READY';

  @override
  String get wed => 'WED';

  @override
  String get thu => 'THU';

  @override
  String get fri => 'FRI';

  @override
  String get sat => 'SAT';

  @override
  String get progressLabel => 'PROGRESS';

  @override
  String get editedYesterday => 'Edited yesterday';

  @override
  String editedHoursAgo(String count) {
    return 'Edited $count hours ago';
  }

  @override
  String fragmentCount(String current, String total) {
    return '$current/$total Fragments';
  }

  @override
  String get newProjectTitle => 'New Project';

  @override
  String get step1Title => 'STEP 1: WRITE OR PASTE YOUR SCRIPT';

  @override
  String charactersCount(String count) {
    return '$count characters';
  }

  @override
  String secondsAbbreviation(String seconds) {
    return '${seconds}s';
  }

  @override
  String totalTimeEstimate(String seconds) {
    return 'approximate duration $seconds';
  }

  @override
  String get assistant => 'ASSISTANT';

  @override
  String get optimize => 'OPTIMIZE WITH AI';

  @override
  String get fragmentPreview => 'FRAGMENT PREVIEW';

  @override
  String blocksCount(int count) {
    return '$count BLOCKS';
  }

  @override
  String get splitIntoFragments => 'Split into Fragments';

  @override
  String get paste => 'Paste';

  @override
  String get segment => 'SEGMENT';
}
