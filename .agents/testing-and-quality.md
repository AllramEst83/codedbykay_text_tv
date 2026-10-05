# Testing & quality

Run all Flutter commands from the repo root.

## Definition of done
Before saying work is complete, run and report results of:
```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
All must pass (CI runs the same, plus `flutter build apk --debug`). If something can't be run (e.g. no device), say so explicitly; don't claim it works. For UI behaviour, also check on a device or emulator with `flutter run` when possible.

## What to test
- **Unit tests (most tests live here)**: the texttv.nu client (`test/services/text_tv_test.dart`), the HTML parser and block-graphics decoder, page layout maths (`tv_layout`), headline extraction, and the cache.
- **Widget tests**: `test/ui/text_tv_screen_test.dart` drives the screen with `FakeTextTvRepository`: opening, filling the screen, arrows, shortcuts, links, the number pad, parts and swipes, back, failure/retry/refresh. `test/app_test.dart` checks the app opens on the viewer.
- **No network, no platform in tests**: `FakeHttpFetcher` and `FakeTextTvRepository` in `test/fakes/`. Real answers from texttv.nu are saved in `test/fixtures/` (pages 100, 104, 377); never hit the live API from a committed test.
- When texttv.nu changes shape, save the new real answer as a fixture and make the parser pass it; do not loosen the parser's "everything unexpected is null" rule.

## Conventions
- Test file mirrors source path: `lib/model/tv_layout.dart` → `test/model/tv_layout_test.dart`.
- Arrange/act/assert; one behaviour per test; names describe behaviour.
- Hand-written fakes over mocking libraries.
- Write the failing test first for bugs; add a regression test with every fix.
- Deterministic tests: no wall-clock, network or randomness without injection.
- `flutter test` does not load the pixel font, so text layout is checked by geometry (rects, sizes), not by eye. Size-based assertions are easy to write so they pass for the wrong reason: when adding one, reintroduce the bug and confirm the test fails.
- Tests load fixtures by file path relative to the repo root (`test/fixtures/...`), so run `flutter test` from the root.

## Review checklist
- [ ] No logic in widgets; parsing, layout maths and caching live in `model/` / `services/`
- [ ] Every controller/focus node/timer disposed; `mounted` checked after awaits
- [ ] Only the newest page request may update the screen
- [ ] Works with no network: a clear failure and TRY AGAIN, never a crash
- [ ] Chrome colours from `ui/theme.dart`; strings in `messages.dart`; the grid width is `textTvColumns`
- [ ] No new dependency without checking it's maintained
- [ ] Analyze clean, formatted, tests pass
