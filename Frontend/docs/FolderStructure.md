# Acadex Folder Structure

The project follows a standard Feature-First structure where each capability is isolated within a self-contained feature folder, supporting layered Clean Architecture divisions.

## Root Directories

- `lib/`: Main codebase.
  - `app/`: Global configurations, themes, routing, and shared UI assets.
  - `core/`: Core utilities, network clients, state overrides, and common errors.
  - `features/`: All business components structured by feature modules.
  - `main.dart`: Entry point of the application.
- `test/`: Test suites.
  - `widget_test.dart`: Reusable UI checks (e.g. login landing verification).

## Feature Folder Blueprint

Every feature module in `lib/features/` is organized with the following layer divisions:

```
feature_name/
├── data/
│   └── repositories/      # Mock or Firebase repository implementations
├── domain/
│   └── models/            # Feature-specific Data Models
└── presentation/
    ├── providers/         # Riverpod Notifiers and State Providers
    ├── screens/           # Main UI screens/pages
    └── widgets/           # Sub-components and feature-specific cards
```

## Current Feature Modules

- `auth/`: User sessions, roles, credentials, and demo role switcher.
- `academic_structure/`: Departments, courses, academic years, semesters, sections, subjects, faculty and students.
- `attendance/`: Student and Faculty attendance logging, class lists, and history.
- `profile/`: User profile updates and personal details.
- `settings/`: System configurations, theme switching, language preferences, and notification overrides.
- `search/`: Global unified search system with query indexing and filters.
- `notifications/`: Notification center, badge counting, read/unread states, and settings filters.
- `analytics/`: Attendance analysis dashboard, insights engine, risk calculators, trends, and reports.
