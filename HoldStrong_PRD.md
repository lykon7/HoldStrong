# HoldStrong — Product Requirements Document

**Version:** 1.1  
**Author:** LYKON  
**Date:** April 2026  
**Status:** Draft

---

## 1. Overview

### 1.1 What Is This?

HoldStrong is a lightweight, offline-first Android application built for one purpose: making discipline feel like winning. When the user resists an impulse — food, spending, anything — they log what it would have cost them. That amount is tracked as saved, measured against a personal goal, and thrown back at the user as a concrete victory.

The app operates in two parallel modes that reinforce each other:

- **Financial mode:** Every craving resisted saves real money toward a real goal — a motorcycle, a house, anything with a price tag.
- **Fitness mode:** Every junk food craving resisted is a health decision. The app tracks both the Rs saved and an optional calorie estimate avoided.

HoldStrong is not a budgeting tool. It is not a calorie counter. It is a **discipline engine** — a fast, satisfying feedback loop that makes the act of not giving in feel like the win it actually is.

---

### 1.2 Problem Statement

Impulse spending on food is a silent financial drain. The deeper problem is psychological: resisting a craving in the moment feels like getting nothing. There is no visible reward for discipline. The money you saved is invisible. The health benefit is abstract.

HoldStrong makes both payoffs concrete and immediate — every single time.

---

### 1.3 Target User

- **Persona:** LYKON — a CS undergraduate on a tight budget with real financial goals and a body he wants to reclaim. Feels the pull of food cravings hard and often. Wants to build discipline, not just track spending.
- **Broader audience:** Anyone using financial restraint and dietary restraint as twin levers of self-improvement.

---

## 2. Core Philosophy

> "Every craving you resist is a brick in the wall of what you actually want."

The app must feel like a personal drill sergeant who respects you — not a wellness app that pats you on the back. Tone is firm, direct, and motivating. Never soft. Never preachy.

- No shame. No guilt. Only forward momentum.
- Celebratory on every logged resist — loudly so.
- Progress-obsessed. Always showing proximity to the goal.
- Brutally fast to open and use. Under 10 seconds from cold launch to logged entry.

---

## 3. Visual and Thematic Identity

### 3.1 Batman Theme

HoldStrong wears a Batman aesthetic — not the cartoon, not the camp. The Christopher Nolan version. Grim, disciplined, purposeful. The visual language should feel like the inside of the Batcave crossed with a tactical operations display.

**Colour Palette:**

| Role | Colour | Notes |
|---|---|---|
| Background (primary) | `#0A0A0A` near-black | The void. Everything lives on this. |
| Background (surface) | `#111318` dark charcoal-navy | Cards, panels, input surfaces |
| Background (elevated) | `#1A1E27` dark slate | Modals, bottom sheets |
| Accent (primary) | `#F0C040` Batman gold | The signal colour. Used for wins, CTAs, progress. |
| Accent (secondary) | `#2A3A5C` dark tactical blue | Used for secondary elements, streaks |
| Text (primary) | `#E8E8E8` off-white | All body text |
| Text (secondary) | `#7A7D8A` muted slate | Labels, timestamps, hints |
| Destructive | `#8B2020` deep crimson | Delete actions, warnings |
| Success pulse | `#F0C040` with glow | Celebration screen accent |

**Typography:**

- **Display and numbers:** `Rajdhani` or `Bebas Neue` — condensed, powerful, no-nonsense. Used for large savings amounts and goal figures.
- **Body and UI:** `IBM Plex Mono` — tactical, technical. Reinforces the discipline-as-system idea.
- No emojis anywhere in the app. Ever.

**Iconography:**

- Minimal line icons. No filled bubbly icons.
- The app icon: a stylised bat silhouette overlaid on a gold hexagon or shield — clean, not literal.
- Progress indicators: angular, not bubbly. Segmented bars or sharp arcs, not soft rounded rings.

**Motion:**

- No bouncy animations. No spring physics.
- Sharp, purposeful transitions. Slide-in from bottom for the log screen. Fade and scale for the celebration screen.
- Celebration: a single gold pulse/ripple effect expanding from the centre — no confetti, no cartoonish effects. One clean, powerful moment.

---

## 4. Feature Requirements

### 4.1 Core Features (MVP)

#### F-01: Quick Craving Log

The single most important screen in the app. Must feel instant.

