import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/core/constants/app_constants.dart';
import 'package:notexlper/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage', () {
    testWidgets('should display app name NOTEXLPER', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(
            splashDuration: Duration.zero,
          ),
        ),
      );

      expect(find.text(AppConstants.appName), findsOneWidget);

      // Complete any pending timers
      await tester.pumpAndSettle();
    });

    testWidgets('should display app icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(
            splashDuration: Duration.zero,
          ),
        ),
      );

      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(
            splashDuration: Duration.zero,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should call onInitialized callback after delay',
        (tester) async {
      bool wasInitialized = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(
            splashDuration: const Duration(milliseconds: 100),
            onInitialized: () {
              wasInitialized = true;
            },
          ),
        ),
      );

      expect(wasInitialized, false);

      // Wait for the splash duration
      await tester.pump(const Duration(milliseconds: 150));

      expect(wasInitialized, true);
    });
  });
}
