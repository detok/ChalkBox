# ChalkBox 2.0.8 — QuestSense Nearby auto-sync

**Nearby only** now maintains the tracker around the quest zone you are actually in, without repeated manual refreshes or unwatching.

- Matches accepted quests using confirmed current-zone map data or their quest-log zone heading. Freshly accepted quests and unscoped POI hints no longer force distant quests into Nearby.
- Temporarily hides non-local manually watched quests, remembers those choices per character, and restores them automatically when you return to the zone, choose Smart or All, or turn QuestSense off.
- Rechecks Nearby every 12 seconds as a fallback for missed zone or tracker events, while retaining fast event-driven updates.
- Keeps manual unwatch decisions, addon-managed watch boundaries, watch limits, and Blizzard's native tracker/supertracked quest.
- Defers changes during combat, map/quest-log use and instances. Preserves watched quests when the client doesn't provide reliable zone information rather than risking false removals.
- Settings display the active mode and count of temporarily hidden watches.

**How to use:** Open **Options → AddOns → ChalkBox → QuestSense**, enable automatic tracking, then choose **Nearby only**. Once selected, it stays active as you travel. Nearby means current zone/area evidence; it does not calculate a physical radius or invent quest coordinates.

**Installation:** Replace the existing addon folder with **ChalkBox-2.0.8.zip**, then type `/reload`. Keep SavedVariables; hidden manual watches and preferences are stored per character.

The separate **ChalkBox-CurseForge-Media-2.0.8.zip** is for artwork/listing copy, not installation.

This WoW Forever beta/test build passed automated Lua 5.1 and package checks but needs real-client behavior confirmation. Retail and Classic Era remain unverified. Maintained by Detok Whitemaine.
