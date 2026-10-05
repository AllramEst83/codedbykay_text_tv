# Architecture

A one-screen Android app: a viewer for SVT Text (Swedish teletext, pages 100-899) through the public **texttv.nu** JSON API. The viewer is the home screen; there is no navigation, no persistence and no platform channel. Android needs only the `INTERNET` permission.

Keep the file list below in step with `lib/` as it changes.

## Layers (dependency direction: ui -> model <- services)

```
lib/
  main.dart                  # runApp + wiring: IoHttpFetcher -> TextTv -> LiveTextTvRepository -> TextTvApp
  app.dart                   # TextTvApp: MaterialApp, theme, edge-to-edge black system bars
  messages.dart              # user-facing strings
  model/                     # pure Dart (values and parsers): no platform, no I/O
    styled_text.dart         # TvColor, StyledRun (text + colours + underline + tall + mosaic + link), mergeRuns, plainText
    text_tv_page.dart        # textTvColumns, textTvFirstPage/LastPage, TextTvPage (parts, styledParts, previous/next), TextTvResult (TextTvShown / NotBroadcast / Failed)
    text_tv_html.dart        # parseTextTvHtml: a page's HTML as styled rows (null if not the shape expected, so the plain text is the fallback)
    tv_mosaic.dart           # tvPictureFor(hash): texttv.nu's block-graphics GIFs rebuilt and looked up by CRC-32 (no downloads)
    tv_layout.dart           # tvIsBar / tvTextMargins / tvGutters: the black gutter each side of a page that gives its TEXT equal margins
    text_tv_headlines.dart   # textTvHeadlines(page): the headline lines of a page (no title, bare numbers or navigation); not used by the UI yet
  services/
    http_fetcher.dart        # HttpFetcher: GET a URL, return the body
    io_http_fetcher.dart     # IoHttpFetcher on dart:io: 10 s timeouts, 2 MB cap, UTF-8, new client per request, no retry
    network_exception.dart   # NetworkException(message): the one failure the services throw
    text_tv.dart             # TextTv: the texttv.nu client; page(n) -> TextTvPage? (null = not in broadcast), throws NetworkException
    text_tv_repository.dart  # TextTvRepository: page(n, {fresh}) -> TextTvResult, never throws
    live_text_tv_repository.dart # in-memory cache over TextTv: 5 min, 40 pages
  ui/
    theme.dart               # TvColors, TvMetrics, kPixelFontFamily, textTvTheme(): the chrome's colours and metrics, the only place they are defined
    text_tv_screen.dart      # TextTvScreen: state (page, part, history, number pad, request counter) and the layout of the screen
    text_tv_page_area.dart   # TvPageArea / TvGrid / TvMessage: the page, or loading / not-broadcast / failure
    text_tv_controls.dart    # TvTopBar, TvPartBar, TvButton, TvNumberBox, TvShortcuts, TvKeypad, textTvShortcuts
    text_tv_keys.dart        # the ValueKeys tests use to find controls
    tv_row.dart              # TvRow: one row drawn cell by cell (colour bars, block graphics, underlined links, tall headlines); tvColorOf = the fixed teletext palette
test/                        # mirrors lib/; fakes/ holds FakeHttpFetcher and FakeTextTvRepository; fixtures/ holds real texttv.nu answers
```

Rules:
- `model/` imports nothing from `services/` or `ui/` (and no `dart:io`, no Flutter).
- `ui/` reaches the network only through `TextTvRepository`. Tests inject a fake; nothing in `lib/` constructs a repository except `main.dart`.
- Expected failures are values (`TextTvResult`), not exceptions; `NetworkException` stays inside `services/`.
- The page's colours are the fixed teletext palette in `tv_row.dart` and are not themeable; the chrome's colours are in `ui/theme.dart` and nowhere else.

## The `app` id
texttv.nu asks every client to send its own unique `app` value. This app sends `texttv_android` (`TextTv._app`, also `IoHttpFetcher.userAgent`). Never reuse another app's id (Tile Launcher sends its own).

## Module spec (behaviour to preserve)

Carried over from the Tile Launcher's Text TV module, which this app was extracted from. The tests pin most of it; change the spec and the tests together.


### API contract (as the code uses it)

