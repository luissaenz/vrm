import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:vrm_app/main.dart';
import 'package:vrm_app/features/dashboard/dashboard_page.dart';
import 'package:vrm_app/features/onboarding/pages/onboarding_flow.dart';

void main() {
  group('VRMApp Widget Tests', () {
    late Directory testDir;

    setUpAll(() {
      HttpOverrides.global = null;
    });

    setUp(() {
      testDir = Directory.systemTemp.createTempSync('vrm_widget_test_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(testDir.path);
    });

    tearDown(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    testWidgets('App renders MaterialApp without crash', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        await tester.pumpWidget(const VRMApp(startWithOnboarding: false));
        await tester.pump();
      });
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App shows OnboardingFlow when startWithOnboarding=true', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        await tester.pumpWidget(const VRMApp(startWithOnboarding: true));
        // We cannot use pumpAndSettle in runAsync easily if there are animations,
        // but we can pump a few times.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      });
      expect(find.byType(OnboardingFlow), findsOneWidget);
    });

    testWidgets('App shows DashboardPage when startWithOnboarding=false', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'user_identity': 1, // UserIdentity.influencer
      });
      await tester.runAsync(() async {
        await tester.pumpWidget(const VRMApp(startWithOnboarding: false));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      });
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('App configures both light and dark themes', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        await tester.pumpWidget(const VRMApp(startWithOnboarding: false));
        await tester.pump();
      });
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.theme, isNotNull);
    });
  });
}

/// Fake path provider for widget testing
class _FakePathProviderPlatform extends PathProviderPlatform {
  final String basePath;

  _FakePathProviderPlatform(this.basePath);

  @override
  Future<String?> getApplicationDocumentsPath() async => basePath;

  @override
  Future<String?> getTemporaryPath() async => basePath;

  @override
  Future<String?> getApplicationSupportPath() async => basePath;
}
