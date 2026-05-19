# HoldStrong

HoldStrong is a discipline tracking application built with Flutter. It is designed to help users track resisted cravings, measure their progress toward specific goals, and manage their personal finances through income, expenses, and fund tracking.

## Features

- **Discipline Tracking**: Log every time you resist a craving. Track the money saved and calories avoided.
- **Goal Management**: Set financial or fitness goals with target amounts. Visualize your progress and projected completion dates.
- **Streak Tracking**: Build and maintain momentum by tracking consecutive days of resisting cravings.
- **Expense Logging**: A built-in daily expenses section to log expenditures. View your spend grouped by day, along with daily, weekly, and monthly totals.
- **Income Logging**: Log your daily income from various sources. View your income grouped by day, along with daily, weekly, and monthly totals.
- **Funds Management**: Create custom fund accounts (e.g., Cash, Bank, Wallet) with opening balances. Link your income and expenses to specific accounts to automatically calculate their live balances.
- **Hub**: A central command center for accessing secondary productivity and tracking features.
- **Journaling**: Document your thoughts and daily reflections with auto-saving and swipe-to-delete functionality.
- **Wishlist**: Track items you want to purchase along with their estimated costs, helping you direct your saved funds purposefully.
- **Workout Tracker**: Build a visual gym habit by logging your daily workouts and monitoring your active streaks.
- **To-Do List**: Manage daily tasks and deadlines, complete with overdue highlighting to stay on top of your responsibilities.
- **Data Persistence**: Fast and local data storage powered by Isar Database.

## Technology Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Database**: Isar

## Getting Started

### Prerequisites

- Flutter SDK (>=3.11.0 <4.0.0)
- Dart SDK

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate necessary code files (Isar schemas and Riverpod providers):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## Build

To build a release APK for Android:

```bash
flutter build apk --release
```

To build an App Bundle (AAB) for the Google Play Store:

```bash
flutter build appbundle --release
```
