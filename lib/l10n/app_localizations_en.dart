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

  @override
  String get scriptAssistantTitle => 'Script Assistant';

  @override
  String get defineIdea => 'Define your Idea';

  @override
  String get iaHelperText => 'AI will help you structure the perfect content.';

  @override
  String get videoIdeaLabel => 'VIDEO IDEA';

  @override
  String get videoIdeaPlaceholder =>
      'Ej: A video about how to organize your desk to be more productive in 5 steps...';

  @override
  String get suggestedStructures => 'Suggested Structures';

  @override
  String get premiumAi => 'PREMIUM AI';

  @override
  String get hookTitle => 'Introduction / Hook';

  @override
  String get hookDesc =>
      'Hook your audience in the first 3 seconds with a common problem.';

  @override
  String get valueTitle => 'Value Development';

  @override
  String get valueDesc =>
      'Divide your explanation into 3 actionable and easy-to-follow key points.';

  @override
  String get ctaTitle => 'Close (CTA)';

  @override
  String get ctaDesc => 'Ask your followers to like and share the content.';

  @override
  String get generateFullScript => 'Generate Full Script';

  @override
  String get poweredByAi => 'POWERED BY LATEST GENERATION AI';

  @override
  String get step2Title => 'STEP 2: VALIDATE THE FRAGMENTS';

  @override
  String get next => 'NEXT';

  @override
  String get reRecord => 'RE-RECORD';

  @override
  String get preparation => 'PREPARATION';

  @override
  String get listening => 'LISTENING...';

  @override
  String get systemReads => 'THE SYSTEM READS THE SCRIPT:';

  @override
  String get getReady => 'GET READY';

  @override
  String get repeat => 'REPEAT';

  @override
  String get record => 'RECORD';

  @override
  String get waiting => 'WAITING...';

  @override
  String get voiceControlDisabled => 'Voice control disabled';

  @override
  String get recordingStatus => 'RECORDING';

  @override
  String get listeningToAdvance => 'Listening for voice to advance...';

  @override
  String get gridLabel => 'GRID';

  @override
  String get ghostLabel => 'GHOST';

  @override
  String get welcomeTitle => 'WELCOME';

  @override
  String get welcomeHeadline => 'What is your biggest obstacle today?';

  @override
  String get welcomeCta => 'START';

  @override
  String get identityHeadline => 'Choose your Identity';

  @override
  String get identitySubheadline =>
      'Touch the mirror that best reflects your purpose today';

  @override
  String get identityConfirm => 'CONFIRM IDENTITY';

  @override
  String get configTitle => 'Custom Configuration';

  @override
  String get configGreetingLeader =>
      '\"Welcome. I have configured the app in Efficiency Mode. Your scripts will be concise and the AI will automatically remove your silences.\"';

  @override
  String get configGreetingInfluencer =>
      '\"Hi! I have activated Flow Mode. The app will notify you if your smile or eye contact drops. Let\'s make them fall in love with your content.\"';

  @override
  String get configGreetingSeller =>
      '\"Ready. I have loaded Elevator Pitch templates and proven sales scripts. Your goal is clarity.\"';

  @override
  String get configGreetingDefault => '\"We are ready to start.\"';

  @override
  String get configSummaryLabel => 'CONFIGURATION SUMMARY';

  @override
  String get configTeleprompterLabel => 'Suggested speed for your profile';

  @override
  String get configCta => 'CREATE MY FIRST VIDEO';

  @override
  String get configFooterLabel => 'PRESS TO START YOUR EXPERIENCE';

  @override
  String get profileLeaderTitle => 'Leader';

  @override
  String get profileLeaderTag => 'EFFICIENCY';

  @override
  String get profileLeaderQuote => '\"I have little time\"';

  @override
  String get profileInfluencerTitle => 'Influencer';

  @override
  String get profileInfluencerTag => 'ENERGY';

  @override
  String get profileInfluencerQuote => '\"I want to connect\"';

  @override
  String get profileSellerTitle => 'Seller';

  @override
  String get profileSellerTag => 'CONFIDENCE';

  @override
  String get profileSellerQuote => '\"I need to sell\"';

  @override
  String get configSolutionLeaderTitle => 'Take 1 Minute';

  @override
  String get configSolutionLeaderSubtitle => 'Fast and perfect recordings';

  @override
  String get configSolutionInfluencerTitle => 'Find your Voice';

  @override
  String get configSolutionInfluencerSubtitle =>
      'Create a community that loves you';

  @override
  String get configSolutionSellerTitle => 'Absolute Clarity';

  @override
  String get configSolutionSellerSubtitle => 'Convert viewers into customers';

  @override
  String get configSolutionDefaultTitle => 'Optimized Solution';

  @override
  String get configSolutionDefaultSubtitle => 'Custom configuration';

  @override
  String get configPremiumLeaderTitle => '\"Magic Edit\" Mode';

  @override
  String get configPremiumLeaderSubtitle => 'Video ready in 30 seconds';

  @override
  String get configPremiumInfluencerTitle => '\"Charisma\" Filters';

  @override
  String get configPremiumInfluencerSubtitle => 'Emotional tone analysis';

  @override
  String get configPremiumSellerTitle => 'Sales Teleprompter';

  @override
  String get configPremiumSellerSubtitle => 'Premium scripts included';

  @override
  String get configPremiumDefaultTitle => 'Premium Features';

  @override
  String get configPremiumDefaultSubtitle => 'Unlock all potential';

  @override
  String profileTeleprompterLeader(String ppm) {
    return 'Fast Teleprompter ($ppm ppm)';
  }

  @override
  String profileTeleprompterInfluencer(String ppm) {
    return 'Dynamic Teleprompter ($ppm ppm)';
  }

  @override
  String profileTeleprompterSeller(String ppm) {
    return 'Persuasive Teleprompter ($ppm ppm)';
  }

  @override
  String get welcomeCoachImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDtnj9X_8A4fpoltWeeCfJjOfdRir4lvqGiqtmMoT9Hvmws0Aq5DKAZCFTa9kXP_wgcDvg8PTDqEzCFC3zFii1Veuisu0XyAs9IOo0zP1n_QGqG1XnhUWb56CkgWZFSuxlcpsJtwkYwOP5ge53hCLRFqDiuBvmfFjY0vE1fNtLvZx3ZRMPsDPqcISCDlgnLfuVNNvfOC-Xo2Avc5bsJ4x6WTihF_dDNwh_ZMzgcGLr31IjmjExdO2MegRAE0LM3QxLehYpyI7bLo8dl';

  @override
  String get profileLeaderImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBaw-4btBBo8h8Eo_zdQlH4NB0-mfmLOvZBgRkZbeWySLCOZmlQPhwwpiZj9FnkAt0fPwEVLldrfe14cfiUOqLNRqtslNctV2P71HNv4Ywto6BKxgvVR_F6dhJK6SgO_Vl-JUeXPiuNXyMReFBwQ5jraxir0GslbZAvIWf2L18N28Uv4H1cE5531ATnModh2xsBVwzHxwuTv8gKh-tDhmDylWTS7TvIc7kdaw-2Y1Khuu0BVAzSRY56VbfrDY-EU8Eiif5qGpVnEHTG';

  @override
  String get profileInfluencerImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfHM-MBerpZJQCw1G3xkyUzZFtWHm1-mXt_BzAN78Zz5-iUC5HLbaQ6Hsf0u8oYKDUVO__A18MIz3ySJH3ssZ1G17Z5raOAK1hVKQNdfj8_ei7kjmmWZ_lDM2t3nzH5wHp8JrcbyyoH_1IGK7erPct4eaNzbgBsqenPoZe2CZi63PE8ftlb6WRkOIA8OKzqKwVeUwL-S_7Rl7pV0666CS5a1g1zTZAWo6DpQ6i06jyEngNHa-BVG39DOOc1Eq6XNMsziDBwVAn3qZ';

  @override
  String get profileSellerImage =>
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAbHlQa2OUJlKn6gBpuhTPrs-Q0_qAIgIDsINsGm2LfDF76YoL3utRhVCQZBt6pFvVeMUMvQuAg_7-LwLeCMFJnJQ4l18fMu-jUX1w15MZt7mxklAwpcg1L6vUWXRZn2xc81UNL7g2IqMrNhBTCXDe9Y18yO1iYbt8tc8jU4KDoFeLKt5_qsgWKoGerm2puw0hCjNqb0TfvxixhDpay7OjTLm-u4IRnf_IbJ-Ezo-hvh5e4YPu2lHJS9o03e05lK4IxuPyCXfoCCU4d';
}
