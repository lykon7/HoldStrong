# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HoldStrong** is a personal discipline tracking app built with Flutter. It helps users track resisted cravings (financially and calorically), manage personal finances (income/expenses/funds), set goals, maintain streaks, and use secondary productivity tools (journal, wishlist, workouts, to-do). All data is stored locally via Isar Database. The app is a single-user, offline-first Android application.

## Commands

```bash
# Install dependencies
flutter pub get

# Generate Isar schemas + Riverpod providers (required after changing any model in lib/data/models/)
dart run build_runner build --delete-conflicting-outputs

# Run the app (debug)
flutter run

# Lint
flutter analyze

# Build release APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release
```

**Always run `dart run build_runner build --delete-conflicting-outputs` after adding or modifying any Isar model** (files in `lib/data/models/`) — this regenerates the `.g.dart` schema and collection files needed at runtime.

## Architecture

### State Management: Riverpod (code-gen style)

The project uses `flutter_riverpod` with code-generated providers. Providers live in two layers:

- **`lib/domain/providers/`** — Business-logic providers. Each concern (expenses, resists, goals, etc.) has its own `*_providers.dart` file. These define:
  - `repositoryProvider` — wraps the corresponding `Repository` with the Isar instance
  - Derived/computed providers (e.g. daily/weekly/monthly totals via `Provider<AsyncValue<double>>.whenData`)
  - `StreamProvider`s for reactive lists (`watchAllEntries()` from the repository)
- **`lib/data/repositories/`** — Data-access layer. Each repository wraps an `Isar` instance and exposes both `Stream<T>` (reactive via `watch(fireImmediately: true)`) and `Future<T>` (one-shot) queries.

**Key pattern:** Every `*_providers.dart` imports its repository and `isarProvider` from `goal_providers.dart`. Riverpod auto- or manual providers depend on the corresponding `StreamProvider` to stay reactive.

### Database: Isar

Models are in `lib/data/models/`. Each model has two files:
- `model_name.dart` — the Isar `@collection` class (hand-written)
- `model_name.g.dart` — generated schema (do not edit directly)

A `main.dart` boot sequence opens all 12 schemas and seeds a default "Cash" `FundAccount` if the database is empty. The `Isar` instance is injected into the Riverpod tree via `isarProvider.overrideWithValue(isar)` in `ProviderScope`.

### Routing: GoRouter

All routes are declared in `lib/core/router.dart` as a `goRouterProvider`. The app uses a `ShellRoute` for the 5-tab bottom navigation (`HOME`, `RESISTS`, `TRANSACTIONS`, `FUNDS`, `HUB`) with top-level routes for `/log`, `/celebration`, `/goals/new`, `/settings`, and `/journal/:date`. There's a redirect guard: if no `activeGoal` exists, the app redirects to `/goals/new`.

### UI Structure

- `lib/ui/` is organized by feature: `home/`, `resists/`, `transactions/`, `expenses/`, `income/`, `funds/`, `goals/`, `log/`, `celebration/`, `settings/`, `hub/`, `journal/`, `wishlist/`, `workout/`, `todo/`, `liabilities/`, `history/`
- Feature screens often have a sub-`widgets/` directory for reusable components
- `lib/ui/home/home_screen.dart` is the main dashboard with goal progress, streak, net graph, and hub shortcuts

### Backup/Export

`BackupService` (`lib/data/backup/backup_service.dart`) serializes all collections to a `.hsbackup` JSON file using per-model `toBackupJson()` / `fromBackupJson()` extension methods in `backup_extensions.dart`. Import merges by UUID (skips duplicates).

### Theming

Dark theme only. Defined in `lib/core/theme.dart`. The app uses two font families — **Rajdhani** (display/headings) and **IBMPlexMono** (body/labels). Currency symbol is hardcoded as `'RS'` in `AppConstants`.

## Important Conventions

- **Currency**: All monetary amounts use `amountLkr` or `amount` fields in the models; the display symbol is `'RS'` from `AppConstants.kCurrencySymbol`
- **UUID**: Every model has a `@Index(unique: true) late String uuid` field. Generate new UUIDs with `const Uuid().v4()` (from the `uuid` package)
- **Isar auto-increment**: `Id id = Isar.autoIncrement` is the internal Isar ID; the `uuid` string is the logical identifier
- **Adding a new model**: (1) Create `model_name.dart` with `@collection` class, (2) Create blank `model_name.g.dart` with `part 'model_name.g.dart';` in the main file, (3) Run `dart run build_runner build --delete-conflicting-outputs`, (4) Add the schema to `main.dart`'s `Isar.open()` list
- **Adding a new repository**: Create it in `lib/data/repositories/`, then create a corresponding provider file in `lib/domain/providers/`
- **Tests**: Only a dummy test exists in `test/widget_test.dart`. The project has no unit or integration test infrastructure.
