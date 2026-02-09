# Notexlper Architecture Guide

This document explains **how the code is organized**, **what each widget does**,
and **how the different parts talk to each other**. It targets beginners who know
basic Dart but are new to Flutter and Clean Architecture.

---

## Table of Contents

1. [Big Picture](#1-big-picture)
2. [Clean Architecture Layers](#2-clean-architecture-layers)
3. [Project Structure (file map)](#3-project-structure-file-map)
4. [Domain Layer (pure Dart)](#4-domain-layer-pure-dart)
5. [Data Layer (storage)](#5-data-layer-storage)
6. [Presentation Layer (UI)](#6-presentation-layer-ui)
   - [Pages (screens)](#pages-screens)
   - [Widgets (reusable pieces)](#widgets-reusable-pieces)
   - [Providers (state management)](#providers-state-management)
7. [Widget Glossary](#7-widget-glossary)
8. [How Data Flows](#8-how-data-flows)
9. [How Navigation Works](#9-how-navigation-works)
10. [Testing Strategy](#10-testing-strategy)

---

## 1. Big Picture

Notexlper is a **checklist / task management** app (think "Google Keep for
checkboxes"). The user creates **checklist notes**, each containing multiple
**items** that can be checked off. Items can optionally belong to a **category**
(like "Work" or "Shopping") which gives them a color badge.

```
┌─────────────────────────────────────────────┐
│                   App                       │
│                                             │
│  SplashPage ──> HomePage ──> DetailPage     │
│                      │                      │
│                      └──> CategoryAdminPage │
└─────────────────────────────────────────────┘
```

---

## 2. Clean Architecture Layers

The code follows **Clean Architecture** – three concentric layers where the inner
layers know nothing about the outer ones:

```
┌──────────────────────────────────────────┐
│           PRESENTATION (UI)              │  ← Widgets, Pages, Providers
│  ┌────────────────────────────────────┐  │
│  │          DOMAIN (rules)            │  │  ← Entities, Repository interfaces
│  │  ┌──────────────────────────────┐  │  │
│  │  │       DATA (storage)         │  │  │  ← DataSources, Repository impls
│  │  └──────────────────────────────┘  │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

| Layer | Knows about | Does NOT know about |
|-------|-------------|---------------------|
| **Domain** | Only pure Dart | Flutter, UI, databases |
| **Data** | Domain entities | UI, widgets |
| **Presentation** | Domain + Data | Database internals |

**Why?** This makes it easy to swap storage (e.g. from fake in-memory to
Supabase) without touching the UI, and to test business logic without a phone.

---

## 3. Project Structure (file map)

```
lib/
├── core/                              # Shared utilities
│   ├── constants/
│   │   └── app_constants.dart         # App name, environment flag
│   ├── error/
│   │   └── failures.dart              # Error types (ServerFailure, etc.)
│   └── usecases/
│       └── usecase.dart               # Base class for use cases
│
├── domain/                            # Business logic – pure Dart
│   ├── entities/
│   │   ├── category.dart              # Category (id, name, color)
│   │   ├── checklist_item.dart        # Single checkbox item
│   │   ├── checklist_note.dart        # A note with many items
│   │   └── entities.dart              # Barrel export
│   └── repositories/
│       ├── category_repository.dart   # Abstract: what operations exist
│       └── checklist_repository.dart  # Abstract: what operations exist
│
├── data/                              # Storage implementation
│   ├── datasources/
│   │   └── local/
│   │       ├── fake_category_datasource.dart   # In-memory categories
│   │       └── fake_checklist_datasource.dart  # In-memory checklists
│   └── repositories/
│       ├── category_repository_impl.dart       # Wraps datasource + errors
│       └── checklist_repository_impl.dart      # Wraps datasource + errors
│
├── presentation/                      # Everything the user sees
│   ├── models/
│   │   └── display_mode.dart          # Enum: flat vs grouped-by-category
│   ├── pages/                         # Full-screen views
│   │   ├── splash_page.dart           # Animated splash screen
│   │   ├── home_page.dart             # List of all checklists
│   │   ├── checklist_detail_page.dart # Edit one checklist
│   │   └── category_admin_page.dart   # Manage categories (CRUD)
│   ├── providers/                     # Riverpod state management
│   │   ├── checklist_providers.dart   # Checklist list state
│   │   └── category_providers.dart    # Category list state
│   └── widgets/                       # Reusable UI pieces
│       ├── checklist_card.dart        # Card preview on home page
│       ├── checklist_item_tile.dart   # One checkbox row
│       ├── category_selector.dart     # Chip / "Add category" label
│       ├── category_picker_sheet.dart # Bottom sheet to pick a category
│       ├── category_group.dart        # Group header + items by category
│       ├── category_tile.dart         # Category row in admin list
│       ├── category_form_dialog.dart  # Create/edit category dialog
│       ├── checked_separator.dart     # "── Checked ──" divider line
│       └── display_mode_menu_button.dart # Popup menu for display options
│
└── main.dart                          # App entry point + MaterialApp
```

---

## 4. Domain Layer (pure Dart)

These classes have **no Flutter imports**. They describe the core data.

### `ChecklistItem` (`lib/domain/entities/checklist_item.dart`)

A single to-do inside a checklist.

| Field | Type | Meaning |
|-------|------|---------|
| `id` | `String` | Unique identifier |
| `text` | `String` | What the task says ("Buy milk") |
| `isChecked` | `bool` | Whether the checkbox is ticked |
| `order` | `int` | Position in the list (0, 1, 2…) |
| `categoryId` | `String?` | Optional link to a Category |
| `dueDate` | `DateTime?` | Optional deadline (future feature) |

The `copyWith(...)` method creates a **new** item with some fields changed. This
is important because the entities are **immutable** – you never modify them
directly, you create a copy.

### `ChecklistNote` (`lib/domain/entities/checklist_note.dart`)

A collection of items with a title.

| Field | Type | Meaning |
|-------|------|---------|
| `id` | `String` | Unique identifier |
| `title` | `String` | "Grocery Shopping" |
| `items` | `List<ChecklistItem>` | The actual tasks |
| `createdAt` / `updatedAt` | `DateTime` | Timestamps |

Computed properties:
- `completedCount` – how many items are checked
- `totalCount` – total items
- `sortedItems` – items sorted by their `order` field

### `Category` (`lib/domain/entities/category.dart`)

A color label you can assign to items.

| Field | Type | Meaning |
|-------|------|---------|
| `id` | `String` | Unique identifier |
| `name` | `String` | "Work", "Shopping"… |
| `colorValue` | `int` | Color stored as an integer (e.g. `0xFF2196F3`) |

### Repository Interfaces

`ChecklistRepository` and `CategoryRepository` are **abstract classes** that
define *what* you can do (create, read, update, delete) without saying *how*.
The "how" is in the Data layer.

---

## 5. Data Layer (storage)

### DataSources

`FakeChecklistDataSource` and `FakeCategoryDataSource` store data **in memory**
using plain Dart `List`s. They simulate a real backend with an optional `delay`
parameter (used in tests with `delay: Duration.zero` to skip waiting).

### Repository Implementations

`ChecklistRepositoryImpl` wraps the datasource and catches exceptions, returning
either a **success value** or a **Failure object** using the `dartz` package's
`Either` type:

```dart
// Either<Failure, List<ChecklistNote>>
//   Left  = something went wrong  → Failure
//   Right = success                → data
```

This pattern means the UI never sees raw exceptions – it gets structured errors.

---

## 6. Presentation Layer (UI)

### Pages (screens)

A **page** is a full-screen widget that the user navigates to.

#### `SplashPage` – the loading screen

- Shows the app logo and a spinner for 2 seconds
- After the timer fires, calls `onInitialized()` to switch to HomePage
- **Key Flutter concept**: `Timer` in `initState` / cancelled in `dispose`

#### `HomePage` – the main list

- Watches `checklistListProvider` (Riverpod) for the list of notes
- Shows a loading spinner, an error state, an empty state, or a `ListView`
- Each list item is a `ChecklistCard` widget (extracted to its own file)
- FAB ("Floating Action Button") creates a new checklist and navigates to it

#### `ChecklistDetailPage` – editing a single checklist

This is the most complex page. It manages:
- **Title editing** via a `TextField` + `TextEditingController`
- **Item CRUD**: add, remove, toggle, edit text, change category
- **Display modes**: flat list vs. grouped by category
- **Checked-at-bottom**: checked items sink to the bottom after a short delay
- **Toggle animation**: brief color flash when you check/uncheck an item

State is managed locally in `_ChecklistDetailPageState` using `setState`. The
page delegates visual rendering to extracted widgets.

#### `CategoryAdminPage` – managing categories

- Lists all categories as `CategoryTile` widgets
- FAB opens a `CategoryFormDialog` to create a new category
- Each tile has edit and delete buttons

---

### Widgets (reusable pieces)

These are **smaller, focused UI components** extracted from the pages to keep
each file short and single-purpose.

#### `ChecklistCard` (`widgets/checklist_card.dart`)

Shown on the home page. Previews a checklist:
- Title
- Up to 5 item previews (checkbox icon + text + optional category badge)
- Progress counter ("3/5 done")
- Delete button with confirmation dialog

#### `ChecklistItemTile` (`widgets/checklist_item_tile.dart`)

One row in the checklist detail page:
- `Checkbox` on the left
- `TextField` for the item text
- Delete (×) button on the right
- Optional `CategorySelector` below
- Highlight animation when toggled (green flash for check, blue for uncheck)

**Flutter concept – `AnimationController`**: This widget uses
`SingleTickerProviderStateMixin` to create a smooth fade animation. The
`AnimationController` drives the highlight opacity from 1.0 down to 0.0.

#### `CategorySelector` (`widgets/category_selector.dart`)

A small interactive widget below each checklist item:
- When a category IS selected → shows a `Chip` with the category color and name,
  plus a × to remove it
- When NO category is selected → shows a subtle "Add category" label
- Tapping it opens a `CategoryPickerSheet` bottom sheet

**Flutter concept – `Chip`**: A compact element that represents a tag/label.
Built-in Material widget with optional avatar and delete button.

#### `CategoryPickerSheet` (`widgets/category_picker_sheet.dart`)

A bottom sheet (slides up from the bottom) listing all available categories:
- Each category shown as a `ListTile` with a colored circle
- Selected category has a checkmark
- "No category" option to clear
- "Create new category" option at the bottom

**Flutter concept – `showModalBottomSheet`**: Opens a panel from the bottom edge.

#### `CategoryGroup` (`widgets/category_group.dart`)

Used in "Group by category" display mode. Shows:
- A header row: colored dot + category name + item count
- All items in that category (rendered as `ChecklistItemTile`)

#### `CheckedSeparator` (`widgets/checked_separator.dart`)

A visual divider line with the word "Checked" in the center. Appears between
unchecked and checked items when "Checked at bottom" is enabled.

#### `DisplayModeMenuButton` (`widgets/display_mode_menu_button.dart`)

A `PopupMenuButton` in the app bar with three options:
- Flat view (all items in order)
- Group by category
- Checked at bottom (toggle)

Selected options get a highlighted color and a checkmark icon.

**Flutter concept – `PopupMenuButton`**: Shows a dropdown menu when tapped.

#### `CategoryTile` (`widgets/category_tile.dart`)

A card representing one category in the admin page:
- Colored circle avatar
- Category name
- Edit button → opens `CategoryFormDialog` in edit mode
- Delete button → shows confirmation dialog

#### `CategoryFormDialog` (`widgets/category_form_dialog.dart`)

A dialog for creating or editing a category:
- Text field for the name
- Grid of colored circles to pick a color
- Cancel / Create (or Save) buttons

**This widget is shared** between the category admin page and the checklist
detail page (which needs to create categories inline). Before the refactoring,
this dialog was duplicated in two files.

---

### Providers (state management)

Notexlper uses **Riverpod** to manage state. Here's how the pieces fit:

```
┌────────────────────┐     ┌───────────────────────┐
│  DataSource        │────▶│   Repository           │
│  (in-memory list)  │     │   (wraps datasource)   │
└────────────────────┘     └───────────┬───────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   StateNotifier        │
                           │   (manages list state) │
                           └───────────┬───────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   Widget (UI)          │
                           │   ref.watch(provider)  │
                           └───────────────────────┘
```

#### `checklist_providers.dart`

| Provider | Type | Purpose |
|----------|------|---------|
| `dataSourceProvider` | `FakeChecklistDataSource` | Singleton datasource |
| `checklistRepositoryProvider` | `ChecklistRepository` | Repository instance |
| `checklistListProvider` | `AsyncValue<List<ChecklistNote>>` | The list of all notes |

`ChecklistListNotifier` is a `StateNotifier` that exposes `loadNotes()` and
`deleteNote()`. When it loads, it emits `AsyncValue.loading()`, then either
`AsyncValue.data(notes)` or `AsyncValue.error(...)`.

#### `category_providers.dart`

Same pattern for categories, with `createCategory`, `updateCategory`,
`deleteCategory`, and `loadCategories`.

**Flutter concept – `ref.watch(provider)`**: In a `ConsumerWidget`, calling
`ref.watch(someProvider)` tells Riverpod to rebuild this widget whenever the
provider's value changes. `ref.read(...)` reads the value once without
subscribing to changes (used for one-off actions like delete).

---

## 7. Widget Glossary

Quick reference for Flutter widgets used in this project that you might not know:

| Widget | What it does |
|--------|-------------|
| `Scaffold` | Basic page structure: app bar + body + FAB |
| `AppBar` | Top bar with title and action buttons |
| `FloatingActionButton` | Circular button that floats above content |
| `ListView` / `ListView.builder` | Scrollable list of children |
| `Card` | Elevated container with rounded corners |
| `ListTile` | Standard row: leading icon + title + trailing |
| `Checkbox` | A square that toggles between checked/unchecked |
| `TextField` | Editable text input |
| `TextEditingController` | Controls and reads the text in a `TextField` |
| `Chip` | Compact label with optional avatar and delete |
| `CircleAvatar` | A small circle, often with a color or image |
| `Icon` | A Material Design icon (e.g. `Icons.add`) |
| `IconButton` | An icon that responds to taps |
| `InkWell` | Makes any widget tappable with a ripple effect |
| `GestureDetector` | Detects taps, drags, etc. on any widget |
| `Wrap` | Lays out children in rows, wrapping to the next line |
| `Column` | Vertical layout |
| `Row` | Horizontal layout |
| `Expanded` | Takes remaining space inside a Row/Column |
| `Padding` | Adds space around a widget |
| `SizedBox` | Fixed-size empty space (used for gaps) |
| `Divider` | Horizontal line separator |
| `Container` | Box with decoration (color, border, border-radius) |
| `PopupMenuButton` | Shows a dropdown menu on tap |
| `AlertDialog` | Modal dialog with title, content, action buttons |
| `SafeArea` | Avoids system UI (notch, navigation bar) |
| `PopScope` | Intercepts the back button / swipe-back |
| `AnimatedBuilder` | Rebuilds its child every animation frame |
| `AnimationController` | Drives an animation from 0.0 to 1.0 over time |
| `CurvedAnimation` | Applies an easing curve to an animation |
| `ValueKey` | Tells Flutter "this widget represents this data" |
| `ProviderScope` | Root of Riverpod – wraps the app so providers work |
| `ConsumerWidget` | A widget that can read Riverpod providers |
| `ConsumerStatefulWidget` | Stateful version of ConsumerWidget |

---

## 8. How Data Flows

### Creating a new checklist (example)

```
User taps "New Checklist" FAB on HomePage
  │
  ▼
HomePage._createNewChecklist()
  │  Creates a ChecklistNote object
  │  Calls repository.createNote(note)
  │  Calls checklistListProvider.notifier.loadNotes()
  │  Navigates to ChecklistDetailPage(note: note)
  │
  ▼
ChecklistDetailPage displays the note
  │  User types a title → _updateTitle() → save to repository
  │  User taps + FAB    → _addItem()     → save to repository
  │  User taps checkbox → _toggleItem()  → save + animate
  │
  ▼
User presses back
  │  PopScope.onPopInvokedWithResult triggers loadNotes()
  │  HomePage rebuilds with the updated list
```

### Toggling an item with "checked at bottom" enabled

```
User taps checkbox
  │
  ▼
_toggleItem(itemId)
  │  1. Updates the item's isChecked in local state
  │  2. Saves to repository
  │  3. Sets _pendingMoveItemId (item stays in place visually)
  │  4. Starts a 500ms Timer
  │
  ▼
After 500ms
  │  Timer fires → clears _pendingMoveItemId
  │  _applySorting() now moves the item to the bottom
  │  User sees the item slide down
```

---

## 9. How Navigation Works

Notexlper uses **imperative navigation** with `Navigator.push` / `Navigator.pop`:

```
main.dart
  └── SplashWrapper (StatefulWidget)
        ├── SplashPage  (shown first, for 2 seconds)
        └── HomePage    (after splash timer fires)
              ├── push → ChecklistDetailPage
              └── push → CategoryAdminPage
```

- `Navigator.of(context).push(MaterialPageRoute(...))` – opens a new screen
- `Navigator.pop(context)` – goes back (or the back button)
- `Navigator.pop(context, result)` – goes back and returns a value (used by
  dialogs to return the created Category)

---

## 10. Testing Strategy

Tests live in `test/` and mirror the `lib/` structure.

### Types of tests

| Type | Location | What it tests |
|------|----------|---------------|
| **Entity tests** | `test/domain/entities/` | `copyWith`, `props`, computed properties |
| **Repository tests** | `test/data/repositories/` | Error handling, data flow |
| **Widget tests** | `test/presentation/pages/` | UI rendering, user interactions |

### How widget tests work

```dart
// 1. Create a fake datasource with zero delay (instant)
dataSource = FakeChecklistDataSource(delay: Duration.zero);

// 2. Wrap the page in ProviderScope with overrides
Widget createPage() => ProviderScope(
  overrides: [
    dataSourceProvider.overrideWithValue(dataSource),
  ],
  child: MaterialApp(home: HomePage()),
);

// 3. Pump the widget and interact
await tester.pumpWidget(createPage());
await tester.pumpAndSettle();  // Wait for animations & async
expect(find.text('My Checklist'), findsOneWidget);
```

Key testing patterns:
- `tester.pump()` advances one frame
- `tester.pumpAndSettle()` advances until all animations/timers finish
- `find.text(...)` / `find.byType(...)` / `find.byIcon(...)` locate widgets
- `tester.tap(finder)` simulates a tap
- `tester.enterText(finder, 'text')` types into a TextField

### Running tests

```bash
flutter test              # Run all tests
flutter test test/domain  # Run only domain tests
flutter test --name "should toggle"  # Run tests matching a pattern
```
