import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:totoitaliano/features/onboarding/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen mostra il nome dell\'app', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('TotoItaliano'), findsOneWidget);
  });
}
