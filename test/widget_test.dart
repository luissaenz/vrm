import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vrm_app/main.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const VRMApp(startWithOnboarding: false));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
