# ChalkBox 2.2.11 — Adventure Journal Frame Repair

## Current file changelog (WoW Forever test release)

- **Adventure Journal / Session Journal** now has the same native Blizzard outer dialog frame and warm map-derived wood treatment as Discoveries and MacroForge. Session Summary and Field Notes have separate bronze inset sections with consistent spacing.
- **Fixed invisible/unfinished background** when the global ChalkBox opacity setting is low or 0. Journal art is retried on reopening, a safe opaque fallback is provided for clients without the atlas, and theme changes refresh the Journal live.
- **All previous per-character session summaries are preserved**, including the current and last 20 sessions, XP, gold, quest counts, observed loot, camping and repair quotes. No SavedVariables migration or gameplay counters changed.
- A [Full Adventure Chronicle](https://github.com/detok/ChalkBox/blob/main/docs/ADVENTURE_CHRONICLE_DESIGN.md) is designed as a future stage with verified milestones and bounded recording. **Event Timeline and History views are not active in this release.**

Full changes: https://github.com/detok/ChalkBox/blob/main/CHANGELOG.md

Download the playable **ChalkBox-2.2.11.zip** from https://github.com/detok/ChalkBox/releases/tag/v2.2.11. The separate CurseForge media ZIP contains publisher assets and is not an addon installation.
