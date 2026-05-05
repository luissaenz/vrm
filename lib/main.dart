import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/core/theme.dart';
import 'package:vrm_app/features/dashboard/dashboard_page.dart';
import 'package:vrm_app/features/onboarding/pages/onboarding_flow.dart';
import 'package:vrm_app/features/recording/pages/stitch_progress_page.dart';
import 'package:vrm_app/features/recording/recording_end_page.dart';
import 'package:vrm_app/features/recording/recording_page.dart';
import 'package:vrm_app/features/new_project/models/script_analysis.dart';
import 'package:vrm_app/features/settings/services/settings_service.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const VRMApp(startWithOnboarding: true));
}

class VRMApp extends StatefulWidget {
  final bool startWithOnboarding;
  const VRMApp({super.key, required this.startWithOnboarding});

  @override
  State<VRMApp> createState() => _VRMAppState();
}

class _VRMAppState extends State<VRMApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await SettingsService.instance.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = mode;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
      );
    }

    return MaterialApp(
      title: 'VRM App - Cámara Atómica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: widget.startWithOnboarding
          ? const OnboardingFlow()
          : const DashboardPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/onboarding': (context) => const OnboardingFlow(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/stitch-progress') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => StitchProgressPage(
              projectId: args['projectId'] as String,
              approvedClips: args['approvedClips'] as List<String>,
            ),
          );
        } else if (settings.name == '/recording') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RecordingPage(
              analysis: args['analysis'] as ScriptAnalysis,
              projectId: args['projectId'] as String,
              currentFragmentIndex: args['currentFragmentIndex'] as int? ?? 0,
            ),
          );
        } else if (settings.name == '/recording-end') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => RecordingEndPage(
              finalVideoPath: args?['finalVideoPath'] as String?,
            ),
          );
        }
        return null;
      },
    );
  }
}
