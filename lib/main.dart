import 'package:flutter/material.dart';
import 'package:vrm_app/core/theme.dart';
import 'package:vrm_app/features/dashboard/dashboard_page.dart';

void main() {
  runApp(const VRMApp());
}

class VRMApp extends StatelessWidget {
  const VRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRM App - Cámara Atómica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardPage(),
    );
  }
}
