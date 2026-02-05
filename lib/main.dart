import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vrm_app/l10n/app_localizations.dart';
import 'package:vrm_app/core/theme.dart';
import 'package:vrm_app/features/dashboard/dashboard_page.dart';

void main() {
  runApp(const VRMApp(startWithOnboarding: false));
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
      home: const DashboardPage(),
    );
  }
}
