import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_actor_datasource.dart';
import 'package:notexlper/data/datasources/local/fake_auth_datasource.dart';
import 'package:notexlper/data/datasources/local/fake_workspace_datasource.dart';
import 'package:notexlper/data/repositories/auth_repository_impl.dart';
import 'package:notexlper/presentation/pages/auth_page.dart';
import 'package:notexlper/presentation/providers/actor_providers.dart';
import 'package:notexlper/presentation/providers/auth_providers.dart';
import 'package:notexlper/presentation/providers/workspace_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeAuthDataSource authDataSource;
  late FakeActorDataSource actorDataSource;
  late FakeWorkspaceDataSource workspaceDataSource;

  const submitBtnKey = Key('auth-submit-btn');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authDataSource = FakeAuthDataSource(delay: Duration.zero);
    actorDataSource = FakeActorDataSource(delay: Duration.zero);
    workspaceDataSource = FakeWorkspaceDataSource(delay: Duration.zero);
  });

  Widget createAuthPage({VoidCallback? onAuthenticated}) {
    return ProviderScope(
      overrides: [
        authDataSourceProvider.overrideWithValue(authDataSource),
        actorDataSourceProvider.overrideWithValue(actorDataSource),
        workspaceDataSourceProvider.overrideWithValue(workspaceDataSource),
        authRepositoryProvider.overrideWith(
          (ref) => AuthRepositoryImpl(dataSource: authDataSource),
        ),
      ],
      child: MaterialApp(
        home: AuthPage(onAuthenticated: onAuthenticated ?? () {}),
      ),
    );
  }

  group('AuthPage', () {
    testWidgets('shows Create Account and Sign In tabs', (tester) async {
      await tester.pumpWidget(createAuthPage());

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('shows app name', (tester) async {
      await tester.pumpWidget(createAuthPage());

      expect(find.text('Notexlper'), findsOneWidget);
    });

    testWidgets('Create Account tab has username, password and confirm fields',
        (tester) async {
      await tester.pumpWidget(createAuthPage());

      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm password'),
          findsOneWidget);
    });

    testWidgets('Remember Me switch is ON by default', (tester) async {
      await tester.pumpWidget(createAuthPage());

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('shows validation error when username is empty', (tester) async {
      await tester.pumpWidget(createAuthPage());

      await tester.tap(find.byKey(submitBtnKey));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('shows validation error when password is too short',
        (tester) async {
      await tester.pumpWidget(createAuthPage());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'alice');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.byKey(submitBtnKey));
      await tester.pumpAndSettle();

      expect(find.text('At least 6 characters'), findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match',
        (tester) async {
      await tester.pumpWidget(createAuthPage());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'alice');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'pass123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'), 'different');
      await tester.tap(find.byKey(submitBtnKey));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Sign In tab shows username and password but no confirm field',
        (tester) async {
      await tester.pumpWidget(createAuthPage());

      // Tap the Sign In tab (first occurrence = the tab).
      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm password'),
          findsNothing);
    });

    testWidgets('successful sign-up calls onAuthenticated', (tester) async {
      var called = false;
      await tester
          .pumpWidget(createAuthPage(onAuthenticated: () => called = true));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'newuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'pass123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'), 'pass123');
      await tester.tap(find.byKey(submitBtnKey));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('successful sign-in calls onAuthenticated', (tester) async {
      // FakeAuthDataSource seeds "me" → "actor-1".
      // FakeActorDataSource seeds actor-1 with name "Me".
      var called = false;
      await tester
          .pumpWidget(createAuthPage(onAuthenticated: () => called = true));

      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'me');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password');
      await tester.tap(find.byKey(submitBtnKey));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('shows snack bar on sign-in failure', (tester) async {
      await tester.pumpWidget(createAuthPage());

      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'nobody');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'wrong');
      await tester.tap(find.byKey(submitBtnKey));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
