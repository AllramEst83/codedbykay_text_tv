# Text TV

An Android viewer for **SVT Text**, Swedish teletext (pages 100–899), in its own colours and block graphics. It reads the public [texttv.nu](https://texttv.nu) API.

Personal project, built with Flutter.

## Features

- Every page, 100–899, drawn as the 40-column teletext grid: the eight teletext colours, double-height headlines, the block-graphics logo, underlined page links.
- Tap a page number in the page to open it. Swipe left/right to move between the parts of a page and then between pages.
- `<` / `>` arrows (following the site's own neighbouring pages), an always-visible number pad for typing a page number (the box shows `1--` as you type), coloured Fastext keys built from a page's bottom row of links, and shortcuts to 100 NYHETER, 101 INRIKES, 104 UTRIKES, 300 SPORT, 400 VÄDER and 700 INNEHÅLL.
- Reader mode (the glasses button): the page as text reflowed to the screen, with `A-`/`A+` for the text size, five colour schemes (black, grey, beige, paper, high contrast), and options for line spacing, letter spacing, margins and bold. Headlines, links and tables are kept.
- Portrait only.
- A settings page (the gear button) with an optional CRT look for the teletext page: a slight screen bulge, scanlines and a vignette, each adjustable within safe limits and remembered. Taps still land on what you see.
- Back steps through the pages you have read, then leaves the app.
- Opens where you left off: the page, its part and the pages you came through.
- Pages read in the last five minutes are reused; REFRESH asks the site again. Failures say why and offer TRY AGAIN.
- Works offline for pages you have read: they are saved on the phone, shown at once, refreshed behind, and marked "OFFLINE. SAVED 14:32" when the site cannot be reached.
- Bundled pixel font; the only permission is `INTERNET`.

## Build and run

Needs Flutter 3.47 or newer (Dart ^3.13) and the Android SDK.

```
flutter pub get
flutter run                 # on a connected device or emulator
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
```

### Checks

```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

CI runs the same (`.github/workflows/ci.yml`). Tests never touch the network: they use fakes and real answers saved in `test/fixtures/`.

### Release build

`flutter build apk --release` signs with the debug key unless `android/key.properties` exists (git-ignored; see [.agents/android.md](.agents/android.md)).

## How it works

```
TextTvScreen (ui) ──▶ TextTvRepository ──▶ TextTv (texttv.nu client) ──▶ HttpFetcher
        │                                         │
        └──────────────▶ model: TextTvPage, styled rows, layout maths ◀─┘
```

Architecture notes, the behaviour spec and the decisions log are in [.agents/architecture.md](.agents/architecture.md). Contributor and agent guidelines start at [AGENTS.md](AGENTS.md).

## Credits and licence

- Content: SVT Text, relayed by [texttv.nu](https://texttv.nu). The app sends its own `app` id (`texttv_android`) with every request, as the site's API asks.
- Font: [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) by CodeMan38, SIL Open Font License 1.1 (`fonts/OFL.txt`).
- Code: [MIT](LICENSE) © 2026 Kay Wiberg. The bundled font keeps its own licence.