- `GET https://texttv.nu/api/get/{n}?app=android_tile_launcher&includePlainTextContent=1`. The site asks every client to send its own unique `app` value; the standalone app must send its **own** id, not the launcher's.
- Answer: JSON list. Element 0 is a map with `num`, `title`, `content` (list of HTML strings, one per sub-page; absent on some responses), `content_plain` (list of strings, one per sub-page, lines joined by `\n`), `next_page`, `prev_page` (strings), and sometimes `date_updated_unix` (int; **read by nobody today**).
- Not in broadcast = empty list, **or** exactly one part with exactly one line containing `ej i sändning` (case-insensitive). A real page that merely mentions it is still a page.
- Anything else unexpected (not JSON, not a list, element not a map, `content_plain` missing / empty / not all strings) → `NetworkException('texttv.nu sent an answer I could not read')`.
- `parts` = `content_plain` split on `\n`, each line right-trimmed. `styledParts` = HTML parsed per part, **all or nothing**: if the `content` count differs from the plain part count, or any part fails, the page is plain text only. The plain text is the source of truth.
- `previous` / `next` = `int.tryParse` of `prev_page` / `next_page`, null if missing.

### HTML → rows (`parseTextTvHtml`)

- Row = `<span … class="line…">`; `class` need not be the first attribute (`line DH` rows carry a `style` first).
- Inside a row, one `<span class="…">` per stretch. Class names: `bgBl bgR bgG bgY bgB bgM bgC bgW` (backgrounds), `bl R G Y B M C W` (text colours), `bgImg` (block-graphics cell; the picture is `storage/chars/{hash}.gif` in the `style`). Defaults white on black.
- `<a href="/{n}">` inside a span → underlined run whose command is `'$n'`. Other links are underlined but not tappable.
- Every row must be exactly 40 characters wide after tag stripping, else the whole part is null.
- `DH` rows are double height. The blank row the site leaves under a headline is dropped, but only if it is blank (content under a headline stays).
- Entities decoded: `&nbsp; &lt; &gt; &quot; &#39; &amp;`.
- A picture hash it does not know → a blank cell in the span's colours (no crash).
- Palette in the hash rebuild: the site's teletext colours with channels pulled in to 4/252 (green 2/254). Mask bit `row*2 + column`, rows 5/6/5 sixteenths, columns 6/7 thirteenths.

### Repository

- `LiveTextTvRepository`: key = page number; reuse if younger than 5 min unless `fresh`; keep ≤ 40 pages (oldest read evicted); only a read page is kept; a not-in-broadcast answer evicts; a `NetworkException` becomes `TextTvFailed(message)`. In memory only.

### Viewer

- Range 100–899 (`textTvFirstPage` / `textTvLastPage` in `model/text_tv_page.dart`). Start page configurable.
- `_load` bumps a request counter; only the newest answer is applied (a slow one that was overtaken is ignored); checks `mounted`.
- Opening a page pushes the page left onto a history stack; opening the page already shown (and loaded) is a no-op.
- Arrows use the site's `prev`/`next`, else ±1, hidden at the ends. They also work on a not-in-broadcast page.
- Number pad: first digit 1–8; third digit opens; `DEL`; `X` closes the pad; the number box shows `1--`-style progress; opening a page closes the pad.
- Swipe (|velocity| ≥ 200): left = next part, then next page; right = previous part, then previous page. Part bar only when a page has > 1 part.
- Back: closes the pad first, then pops the history, then closes (`PopScope`).
- `REFRESH` and `TRY AGAIN` read with `fresh: true`. Failures print the exception message upper-cased.
- Shortcuts (Swedish, hard-coded): 100 NYHETER, 101 INRIKES, 104 UTRIKES, 300 SPORT, 400 VÄDER, 700 INNEHÅLL.
- Layout constants: 40 columns + 2 gutter cells; cell width capped at `8 × 1.75`; row height spreads the free height over the row units (double-height = 2), clamped to 1.6–3 cells; glyphs stretched upright up to 2× about the cell centre; `leadingDistribution: even` so text is not low in its row; 12 px air above and below; text centred by `tvGutters`, colour bars (≥ 90 % non-black background) centred by their edges with a 1-cell gutter; first row ignored for margin measurement; rows with < 12 characters of ink ignored.
- A row is announced to TalkBack as its trimmed plain text.

## Decisions log

