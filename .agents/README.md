# .agents — shared guidance for AI coding agents

Single source of truth for how agents (Claude Code, Codex, Cursor, etc.) work in this repo.
Entry points: [`../AGENTS.md`](../AGENTS.md) and [`../CLAUDE.md`](../CLAUDE.md) both point here.

| File | Read it when |
|---|---|
| [flutter-best-practices.md](flutter-best-practices.md) | Writing or reviewing any Dart/Flutter code |
| [architecture.md](architecture.md) | Adding a widget or service, deciding where code lives, or checking how Text TV is meant to behave (the module spec and decisions log) |
| [android.md](android.md) | Touching the manifest, Gradle, signing, the icon or permissions |
| [testing-and-quality.md](testing-and-quality.md) | Writing tests, running checks, before declaring work done |

## Where this came from
This is the Text TV module of the Tile Launcher (`../android_tile_launcher`) reimplemented as a standalone app. The Tile Launcher's `.agents/text-tv-extraction.md` has the inventory, the extraction plan and the **improvement backlog** (persistent cache, zoom/landscape, Fastext, search, ...). The backlog is on hold until the ported viewer is confirmed working on a phone; when it is picked up, move what is being built into a `plan.md` here and log decisions in `architecture.md`.

The two apps are separate products: conventions in one do not automatically apply to the other.

## Precedence
1. Direct user instructions.
2. These guides.
3. Flutter/Dart defaults.

If a guide is wrong or outdated, fix it in the same change. Keep guides short; delete rules nobody follows.
