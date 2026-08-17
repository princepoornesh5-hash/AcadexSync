# Navigation & Routing Architecture

Acadex implements a unified navigation layout managed via `go_router`.

## Layout Wrapper

- `ShellWrapper` wrapping main content and injecting correct layout based on responsive breakpoints:
  - **Mobile Screens**: Drawer navigation for configuration items, and custom Bottom Navigation.
  - **Tablet Screens**: Vertical `NavRail` on the left.
  - **Desktop / Web Screens**: Full static Drawer pinned on the left.

## Core Navigation Routes

- `/login`: Landing screen for unauthenticated users.
- `/forgot-password`: Recovery flow.
- `/dashboard/{role}`: Home dashboards specific to user roles.
- `/search`: Global search screen.
- `/module/Notifications`: Center for reading and clearing notices.
- `/analytics`: Aggregated graphs and metrics.
- `/analytics/reports`: System queries list.
- `/settings`: Central settings index.
