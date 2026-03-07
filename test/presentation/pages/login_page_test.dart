import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_actor_datasource.dart';
import 'package:notexlper/data/datasources/local/fake_workspace_datasource.dart';
import 'package:notexlper/presentation/pages/login_page.dart';
import 'package:notexlper/presentation/providers/actor_providers.dart';
import 'package:notexlper/presentation/providers/workspace_providers.dart';

void main() {
  late FakeActorDataSource actorDataSource;
  late FakeWorkspaceDataSource workspaceDataSource;

  setUp(() {
    actorDataSource = FakeActorDataSource(delay: Duration.zero);
    workspaceDataSource = FakeWorkspaceDataSource(delay: Duration.zero);
  });

  Widget createLoginPage({VoidCallback? onLoggedIn}) {
    return ProviderScope(
      overrides: [
        actorDataSourceProvider.overrideWithValue(actorDataSource),
        workspaceDataSourceProvider.overrideWithValue(workspaceDataSource),
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

    testWidgets('should display "Create new account" button', (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Create new account'), findsOneWidget);
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
            workspaceDataSourceProvider.overrideWithValue(workspaceDataSource),
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

    testWidgets('should show create form when "Create new account" is tapped',
        (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create new account'));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
    });

    testWidgets('should hide create form when Cancel is tapped', (tester) async {
      await tester.pumpWidget(createLoginPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create new account'));
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);

      // The form may extend beyond the default 800x600 test viewport when
      // actor tiles are also present — scroll Cancel into view before tapping.
      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsNothing);
      expect(find.text('Create new account'), findsOneWidget);
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
      // Create account button still shown
      expect(find.text('Create new account'), findsOneWidget);
    });
  });
}
