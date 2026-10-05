# AGENTS.md

Text TV: an Android app that shows SVT Text (Swedish teletext, pages 100-899) through the public texttv.nu API, in teletext colours and block graphics. One screen, built with Flutter. Personal project, kept production-quality.

## Layout
- Repo root is the Flutter project: `lib/`, `test/`, `android/`, `pubspec.yaml` — **run all `flutter`/`dart` commands here**
- Android application id: `com.codedbykay.texttv`; API `app` value: `texttv_android`
- `.agents/` holds the guidance below; `README.md` is for people

## Read before working
Start with the index in [`.agents/README.md`](.agents/README.md), then:
- Any Dart/Flutter code → [.agents/flutter-best-practices.md](.agents/flutter-best-practices.md)
- New screen, widget or service; where code lives; how Text TV behaves → [.agents/architecture.md](.agents/architecture.md)
- Manifest, Gradle, signing, permissions → [.agents/android.md](.agents/android.md)
- Tests / finishing work → [.agents/testing-and-quality.md](.agents/testing-and-quality.md)

## Non-negotiables
1. `model/` is pure Dart and unit-tested; UI only renders state and forwards input.
2. The network is reached only through `TextTvRepository`; tests use fakes and the saved fixtures in `test/fixtures/`, never the live site.
3. The font is bundled; nothing is downloaded at runtime except the page asked for.
4. Dispose every controller/focus node/timer; check `mounted` after awaits.
5. Chrome colours and metrics come from `lib/ui/theme.dart`; page colours from the teletext palette in `lib/ui/tv_row.dart`.
6. Send this app's own `app` id to texttv.nu (`texttv_android`), never another app's.
7. Before calling work done: `dart format`, `flutter analyze`, `flutter test` all clean (and `flutter build apk --debug` after touching `android/`).
8. Small steps; add or update a test with every behaviour change.
9. The improvement backlog (offline cache, zoom, search, ...) is on hold until the user says the ported viewer is working; do not start it unprompted.
