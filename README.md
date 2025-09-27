# ShopSphere — E-commerce Flutter App

A  e-commerce Flutter app (ShopSphere) built with practical separation of concerns and testability in mind. The codebase uses BLoC for state management, a service layer for API and storage, and local persistence for offline scenarios.

## Quick links
- Project root: `lib/`
- Tests: `test/`


## Setup (Windows / PowerShell)

**Prerequisites**
- Flutter SDK (project targets Dart SDK >= 3.8.1 as specified in `pubspec.yaml`)
- Android Studio or VS Code with Flutter extensions
- An Android or iOS emulator / physical device

**Install and run locally**
```powershell
# clone
> git clone <repository-url>
> cd ecommerce

# fetch dependencies
> flutter pub get

# run tests
> flutter test

# run the app on a connected device / emulator
> flutter run
```

_Tip: If you add or update dev-dependencies, re-run `flutter pub get`._

## What this repo contains (high-level)
- `lib/` — app source
  - `main.dart` — app entry and MultiBlocProvider wiring
  - `bloc/` — business logic (BLoC classes and events/states)
  - `services/` — API, storage, and database abstractions
  - `screens/` — screen widgets (auth, product list, profile, etc.)
  - `widgets/` — reusable UI components (buttons, cards, text fields)
- `test/` — unit and widget tests (uses `mocktail` and `bloc_test`)
- `pubspec.yaml` — dependencies


## Solution overview and approach

This section describes how the app is organized and the reasoning behind the core implementation choices. It is written to help a developer quickly understand the runtime flow, responsibilities of each layer, and how to extend or test the system.

### High-level goals
- Clear separation of concerns so UI code never performs network or database I/O directly.
- Deterministic, unit-testable business logic (BLoCs) with small, well-defined inputs (events) and outputs (states).
- Resilient UX: prefer local cached data and gracefully fall back to it when the network is unavailable.

### Primary building blocks
- **UI (screens & widgets):** lightweight, declarative Flutter widgets that render state and send user intents as BLoC events.
- **BLoC layer (`lib/bloc/*`):** contains business logic components that subscribe to events and emit states. BLoCs orchestrate calls to services and apply business rules (validation, merging server/local data, retry/backoff decisions).
- **Services (`lib/services/*`):** small, single-purpose classes that wrap external side-effects (HTTP API clients, local DB, secure storage). BLoCs treat services as black-box collaborators and call them through small, testable interfaces.
- **Models (`lib/models/*`):** immutable value objects used across layers (products, cart, user session). `equatable` is used widely to make equality checks predictable.

## Data flow (typical request)
1. User taps a button in a screen widget.
2. Widget dispatches an Event to the appropriate BLoC (for example, `CartAddItem`).
3. BLoC handles the event: it may immediately update local state, call a `DatabaseService` to persist the change, and then (optionally) call `CartApiService` to sync with the server.
4. BLoC emits new states which the UI observes and rerenders.

### Service and sync strategy
- **Local-first:** cart and wishlist are stored in the local `sqflite` database so screens can show data immediately. Writes are persisted locally first.
- **Background sync:** BLoCs will attempt to push local changes to the remote API (via `CartApiService`) when connectivity is available. Syncs are best-effort and guarded with try/catch; on failures the app keeps local changes and retries on the next opportunity.
- **Token handling:** authentication tokens are stored securely (via `flutter_secure_storage` wrapper). `AuthBloc` exposes refresh-token flow handling — unit tests mock and control this behavior.

### Testability and how tests hook into the system
- **Injection points:** several BLoCs expose small injectable hooks or factories (for example `loginFn`, `storeUserSessionFn`, `databaseServiceImpl`) so tests can provide deterministic responses without relying on network or persistent storage.
- **Unit tests:** focus on BLoC behavior. Typical test pattern:
  1. Arrange — create mocks/stubs and wire injectable hooks.
  2. Act — create the BLoC and add an event.
  3. Assert — expect a sequence of emitted states.
- **Widget tests:** keep them deterministic by avoiding heavy app-level startup (we use small widget trees in tests, or provide minimal test-only providers to satisfy listeners).

### Error handling and resilience
- BLoCs use small try/catch blocks around service calls and map failures into error states (for example `AuthError`, `CartWishlistError`).
- UI surfaces meaningful messages for recoverable errors and allows retry via user actions.

### Extending the app
- Add a new feature by creating:
  - models for the data shape
  - a service that implements the external calls and a local storage contract if needed
  - a BLoC that encapsulates the business rules and exposes events and states
  - screens/widgets that dispatch events and render states
- Keep tests small and focused: unit test the BLoC, and add a lightweight widget test if the UI requires special behavior.