- Primary action on the home screen: **"I HELD"** — a large, full-width button.
- On tap, the log screen opens immediately. The numeric keyboard is already visible — no extra tap required.
- User inputs:
  - **Amount in LKR** (required) — what they would have spent.
  - **Label** (optional) — what was the craving. Either typed or selected from a personal shortlist displayed as one-tap chips at the top of the screen.
  - **Calorie estimate** (optional, shown only if the active goal type includes fitness) — rough estimate of calories avoided. Pre-filled suggestions appear based on the label (e.g. "KFC" auto-suggests ~800 kcal).
  - **Date/time** — defaults to now. User can adjust if logging retrospectively.
- Confirmation: one tap. The entry saves and the celebration screen fires immediately.
- No confirmation dialogs. No "are you sure?" prompts.

#### F-02: Dual Goal Types

Every goal has a type. The type determines what the app tracks and celebrates.

**Type A — Financial Goal**

User sets a target in LKR. Every logged resist contributes its amount toward the target.

Examples: "Motorcycle", "House fund", "New laptop", "Emergency fund"

Tracked per goal:
- Total LKR saved
- Progress percentage toward target
- Projected completion date (based on rolling 30-day average save rate, if no target date is set)

**Type B — Fitness and Financial Goal**

All of Type A, plus calorie tracking.

The user additionally sets:
- An optional fitness milestone in plain text (e.g. "Get back to 72kg", "Run a 5K without stopping")

The fitness milestone is not numerically tracked — it is a declaration, a reminder, a why. It displays on the goal card and on the celebration screen. Calories avoided per logged resist are tracked cumulatively and displayed separately.

Examples: "Cut the junk / Get my body back", "Save for gym equipment while building the discipline to deserve it"

No body weight input. No BMI. No diet prescription. The app tracks what the user resists, not what the user looks like. The fitness dimension exists to reinforce the why, not to measure the body.

#### F-03: Celebration Screen

After every logged resist, the app shows a full-screen celebration moment.

**Financial display (always shown):**
```
RS 1,400 SAVED
2.4% closer to your Motorcycle
Total saved: RS 58,200 of RS 60,000
```

**Fitness display (shown only if goal type is fitness and financial):**
```
~850 CALORIES AVOIDED
Total avoided this month: 12,400 kcal
"Get your body back" — you are doing it.
```

**Motivational message (dynamic):**
One message rotated from the pre-written bank in Section 9, filled with the amount, goal name, streak count, and progress percentage.

The celebration screen:
- Auto-dismisses after 5 seconds if not tapped
- Dismisses on any tap anywhere on the screen
- Plays the gold pulse animation once on entry
- Never shows emojis

#### F-04: Home Dashboard

Everything visible at a single glance. No scrolling required on the home screen.

Sections (top to bottom):
1. **Active goal card** — goal name, type badge (Financial / Fitness), angular progress bar in gold, LKR saved out of LKR target, percentage complete, current streak count.
2. **"I HELD"** — the primary action button. Dominant. Centred. Always one tap away.
3. **Recent resists feed** — the last 3 logged entries. Amount, label, time elapsed.

No clutter. No widgets. Nothing that does not serve the mission.

#### F-05: History Log

- Full chronological list of all logged resists.
- Each entry shows: amount in LKR, label, date and time, calorie figure if logged.
- Daily and weekly subtotals shown as section headers.
- Swipe left on an entry to delete, with immediate undo via a snackbar — no modal confirmation required.
- Filter by: date range, label, goal.

#### F-06: Goal Management

- Create a goal: name, type, target amount in LKR, optional target date, optional fitness milestone statement.
- Set one goal as active at a time.
- Switch active goal at any time — past resists stay attributed to the goal under which they were logged.
- Mark a goal as completed — triggers a dedicated completion celebration screen, then archives the goal.
- View archived goals and their final stats.

---

### 4.2 Secondary Features (Post-MVP)

#### F-07: Streaks and Milestones

- Daily streak: consecutive days with at least one logged resist.
- Milestone triggers displayed as a banner on the home screen for 24 hours:
  - First resist logged
  - 7-day streak / 30-day streak
  - First RS 5,000 saved / First RS 50,000 saved
  - 10th, 50th, 100th resist logged
  - First goal completed
- No badges or gamification UI beyond a streak counter and milestone banners.

#### F-08: Craving Shortlist

- User-managed list of frequent craving labels with optional default calorie estimates per label.
- Displayed as chips at the top of the log screen.
- Ranked by most recently used. Maximum 8 chips visible; scroll horizontally for more.
- New typed labels are remembered and auto-suggested on subsequent entries.

