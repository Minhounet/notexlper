# NOTEXLPER

A checklist and task management app with reminders, inspired by Google Keep.

## Features (Planned)

- Checkbox-based notes/checklists
- Due dates for tasks
- Reminder notifications
- Clean Architecture for testability

## Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.2.0 or higher

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/notexlper.git
cd notexlper

# Get dependencies
flutter pub get

# Run in development mode (with fake data)
flutter run --dart-define=ENV=dev

# Run in production mode
flutter run --dart-define=ENV=prod
```

### Running Tests

```bash
flutter test
```

### Building APK

```bash
flutter build apk --release --dart-define=ENV=dev
```

## Architecture

This project follows Clean Architecture principles:

- **Domain Layer**: Business logic, entities, and repository interfaces
- **Data Layer**: Repository implementations and data sources
- **Presentation Layer**: UI and state management (Riverpod)

## CI/CD

APK builds are automatically generated on every push via GitHub Actions.
Download the latest APK from the Actions tab > Artifacts.

## License

MIT
