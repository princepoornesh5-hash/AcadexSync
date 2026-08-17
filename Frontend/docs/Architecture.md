# Acadex System Architecture

Acadex is built using a clean, layered architecture designed to keep business logic separate from the user interface and ready for backend integration (e.g. Firebase).

## Architectural Layers

```
┌─────────────────────────────────────────────────────────┐
│                       UI / Widgets                      │
│                  (Presentation Layer)                   │
└────────────────────────────┬────────────────────────────┘
                             │ watches / reads
┌────────────────────────────▼────────────────────────────┐
│                    Riverpod Providers                   │
│                      (State Layer)                      │
└────────────────────────────┬────────────────────────────┘
                             │ calls
┌────────────────────────────▼────────────────────────────┐
│                  Repository Interfaces                  │
│                     (Domain Layer)                      │
└────────────────────────────┬────────────────────────────┘
                             │ implements
┌────────────────────────────▼────────────────────────────┐
│               Mock / Firebase Repositories              │
│                      (Data Layer)                       │
└─────────────────────────────────────────────────────────┘
```

1. **Presentation Layer (UI)**: Consists of standard Flutter widgets, screens, and custom components. The UI is completely reactive and does not contain business logic. It observes Riverpod providers to update its state.
2. **State Layer (Riverpod Providers)**: Manages application state, handles user actions, triggers repository calls, and propagates data updates back to the UI. Includes state caching, notifications notifier, and analytics calculations.
3. **Domain Layer (Repository Interfaces)**: Abstract contracts defining what actions can be taken (e.g., `getStudentAttendance`, `markNotificationRead`). This layer ensures the UI/State layers do not know how data is retrieved.
4. **Data Layer (Repository implementations & Mock Sources)**: Implements the Repository Interfaces. Currently, these are Mock implementations containing robust mock datasets, but they can easily be replaced by Firebase implementations.

## Design Patterns

- **Dependency Injection**: Facilitated via Riverpod providers. UI components depend only on providers, and implementation repositories are injected into providers.
- **Optimistic UI Updates**: Implemented in features like the Notification Center, where the UI updates instantly to mark items as read before the repository operation completes.
- **Role-Aware Processing**: All services, global searches, and dashboard metrics calculate data context-sensitively based on the current user's authenticated role.
