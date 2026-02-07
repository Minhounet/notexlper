# NOTEXLPER - Project Context

## Overview
A mobile checklist/task management app inspired by Google Keep, built with Flutter.
Focus on checkbox notes with due dates and reminder notifications.

## Tech Stack
- **Framework**: Flutter (Android & iOS)
- **Backend**: Supabase (future)
- **State Management**: Riverpod
- **Architecture**: Clean Architecture

## Project Structure
```
lib/
├── core/                     # Shared utilities
│   ├── error/                # Failure classes
│   ├── usecases/             # Base use case class
│   └── constants/            # App constants
├── domain/                   # Business logic (pure Dart)
│   ├── entities/             # Business objects
│   ├── repositories/         # Abstract repository interfaces
│   └── usecases/             # Application use cases
├── data/                     # Data layer
│   ├── datasources/          # Data sources (local/remote)
│   │   ├── local/            # Fake/local implementation
│   │   └── remote/           # Supabase implementation
│   ├── models/               # Data models (JSON serialization)
│   └── repositories/         # Repository implementations
├── presentation/             # UI layer
│   ├── pages/                # Screen widgets
│   ├── widgets/              # Reusable widgets
│   └── providers/            # Riverpod providers
└── main.dart                 # Entry point
```

## Key Entities
- **ChecklistNote**: A note containing multiple ChecklistItems
- **ChecklistItem**: A single task with checkbox state
- **Reminder**: Due date + notification settings

## Environment Strategy
- **Dev**: Uses `FakeDataSource` (in-memory)
- **Prod**: Uses `SupabaseDataSource` (real backend)

Configured via `--dart-define=ENV=dev|prod`

## Testing Strategy
- Unit tests for use cases and repositories
- Widget tests for critical UI components
- Integration tests for complete flows
- **TDD approach**: Write tests first, then implement

Test files mirror lib/ structure in test/

## Commands
```bash
# Run in dev mode (fake data)
flutter run --dart-define=ENV=dev

# Run in prod mode
flutter run --dart-define=ENV=prod

# Run tests
flutter test

# Build APK
flutter build apk --release --dart-define=ENV=dev
```

## CI/CD - GitHub Actions

### Workflow Behavior
- **Trigger**: Every push to `main`, `develop`, `claude/*` branches
- **Steps**:
  1. Analyze code (`flutter analyze`)
  2. Run tests (`flutter test`)
  3. Build APK (`flutter build apk`)
  4. Create/update `dev-latest` release with APK

### Download APK
Go to **GitHub > Releases > dev-latest** to download the latest APK.

### IMPORTANT: Workflow Verification
**Before considering a task complete, ALWAYS verify the GitHub Actions workflow passes:**

1. Push your changes
2. Go to GitHub > Actions tab
3. Wait for the workflow to complete
4. Ensure ALL steps pass:
   - ✅ Analyze code (no errors)
   - ✅ Run tests (all tests pass)
   - ✅ Build APK (builds successfully)
   - ✅ Create release (APK uploaded)

**If workflow fails:**
- Check the error logs
- Fix the issue
- Push again
- Repeat until green

### Common CI Issues
- **Lint warnings**: Fix or add to `analysis_options.yaml` exceptions
- **Test failures**: Check timer handling, async operations
- **Build failures**: Verify Android config, pubspec.yaml
- **Gradle issues**: Ensure all android/ files are present

## Conventions
- Entity names: PascalCase
- File names: snake_case
- Tests: `*_test.dart`
- One class per file (except small related classes)
- Commit messages: `type: description` (feat, fix, refactor, test, docs)

## Flutter Widget Testing Tips
- Use `tester.pump(duration)` to advance timers
- Use `tester.pumpAndSettle()` for animations
- Cancel timers in `dispose()` to avoid "pending timer" errors
- Use short durations in tests (e.g., 100ms instead of 2s)
