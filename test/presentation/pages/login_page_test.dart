import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_actor_datasource.dart';
import 'package:notexlper/presentation/pages/login_page.dart';
import 'package:notexlper/presentation/providers/actor_providers.dart';

void main() {
  late FakeActorDataSource actorDataSource;

  setUp(() {
    actorDataSource = FakeActorDataSource(delay: Duration.zero);
  });

  Widget createLoginPage({VoidCallback? onLoggedIn}) {
    return ProviderScope(
      overrides: [
        actorDataSourceProvider.overrideWithValue(actorDataSource),
      ],
      child: MaterialApp(
        home: LoginPage(onLoggedIn: onLoggedIn ?? () {}),
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('should display "Who are you?" heading', (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Who are you?'), findsOneWidget);
    });

    testWidgets('should display both actors', (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('should display people icon', (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('should call onLoggedIn when actor is tapped', (tester) async {
      var loggedIn = false;
      await tester.pumpWidget(createLoginPage(
        onLoggedIn: () => loggedIn = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();

      expect(loggedIn, true);
    });

    testWidgets('should set current actor when actor is tapped', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actorDataSourceProvider.overrideWithValue(actorDataSource),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return LoginPage(onLoggedIn: () {});
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      final currentActor = capturedRef.read(currentActorProvider);
      expect(currentActor, isNotNull);
      expect(currentActor!.name, 'Alice');
    });

    testWidgets('should show empty state when no actors after clear',
        (tester) async {
      actorDataSource.clear();
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Who are you?'), findsOneWidget);
      // No actor tiles should exist
      expect(find.text('Me'), findsNothing);
      expect(find.text('Alice'), findsNothing);
    });
  });
}
