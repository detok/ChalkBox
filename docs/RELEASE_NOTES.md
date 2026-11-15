# ChalkBox 2.2.11 — Adventure Journal Frame Repair (Gate A)

## The Journal finally looks like ChalkBox
The **Adventure Journal / Session Journal** window now uses the same native Blizzard `UI-DialogBox-Border` outer frame and warm map-derived wood art as Discoveries. It has two legible inset sections—**Session Summary** and **Field Notes**—with bronze rims, subtle depth and the original Current / Older / Newer / Close controls.

The window no longer disappears when global theme opacity is set to 0. Its backdrop has a readable opaque fallback when the native atlas is not available on the client. It retries the actual atlas when opened again, and **Global Appearance** now sends live accent/theme refresh notifications to the Journal.

## No data lost or invented
Existing per-character `ChalkBoxZoneDB.sessionJournal.version=1` is **unchanged**, including the current and up to 20 earlier session summaries, experience, net gold, quest totals, loot windows, regions, camp prompts, merchant repair quotes, and navigation. No data migration or new recording events are introduced in this release.

## The Full Adventure Chronicle is designed, not yet collecting milestones
[Adventure Chronicle design](ADVENTURE_CHRONICLE_DESIGN.md) specifies the next development gates: a bounded validated event ledger (levels, completed quests, deaths, verified dungeon entry/exit, later select DropSense integrations), deduplication, evidence provenance, controls, privacy and graceful failure; then real **Today / Timeline / History** views.

**This version implements the visual fix only.** New event recording, chronological views and searchable history are not live yet, and old sessions will never be backfilled with made-up events.

## Safety and verification
- Source change: Journal window presentation and global theme-refresh registration only. No old session data, event-counting or protection logic changed.
- Lua 5.1 regression tests cover old session counters, unreadable native atlas, theme opacity zero, native outer border/fallback, section frames, atlas retry, active appearance changes and preservation of the existing journal schema.
- Final visual appearance and game-specific art fallback still require real WoW Forever client confirmation.

Install `ChalkBox-2.2.11.zip` over your existing ChalkBox folder, keep SavedVariables and enter `/reload`.