#### F-09: Weekly Summary Notification

- One opt-in push notification per week (Sunday evening).
- Content: total saved that week, current streak, progress toward active goal.
- No other background activity. No recurring processes. Uses Android AlarmManager via `flutter_local_notifications`.

#### F-10: Stats Screen

- Weekly and monthly bar charts showing LKR saved over time.
- Total calories avoided over time (if fitness goal is or has been active).
- Most common craving labels.
- Longest streak on record.
- Best single resist amount.

#### F-11: Calorie Suggestion Library

- A built-in reference of common Sri Lankan and international food items with rough calorie estimates.
- Used to auto-fill the calorie field when a matching label is typed or selected.
- User overrides persist on the device.

---

## 5. Non-Functional Requirements

### 5.1 Performance

| Requirement | Target |
|---|---|
| App cold start | Under 1 second |
| Log screen open from home | Under 200ms |
| All database operations | Under 100ms |
| APK size | Under 10 MB |
| RAM usage at idle | Under 20 MB |
| RAM usage during active use | Under 40 MB |
| Background processes | Zero (except optional weekly notification) |

These are hard ceilings. The app must perform on mid-range and budget Android devices. If it ever lags, something is wrong.

### 5.2 Offline First

- All data stored locally on the device.
- No internet connection required for any core feature.
- No user accounts. No login. No registration.
- Cloud backup is a future consideration only.

### 5.3 Privacy

- Zero analytics.
- Zero telemetry.
- Zero network calls in the core app.
- All data lives on the device. No exceptions at MVP.

### 5.4 Accessibility

- High contrast text throughout (minimum 4.5:1 ratio on dark backgrounds).
- All tap targets minimum 48dp.
- System font size scaling respected.

### 5.5 Compatibility

- Minimum SDK: Android 8.0 (API 26).
- Target SDK: Latest stable Android.
- No dependency on Google Play Services — must be sideload-capable.

---

## 6. UX and Navigation Model

### 6.1 Screen Map

```
HOME
 |
 |--- "I HELD" button ---> LOG SCREEN ---> CELEBRATION SCREEN ---> HOME
 |
 |--- Bottom navigation tabs:
       |--- HOME (default)
       |--- HISTORY
       |--- GOALS
       |--- STATS (post-MVP)
 |
 |--- Settings icon (top-right of home) ---> SETTINGS SCREEN
```

No nested navigation beyond two levels. No hamburger menus. No drawers. The primary action is always one tap from home.

### 6.2 Interaction Rules

- Numeric keyboard opens immediately on the log screen. No delay, no extra tap.
- No confirmation modals for logging. Trust the user.
- Swipe-to-delete in history with immediate undo snackbar.
- Celebration screen dismisses on any tap or after 5 seconds, whichever comes first.
- Bottom navigation uses icon plus short label.

---

## 7. Data Model

### 7.1 Entities

**Goal**
```
id                  String (UUID)
name                String
type                Enum: financial | fitness_financial
target_amount_lkr   double
currency            String (default "LKR")
fitness_milestone   String? (optional declaration text)
created_at          DateTime
target_date         DateTime? (optional)
is_active           bool
is_completed        bool
completed_at        DateTime?
```

**ResistEntry**
```
id                  String (UUID)
goal_id             String (references Goal)
amount_lkr          double
label               String? (e.g. "KFC", "bubble tea")
calories_avoided    int? (optional, only for fitness goals)
note                String? (optional free text)
logged_at           DateTime
```

**CravingLabel** (shortlist)
```
id                  String (UUID)
name                String
default_calories    int? (user-defined or from suggestion library)
use_count           int
last_used           DateTime
```

### 7.2 Derived Values (computed, not stored)

| Value | Computation |
|---|---|
| total_saved_for_goal | SUM of ResistEntry.amount_lkr where goal_id matches |
| goal_progress_pct | total_saved divided by goal.target_amount_lkr multiplied by 100 |
| current_streak | Count of consecutive calendar days with at least one ResistEntry |
| total_saved_all_time | SUM of all ResistEntry.amount_lkr |
| total_calories_avoided | SUM of ResistEntry.calories_avoided for the active fitness goal |
| projected_completion_date | Derived from rolling 30-day average daily save rate |

---

## 8. Tech Stack

### 8.1 Framework: Flutter (Dart)

Flutter is the correct choice for this project for the following reasons:

