# ChalkBox 2.2.10 — Smart Dungeon QuestSense

## Current file changelog (WoW Forever test release)

- **Smart QuestSense now focuses the native quest tracker on the actual party dungeon you enter** when Forever provides trustworthy instance-specific quest-map or quest-log header/title evidence.
- Nonmatching manual quest watches are temporarily hidden and restored on leaving; Smart tracks only quests for the **current** dungeon rather than mixing different dungeon quests.
- **No reliable dungeon match?** ChalkBox leaves the existing tracker unchanged instead of guessing or hiding everything. It preserves manual unwatch choices and defers native watch edits in combat and while the World Map or quest log is open.
- Nearby-only and All-accepted modes, watch limits and previous settings remain supported.

### Other features included in this release family

ChalkBox also includes loot-source and outdoor-location observations in Discoveries; item KEEP/quest/profession tooltips; native AuctionSense asking-price scans and read-only AuctionInsights / disenchant value estimates; MacroForge's framed learned-spell wizard and explicit macro creation; the compact Bar with safe Edit Mode exit; optional combat meter, Session Journal, camping reminders, emotes and default-OFF QuietGuard filters.

**Limits:** No server-official drop odds, completed-sale-price claims, unattended trading, automatic macro rotations or invented quest markers. Gameplay interactions remain user-controlled and constrained by the Forever client API.

Full history: https://github.com/detok/ChalkBox/blob/main/CHANGELOG.md

Download the *playable addon* asset from https://github.com/detok/ChalkBox/releases/tag/v2.2.10 — **ChalkBox-2.2.10.zip**. The separate CurseForge media ZIP is *not* an addon installation.
