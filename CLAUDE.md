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
flutter build apk --release
```

## CI/CD
GitHub Actions builds APK on every push to main branches.
Download APK from Actions artifacts.

## Conventions
- Entity names: PascalCase
- File names: snake_case
- Tests: `*_test.dart`
- One class per file (except small related classes)
