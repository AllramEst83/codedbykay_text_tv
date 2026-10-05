# Flutter & Dart best practices

Toolchain: Flutter 3.47 / Dart ^3.13 (see `pubspec.yaml`). Dot shorthands
(`.fromSeed(...)`, `.center`) are enabled and used by the template; use them where the type is obvious from context.

## Language
- Sound null safety. No `!` unless a comment or prior check makes it obviously safe; prefer pattern matching or `?? default`.
- Prefer `final`, immutable value classes, and `sealed` classes + exhaustive `switch` expressions for closed sets (e.g. `TextTvResult`).
- Use records for small ad-hoc tuples, classes when the shape has a name or behavior.
- `async`/`await` over raw `.then`. Never leave a `Future` un-awaited without `unawaited(...)` and a reason.
- Public APIs get `///` doc comments explaining *why/contract*, not restating the name. Don't comment the obvious.
- Errors: throw typed exceptions for exceptional cases; return result types for expected failures (a page not in broadcast, a failed read: `TextTvResult`).

## Widgets
- Small, focused widgets as **classes**, not helper methods returning `Widget` (classes get their own rebuild boundary, const-ness, and element).
- `const` constructors and `const` widgets wherever possible. Use `super.key`.
- Keep `build` pure and cheap: no I/O, no allocations of controllers, no timers.
- Rebuild the smallest subtree. State that changes frequently lives in its own tiny widget so the whole screen doesn't rebuild.
- Chrome colours and metrics come from `ui/theme.dart` (`TvColors`, `TvMetrics`), the reader's from `readerPalette`; the page's own colours from `tvColorOf`. No hard-coded colours scattered in widgets.
- Respect `MediaQuery` text scaling and safe areas/insets (keyboard, gesture bar). Never hard-code device sizes.
- Prefer `LayoutBuilder`/flex layouts over fixed sizes.

## State & lifecycle
- Anything with a `dispose()` (`TextEditingController`, `FocusNode`, `ScrollController`, `Timer`, `AnimationController`, `StreamSubscription`) is created in `initState` (or field initializer) and disposed in `dispose()`. No exceptions.
- After any `await` in a `State`, check `if (!mounted) return;` before touching `context`/`setState`.
- Default state management is plain `ChangeNotifier` + `ListenableBuilder`/`ValueListenableBuilder`. Do not add a state-management package unless the plan needs it; if you do, record why in `architecture.md`.
- `setState` only for widget-local ephemeral state.
- Business logic is never in widgets. See [architecture.md](architecture.md).

## Performance
- Avoid work in `build`; cache derived data in the model.
- Cap unbounded collections (the page cache holds 40) and never poll without a stated interval.
- Use `RepaintBoundary` only when profiling shows a need.
- Profile in `--profile` mode on a real device, not debug.

## Dependencies
- Add a package only when it earns its weight. Check pub.dev: maintained (recent release), not discontinued, supports current Android Gradle Plugin/Kotlin, Flutter-favorite or verified publisher preferred.
- Use `flutter pub add <pkg>`; commit `pubspec.lock` (this is an app).
- Wrap third-party/platform APIs behind our own interface so they can be swapped (see architecture). Today the runtime dependencies beyond Flutter are `shared_preferences` (the saved session and settings), `path_provider` (the page cache folder), `flutter_shaders` (the CRT look) and `quick_actions` (the icon's shortcuts).
- Never fetch assets at runtime that the app needs to function offline. **Bundle fonts as assets**, don't rely on `google_fonts` runtime downloads.

## Style & lints
- `dart format .` before finishing. `flutter analyze` must be clean (zero warnings/infos).
- Follow the surrounding code's naming and comment density. Files `snake_case.dart`, one primary public type per file.
- Imports: `package:` imports for `lib/` code (no relative `../..` climbing); relative imports only within the same feature folder.
- Keep files under ~300 lines; split when a file does two jobs.
- Extra lints already enabled in `analysis_options.yaml`: `prefer_single_quotes`, `always_declare_return_types`, `avoid_print`, `unawaited_futures`, `use_build_context_synchronously`, `prefer_final_locals`, `require_trailing_commas`, `directives_ordering`.

## Accessibility & i18n
- Give interactive/visual elements `Semantics` where the default is insufficient: a page row is announced as its trimmed plain text, because its colours and cell painting carry no meaning for a screen reader. Keep touch targets at least 48 dp.
- Keep contrast high: the page is always on black, and the chrome is white or yellow on black.
- User-facing strings live in the ARB files (`lib/l10n/app_en.arb` is the template, `app_sv.arb` the Swedish), read as `context.l10n.name`; add a key to **both** (a test fails if they differ) and write the Swedish as a Swede would say it, not as a word-for-word translation. A choice between strings by a model type (a failure kind, a theme) goes in the `AppWording` extension. Units (`PX`, `x1.25`) are in `ui/formats.dart`, not translated. Tests say what they expect through `en` (`test/fakes/english.dart`), not by repeating the English.
