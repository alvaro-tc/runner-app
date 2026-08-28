# PaceUp contributor guide

## Project

PaceUp is a Flutter 3.44+ / Dart 3.12 running app. The user-facing app is in `lib/`, with feature-first modules under `lib/features/`, shared UI under `lib/shared/`, and cross-cutting services and design tokens under `lib/core/`.

The app currently mixes real API-backed flows (auth, home, races) with local repositories for some features. Dependency wiring belongs in `lib/app/dependencies.dart`; do not bypass domain repository interfaces from presentation code.

## Architecture rules

- Keep feature code organized as `domain`, `data`, and `presentation`.
- Domain code must not depend on Flutter, networking, or concrete data sources.
- Presentation reads providers and depends on domain contracts, never directly on `data`.
- Use Riverpod providers according to the need: async screen data with `AsyncNotifierProvider`, synchronous state with `NotifierProvider`, derived values with `Provider`, and continuous flows with stream providers.
- Use `Result<T>` and the failure hierarchy in `lib/core/error/` at repository boundaries; exceptions should not cross layers.
- Use GoRouter and keep route constants in `lib/app/router/app_routes.dart`.

## UI and localization

- Use semantic design-system accessors such as `context.colors`, `context.text`, `AppSpacing`, `AppRadius`, and `AppSizes`. Do not add raw colors, ad-hoc text styles, or magic dimensions in screen widgets.
- User-visible strings belong in `lib/l10n/arb/` and are accessed through `context.l10n`. Regenerate localization with `flutter gen-l10n` or `make l10n`.
- Preserve both Spanish and English translations.
- Loading, empty, and error states are required for async screens. Prefer skeletons over centered spinners.

## Commands

```text
flutter pub get
make fmt
make analyze
make test
make i18n-guard
flutter test --update-goldens
make run
make run-web
make run-local
```

`make analyze` and `make test` regenerate localization first. API configuration comes from `.env` or `.env.local` through `--dart-define-from-file`; do not hard-code the base URL or secrets.

## Generated and local files

- Treat `lib/l10n/gen/`, `*.g.dart`, and `*.freezed.dart` as generated output.
- Do not edit build artifacts under `build/` or platform-generated files unless the task specifically targets them.
- The debug route `/dev/showcase` is the visual catalog for shared components and themes.

See `ARCHITECTURE.md` for the complete design-system, state, navigation, and feature-addition conventions, and `README.md` for setup and runtime details.
