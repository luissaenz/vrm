import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/core/theme.dart';
import 'package:vrm_app/features/dashboard/dashboard_page.dart';

import 'package:vrm_app/features/onboarding/pages/onboarding_flow.dart';
import 'package:vrm_app/features/onboarding/data/onboarding_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = OnboardingRepository();
  final profile = await repository.getUserProfile();

  runApp(VRMApp(startWithOnboarding: !profile.onboardingCompleted));
}

class VRMApp extends StatelessWidget {
  final bool startWithOnboarding;
  const VRMApp({super.key, required this.startWithOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRM App - Cámara Atómica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      routes: {
        '/onboarding': (context) => const OnboardingFlow(),
        '/dashboard': (context) => const DashboardPage(),
      },
      home: startWithOnboarding
          ? const OnboardingFlow()
          : const DashboardPage(),
    );
  }
}