_This overview complements the more detailed architecture notes further below. If you want, I can add a sequence diagram or a short example showing a login flow with the exact events/states and service calls._


## Architecture decisions (why these choices)

1) **BLoC (flutter_bloc)**
- Why: clear separation between UI and business logic, good tooling for testing, and predictable state transitions.
- Tradeoffs: somewhat more boilerplate than single-class state approaches, but scales better for medium-sized apps.

2) **Service layer (AuthApiService, CartApiService, DatabaseService, SecureStorageService)**
- Why: external side-effects (HTTP, DB, secure storage) live behind small, testable interfaces. This keeps BLoCs focused on state and orchestration.

3) **Testability via injection**
- Auth and other blocs expose small injectable hooks (for example `loginFn`, `storeUserSessionFn` in `auth_bloc.dart`, and `databaseServiceImpl` factory in `cart_wishlist_bloc.dart`) so tests can control responses without editing production code.
- Benefit: deterministic unit tests, faster CI, and easier edge-case coverage (token refresh, offline fallback).

4) **Offline-first considerations**
- `sqflite` is used for local data storage (cart/wishlist). The app prefers local cache and syncs with APIs when available.
- Benefit: improved UX on flaky networks and cheaper repeated network calls.

5) **Minimal and focused third-party dependencies**
- Project uses `flutter_bloc`, `equatable`, `sqflite`, `flutter_secure_storage` and other pragmatic packages. Dev test libs include `mocktail` and `bloc_test`.
- Tradeoffs: keeping dependencies minimal reduces churn and security surface area while providing the necessary tooling.

## How to run tests and debug
- **Run all tests**
```powershell
> flutter test
```
- **Run a single test file**
```powershell
> flutter test test/auth_bloc_test.dart
```
- **Analyze code for issues**
```powershell
> flutter analyze
```

_If a test fails locally, read the failure message, update the mock/stub that injects the dependency used by the bloc, and re-run the test. BLoC tests generally follow the pattern:_
1. Inject test doubles
2. Instantiate the bloc
3. Add an event
4. Expect a sequence of states

## Explanation of architecture decisions

Below are the major architecture decisions made in this codebase, the rationale for each, trade-offs, and pointers to where the patterns are implemented in the repository.

1) **Use BLoC for state management**
- Rationale: BLoC enforces a clear event -> state flow which simplifies reasoning about app behavior and makes unit testing straightforward.
- Implemented: `lib/bloc/*` (see `lib/bloc/auth/auth_bloc.dart`, `lib/bloc/cart_wishlist/cart_wishlist_bloc.dart`).
- Trade-offs: more scaffolding and verbosity compared to simpler approaches (e.g., `setState` or `ChangeNotifier`) but scales better for complex flows and multi-screen coordination.

2) **Keep side-effects in a service layer**
- Rationale: HTTP calls, database access, and secure storage are single-responsibility services so BLoCs can remain pure orchestration layers.
- Implemented: `lib/services/*` (for example `AuthApiService`, `CartApiService`, `DatabaseService`, `SecureStorageService`).
- Trade-offs: one additional layer to maintain but offers clearer contracts and easier mocking for tests.

3) **Make external dependencies injectable for tests**
- Rationale: Tests should never rely on the real network or disk. Simple injection points (function variables or factories) let tests override behavior with mocks.
- Implemented: `auth_bloc.dart` exposes `loginFn`, `storeUserSessionFn` etc.; `cart_wishlist_bloc.dart` exposes `databaseServiceImpl` factory.
- Trade-offs: a small amount of indirection in production code; the benefit is much faster, deterministic tests and fewer integration-test-only failures.

4) **Local-first / offline-friendly design**
- Rationale: Provide immediate UI feedback and offline resilience by storing user-visible state (cart, wishlist) in local storage and syncing to the server later.
- Implemented: `DatabaseService` and usage in `CartWishlistBloc`.
- Trade-offs: must handle sync conflicts and merge strategies. The current app uses a simple last-write or local-first approach; for production, consider conflict resolution strategies or server-side merging.

5) **Minimal, pragmatic dependency set**
- Rationale: Use libraries that add clear value (BLoC, equatable, sqflite) and avoid heavy UI or utility dependencies unless necessary.
- Trade-offs: re-implementing small utilities may be needed; advantage is fewer security updates and simpler upgrades.

6) **Testing strategy**
- Unit tests for BLoCs are the primary focus (fast, deterministic). Use `mocktail` and `bloc_test` to stub services and assert state sequences.
- Widget tests are limited and targeted — prefer unit tests for business logic, and make widget tests as small and deterministic as possible.

7) **CI and release notes (suggested)**
- Add a light CI pipeline that runs `flutter analyze` and `flutter test` on each PR. Optionally run `flutter build` in release mode on release branches.

