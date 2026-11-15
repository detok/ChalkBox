# ChalkBox 2.2.10 — Smart Dungeon Quest Tracking

## Smart switches to your current dungeon
Inside a recognized party dungeon, QuestSense Smart now prefers **only accepted quests confirmed for the specific instance**, using available dungeon map quest markers or a directly matching quest-log dungeon category/title. For example, Deadmines-specific objectives are not mixed with Stockades quests. Regular outdoor Smart behavior returns after leaving.

Already tracked quests outside that dungeon, including manually selected watches, are **temporarily suspended**, not forgotten. Their previous choices come back automatically when you exit. Unchecking a dungeon quest yourself is still respected; auto-watch limits and existing quest tracking buttons are unchanged.

## Safe API limitations
A generic quest marked "Dungeon" is **not** proof it belongs to the dungeon you are in. Forever sometimes provides incomplete map/POI data. If ChalkBox cannot confirm any matching quest, it preserves the current tracker instead of removing everything. Quest names and map quest data must be recognized; some custom or unusual dungeon quests may not be detected until the client provides matching information.

This behavior is active only in **Smart** and in **party dungeons**. Nearby and All accepted are unchanged. The addon still defers quest tracker edits during combat, or while the World Map or quest log is open. It never modifies Blizzard's map or quests themselves.

Use **Options → AddOns → ChalkBox → QuestSense → Smart (recommended)** and select **Tracking Diagnostics**, or type `/chalk quests status`, to see the matched dungeon count and a reason if no reliable data is available.

## Tests and installation
- Added Lua 5.1 regression tests for Deadmines vs Stockades, dungeon floor map matching, deliberate unwatch, manual restoration on exit, no-data fallback and previously supported QuestSense behavior.
- No SavedVariables version changes, migrations, quest completion actions or unrelated ChalkBox module edits.
- Verify the native tracker in a live Forever dungeon, especially if a quest uses custom or missing POI data.

Install `ChalkBox-2.2.10.zip` over the previous addon directory, preserve SavedVariables and enter `/reload`.