- Compiles to native ARM machine code — no JavaScript bridge, no interpreted runtime layer.
- The entire UI and business logic runs in a single efficient Dart VM.
- Meets all performance targets with significant headroom on mid-range Android hardware.
- LYKON already thinks in reactive component models from web work — Dart reads as a fast mental transfer.
- Produces a single APK with no external runtime dependency.
- If iOS is ever needed, the same codebase covers it at near-zero additional cost.

### 8.2 Full Dependency Stack

| Layer | Package | Reason |
|---|---|---|
| Database | `isar` | Fastest local DB in Flutter. Schema-based, zero-copy reads, reactive streams. Ideal for offline-only apps. |
| State management | `riverpod` | Lightweight, testable, minimal boilerplate. Reactive providers wire cleanly to Isar streams. |
| Navigation | `go_router` | Declarative, maintained by the Flutter team. Handles deep links if ever needed. |
| Animations | `lottie` | One lightweight JSON animation file for the celebration gold pulse. No GIFs. |
| Notifications | `flutter_local_notifications` | Scheduled via AlarmManager. Zero background RAM when idle. Post-MVP feature. |
| Currency and date formatting | `intl` | LKR formatting, date formatting, number formatting. |
| ID generation | `uuid` | Local UUID generation for all entities. |
| Simple preferences | `shared_preferences` | Active goal ID, notification preference. |
| Fonts | Bundled as assets | Rajdhani and IBM Plex Mono loaded from bundled asset files, not fetched at runtime. |

### 8.3 What Is Not Included and Why

| Excluded | Reason |
|---|---|
| Firebase or any cloud service | Privacy requirement. No network calls at MVP. |
| Redux or BLoC | Overkill for this scope. Riverpod is sufficient and faster to build with. |
| Any analytics SDK | Zero telemetry is a hard requirement. |
| sqflite or drift | Isar outperforms both on read-heavy reactive patterns for this use case. |
| HTTP client | Not needed. No network calls in the core app. |

### 8.4 Project Structure

```
holdstrong/
|
|-- lib/
|   |-- main.dart                          Entry point, Isar init, ProviderScope
|   |-- app.dart                           MaterialApp, theme, go_router
|   |
|   |-- core/
|   |   |-- theme.dart                     Batman colour palette, typography, component styles
|   |   |-- router.dart                    Route definitions
|   |   |-- constants.dart                 Currency symbol, default labels
|   |   |-- message_bank.dart              All celebration message strings
|   |   |-- calorie_library.dart           Built-in calorie suggestion data
|   |
|   |-- data/
|   |   |-- isar_service.dart              DB singleton, schema registration, lifecycle
|   |   |-- models/
|   |   |   |-- goal.dart                  Isar schema: Goal
|   |   |   |-- resist_entry.dart          Isar schema: ResistEntry
|   |   |   |-- craving_label.dart         Isar schema: CravingLabel
|   |   |-- repositories/
|   |       |-- goal_repository.dart
|   |       |-- resist_repository.dart
|   |       |-- label_repository.dart
|   |
|   |-- domain/
|   |   |-- providers/
|   |   |   |-- goal_providers.dart        Active goal, goal list, derived stats
|   |   |   |-- resist_providers.dart      Entry list, streak, totals
|   |   |   |-- label_providers.dart       Shortlist management
|   |   |-- models/
|   |       |-- celebration_data.dart      DTO passed from log screen to celebration screen
|   |
|   |-- ui/
|       |-- home/
|       |   |-- home_screen.dart
|       |   |-- widgets/
|       |       |-- goal_progress_card.dart
|       |       |-- held_button.dart
|       |       |-- recent_feed.dart
|       |
|       |-- log/
|       |   |-- log_screen.dart
|       |   |-- widgets/
|       |       |-- label_chips.dart
|       |       |-- calorie_input.dart
|       |
|       |-- celebration/
|       |   |-- celebration_screen.dart
|       |   |-- widgets/
|       |       |-- gold_pulse_animation.dart
|       |       |-- message_display.dart
|       |
|       |-- history/
|       |   |-- history_screen.dart
|       |   |-- widgets/
|       |       |-- resist_entry_tile.dart
|       |
|       |-- goals/
|       |   |-- goals_screen.dart
|       |   |-- goal_form_screen.dart
|       |   |-- widgets/
|       |       |-- goal_card.dart
|       |
|       |-- settings/
|           |-- settings_screen.dart
|
|-- assets/
|   |-- animations/
|   |   |-- gold_pulse.json                Lottie: celebration gold pulse
|   |   |-- goal_complete.json             Lottie: goal completion animation
|   |-- fonts/
|       |-- Rajdhani-*.ttf
|       |-- IBMPlexMono-*.ttf
|
|-- test/
|   |-- unit/
|   |-- widget/
|
|-- pubspec.yaml
```