- Origin: this app is the Text TV module of Tile Launcher (`android_tile_launcher`) reimplemented as its own app; the launcher keeps its copy. The extraction plan and the improvement backlog (offline cache, zoom, search, ...) live in that repo's `.agents/text-tv-extraction.md`. **The backlog is deliberately on hold until the ported viewer works on a phone.**
- Look: the launcher's C64 chrome (bevels, VIC-II colours) was not carried over. The app is flat black with white/yellow chrome in Press Start 2P; the page uses the eight teletext colours. Colours and metrics are in `ui/theme.dart` (`TvColors`, `TvMetrics`).
- Id and name: application id `com.codedbykay.texttv`, label "Text TV", API `app` value `texttv_android`. Fix these before any release; they are painful to change after publishing.
- The viewer became the home screen instead of a pushed route: no close button, and `PopScope(canPop: history empty and no keypad)` makes back step through the pages read and then leave the app.
- One `textTvColumns` constant in `model/` replaces the `40` that used to be hard-coded in both the client and the UI.
- Release signing reads `android/key.properties` (untracked) and falls back to the debug key when it is absent, so CI and fresh clones build; see [android.md](android.md).

### Carried over from the Tile Launcher's decision log
Written in that repo's words, so "the tile", "the launcher" and "the sibling" refer to the apps this one came from.

- The viewer is a full-screen route, not a sheet (asked for by the user: "like opening an app"): `showTextTv` pushes a `MaterialPageRoute(fullscreenDialog: true)` from the tile's tap, and the tile reads again when it closes. Layout: a top bar with the close button on the left (where a thumb reaches back from), the name, and REFRESH; the page on its own black screen in the middle; thumb-sized controls below (`<` page `>`, then shortcuts to 100 NYHETER / 101 / 104 / 300 SPORT / 400 VÄDER / 700 INNEHÅLL). Tapping the number opens a remote-style number pad (a page number starts with 1 to 8; the third digit opens the page; DEL; X puts it away) instead of the system keyboard. Underlined page numbers in a page are tappable links. A swipe left/right steps through a page's parts and then to the next/previous page, and a part bar shows `PART 2/3` with arrows. Back steps back through the pages read (a history stack), closes the number pad first, then closes the viewer (`PopScope`). Failures word themselves (TRY AGAIN reads with `fresh`), and an unbroadcast page says so while the arrows keep working.
- Alignment (the user had seen text and elements sit right of centre in the sibling's rendering): texttv.nu pages are not symmetric (headlines are indented two cells and run to the last column), so drawn as they come the text leans one way. `tvTextMargins` measures the blank cells the page's longer text rows leave at each side (ignoring the title strip, block graphics and short rows) and `tvGutters` gives the black gutter to each side that makes those margins equal; the two gutters always add to 2 cells, so the grid is the same size on every page. The trade-off is inherent: the coloured header bars run to the page's edges, so on a page that leans, the text is centred and the bar is not. Measured on the real pages 100 and 377 in a test.
- The text is Press Start 2P, monospaced (one square cell per character), fitted to the width so 40 columns plus the two gutters fill it, with a 1.6 line height for teletext proportions; block graphics are drawn by the painter. There is no zoom yet: 40 columns on a phone is small, and a text-size control would be the next thing to add if reading is hard. `flutter test` does not load the pixel font, so a rendered test image shows blocks for text (the mosaic logo is real); text layout was therefore checked by geometry in tests rather than by eye.
- The Text TV page fills the height it is given (the user saw it use about half the black area on their phone). 40 columns fix the width, so height is the free variable: `TvGrid` divides the available height over the page's row units (a double-height headline row counts for two) and gives `TvRow` that `rowHeight`, at least the natural 1.6 cells and at most 3 cells (`tvCellWidth` predicts the cell width the row will pick). Backgrounds and block graphics grow with the row; the letters are stretched upright about their centre (`stretch`, up to 2x, so glyphs fill about four fifths of the row), which is how teletext looks (characters twice as tall as wide). A screen too short for the natural height keeps natural rows and the page scrolls.
- Text TV colour bars (the title banner and the navigation strip: a non-black background under 90% or more of the width, `tvIsBar`) are placed by their edges, not their words: they always get the same gutter on both sides, while the text rows get the per-page gutter that centres the text (`tvGutters`), and bar rows are left out of the text-margin measurement. Found on the phone: with everything shifted by the text's lean, the bars sat visibly off-centre. The cost is that a bar and the text rows around it start a cell apart on a page that leans, which follows the site's own layout (its bar text is right-flush).
- Air on the Text TV page (the user marked the last text line touching the bottom bar, and the bar touching the controls): the page keeps `TvMetrics.margin` of black above and below it (the rows are laid out in the height that is left), and the letters are centred in their rows and fill about two thirds of a stretched row. The centring is `leadingDistribution: TextLeadingDistribution.even` on the row's text style: with `height: 1.6` and the font's own proportional split, Press Start 2P put all the extra line height above the letters, so text sat at the bottom of its row and descenders ("g" in "säger") reached the row below.
