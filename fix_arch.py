p = '.agents/architecture.md'
s = open(p, encoding='utf-8').read()
lines = s.split('\n')


def find(prefix):
    return next(i for i, l in enumerate(lines) if l.startswith(prefix))


start = find('## Decisions log')
head = '\n'.join(lines[:start])
old = lines[start:]


def keep(prefix):
    return next(l for l in old if l.startswith(prefix))


align = keep('- Alignment').replace(
    "(the user had seen text and elements sit right of centre in the sibling's rendering)",
    '(text and elements sat right of centre in the first renderings)',
)
text = keep('- The text is Press Start 2P')
fills = keep('- The Text TV page fills').replace(
    '(the user saw it use about half the black area on their phone)',
    '(it used about half the black area on a phone)',
)
bars = keep('- Text TV colour bars')
air = keep('- Air on the Text TV page').replace(
    '(the user marked the last text line touching the bottom bar, and the bar touching the controls)',
    '(the last text line touched the bottom bar, and the bar touched the controls)',
)

decisions = """## Decisions log

- Look: flat black with white/yellow chrome in Press Start 2P; the page uses the eight teletext colours. Colours and metrics are in `ui/theme.dart` (`TvColors`, `TvMetrics`).
- Id and name: application id `com.codedbykay.texttv`, label "Text TV", API `app` value `texttv_android`. Fix these before any release; they are painful to change after publishing.
- The viewer is the home screen: no close button, and `PopScope(canPop: history empty and no keypad)` makes back step through the pages read and then leave the app.
- One `textTvColumns` constant in `model/` is the grid width everywhere (client, parser, UI).
- Release signing reads `android/key.properties` (untracked) and falls back to the debug key when it is absent, so CI and fresh clones build; see [android.md](android.md).
- The improvement backlog is in [improvements.md](improvements.md).

### Viewer design
- Layout: a top bar with the name and REFRESH; the page on its own black screen in the middle; thumb-sized controls below (`<` page `>`, then shortcuts to 100 NYHETER / 101 / 104 / 300 SPORT / 400 VÄDER / 700 INNEHÅLL). Tapping the number opens a remote-style number pad (a page number starts with 1 to 8; the third digit opens the page; DEL; X puts it away) instead of the system keyboard. Underlined page numbers in a page are tappable links. A swipe left/right steps through a page's parts and then to the next/previous page, and a part bar shows `PART 2/3` with arrows. Back steps back through the pages read (a history stack) and closes the number pad first (`PopScope`). Failures word themselves (TRY AGAIN reads with `fresh`), and an unbroadcast page says so while the arrows keep working.
""" + '\n'.join([align, text, fills, bars, air]) + '\n'

s = head + '\n' + decisions
s = s.replace(
    'Never reuse another app\'s id (Tile Launcher sends its own).',
    "Never reuse another app's id.",
)
s = s.replace(
    "Carried over from the Tile Launcher's Text TV module, which this app was extracted from. The tests pin most of it; change the spec and the tests together.",
    'The tests pin most of this; change the spec and the tests together.',
)
s = s.replace(
    "app=android_tile_launcher&includePlainTextContent=1`. The site asks every client to send its own unique `app` value; the standalone app must send its **own** id, not the launcher's.",
    "app=texttv_android&includePlainTextContent=1`. The site asks every client to send its own unique `app` value, so this app sends its own id (`TextTv._app`).",
)
open(p, 'w', encoding='utf-8').write(s)
