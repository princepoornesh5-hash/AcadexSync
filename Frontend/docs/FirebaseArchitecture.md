# Firebase Foundation Architecture

This document describes the architectural abstractions implemented to integrate Firebase into the Acadex project incrementally.

## Architectural Layers

```
┌──────────────────────────────────────────────────────────┐
│                       UI / Screens                       │
└─────────────────────────────┬────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────┐
│                    Riverpod Providers                    │
└─────────────────────────────┬────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────┐
│                  Repository Interfaces                   │
└──────────────────────┬──────────────┬────────────────────┘
                       │              │
       ┌───────────────▼──┐        ┌──▼────────────────┐
       │ MockRepository   │        │ FirebaseRepository│
       └──────────────────┘        └──────────┬────────┘
                                              │
                                   ┌──────────▼────────┐
                                   │ Firebase Services │
                                   └──────────┬────────┘
                                              │
                                   ┌──────────▼────────┐
                                   │   Firebase SDK    │
                                   └───────────────────┘
```

## Layer Responsibilities

1. **Repository Interfaces (Domain Layer)**: Abstract class definitions that detail the operations. No database-specific classes should leak here.
2. **Mock Repository**: Simulates data retrieval locally using in-memory structures or local files.
3. **Firebase Repository**: Implements the repository interface. Communicates with **Firebase Services** to write and read data.
4. **Firebase Services (Service Layer)**: Thin wrapper classes around actual Firebase instances (e.g. `FirebaseAuthService`). Helps in error mapping and isolation.

## Graceful Fallback Mode

At application startup, `FirebaseInitializer` parses the environment settings. If keys are missing (such as running in debug/local developer mode without keys), the initialization layer sets a `fallbackMockActive` flag.
In fallback mode:
- Database, Auth, and Storage service wrappers operate in local offline simulation, avoiding initialization crashes.