---

## 9. Message Bank — Celebration Copy

Messages rotate randomly from this bank. Dynamic values filled at runtime: `{amount}`, `{goal}`, `{progress}`, `{streak}`, `{calories}`.

No emojis. No exclamation marks used cheaply. Tone: earned, firm, direct.

**Financial messages:**

- "RS {amount} SAVED. That is {progress}% of your {goal}. You are not playing."
- "You looked that craving dead in the eye and said no. RS {amount} locked in."
- "Day {streak}. RS {amount} closer to your {goal}. This is what discipline looks like."
- "The food was not worth it. Your {goal} is. RS {amount} added to the war chest."
- "That craving had a price tag: RS {amount}. You refused to pay it."
- "RS {amount}. Small? Maybe. But you are {progress}% of the way to your {goal} and that is real."
- "Most people give in. You did not. RS {amount} stays where it belongs."
- "You won that round. RS {amount} towards {goal}. Keep going."
- "RS {amount} saved. {progress}% done. The goal is not moving. Neither are you."
- "Discipline is not motivation. It is a decision. You just made it. RS {amount}."
- "The craving lasted a moment. Your {goal} will last a lifetime. RS {amount} saved."
- "You chose the goal over the moment. RS {amount} recorded. Do it again tomorrow."

**Fitness and financial messages:**

- "RS {amount} SAVED. ~{calories} CALORIES AVOIDED. You are building the right version of yourself."
- "That junk would have cost you RS {amount} and set you back {calories} calories. You kept both."
- "RS {amount} towards {goal}. {calories} calories you did not eat. Both wins count."
- "Your wallet and your body are aligned. RS {amount} saved, {calories} kcal avoided."
- "Financial discipline and physical discipline are the same muscle. You just trained it. RS {amount}."
- "You resisted. RS {amount} saved. {calories} calories stayed out of your system. This is the work."
- "The version of yourself you are building does not eat that. RS {amount} saved. {calories} kcal avoided."

**Milestone messages (displayed alongside a regular resist when a milestone is reached):**

- "7-DAY STREAK. RS {amount} just added to a 7-day run of discipline. Do not stop."
- "RS 50,000 SAVED IN TOTAL. That is not a number. That is a decision made {streak} times."
- "100TH RESIST LOGGED. RS {amount}. You are a different person than when you started."
- "GOAL COMPLETE. Every RS saved, every craving refused — it was worth it."

---

## 10. Build Milestones

| Phase | Scope | Estimated Effort |
|---|---|---|
| Phase 1 | Project setup, Isar schema, theme system, navigation shell | 3 to 5 days |
| Phase 2 | Home screen, log screen, celebration screen, goal creation | 5 to 7 days |
| Phase 3 | Fitness goal type, calorie input, calorie library | 3 to 4 days |
| Phase 4 | History screen, goal management, goal completion flow | 3 to 5 days |
| Phase 5 | Streaks, milestones, label shortlist management | 3 to 4 days |
| Phase 6 | Stats screen, weekly notification, full QA pass | 5 to 7 days |

Phases 1 through 4 constitute the MVP. Estimated at 3 weeks of focused part-time development.

---

## 11. Out of Scope

- Cloud sync or user accounts of any kind
- Social or sharing features
- Integration with banking or health APIs
- Automatic spending detection
- iOS version at MVP (Flutter makes it a near-zero-cost future option)
- Monetisation of any kind
- Light theme (the Batman aesthetic is the theme)

---

## 12. Success Criteria

1. Logging a craving resist takes under 10 seconds from cold app launch.
2. The user feels a genuine, earned hit of satisfaction after every logged resist.
3. The user opens the app the next time a craving strikes — by choice, not obligation.
4. After one week of use, real savings are visible and tied to something the user actually wants.
5. The app never lags, never crashes, and never drains the battery.
6. A developer unfamiliar with this project can read this document and build it without ambiguity.

---

*"It is not who I am underneath, but what I do that defines me."*
*— Bruce Wayne*

*Build the discipline. Become the version of yourself that deserves what you are saving for.*
