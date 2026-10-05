# .agents — shared guidance for AI coding agents

Single source of truth for how agents (Claude Code, Codex, Cursor, etc.) work in this repo.
Entry points: [`../AGENTS.md`](../AGENTS.md) and [`../CLAUDE.md`](../CLAUDE.md) both point here.

| File | Read it when |
|---|---|
| [flutter-best-practices.md](flutter-best-practices.md) | Writing or reviewing any Dart/Flutter code |
| [architecture.md](architecture.md) | Adding a widget or service, deciding where code lives, or checking how Text TV is meant to behave (the module spec and decisions log) |
| [android.md](android.md) | Touching the manifest, Gradle, signing, the icon or permissions |
| [testing-and-quality.md](testing-and-quality.md) | Writing tests, running checks, before declaring work done |
| [improvements.md](improvements.md) | Deciding what to build next; the backlog by tier |

## Precedence
1. Direct user instructions.
2. These guides.
3. Flutter/Dart defaults.

If a guide is wrong or outdated, fix it in the same change. Keep guides short; delete rules nobody follows.
