# ChalkBox 2.2.12 — QuestSense Navigation

## A simple quest compass
**QuestSense → Navigation** adds an optional movable arrow that follows an *actual accepted quest waypoint* returned by WoW Forever. It shows the selected quest name and a **straight-line** distance in yards when player and destination world positions are available.

The compass is **off by default**. Enable it in **Options → AddOns → ChalkBox → QuestSense → Navigation**, or type `/chalk nav on`. Its compact window has **Auto / Next / Hide** controls, plus a position lock and reset in settings. Use `/chalk nav prev` for the previous verified quest or `/chalk nav follow QUEST_ID` to explicitly select an accepted quest with coordinates.

**Auto** follows Blizzard's currently super-tracked quest when that quest has a waypoint; otherwise it prefers the closest available known quest destination on the same world map region. Your manual selection takes precedence until you choose Auto again or that quest is removed.

## Designed to leave the game alone
- Uses `C_QuestLog.GetNextWaypoint`, optionally a *real* quest map marker, and supported `C_Map` world-position conversions.
- **Does not call** `C_Map.SetUserWaypoint`, clear player map pins, change quest watches, modify Blizzard super-tracking, install another addon, or guess locations from a quest name.
- Inside instances, or when Forever returns no player position / usable facing / cross-continent world coordinate, the arrow hides its directional indicator and shows a readable reason instead of pointing the wrong way.
- The target and position settings are per-character under a **new optional** `ChalkBoxZoneDB.questNavigator` subtree. Existing quest/manual-watch settings are untouched.
- If the quest log is temporarily unavailable, saved manual selections are preserved and the direction is withheld until it returns.

## Gameplay limits
This is a **straight-line compass, not a road-aware travel guide or a full TomTom clone**. It does not automatically route boats, flights, dungeon floors or unknown quest POIs. Some Forever quests expose no waypoint; these are skipped rather than assigned invented coordinates. The arrow follows the character's facing, not the camera.

## Verification
Mocked Lua 5.1 tests cover opt-in defaults, native border, continent zero, super-tracked/manual/nearest priority, selecting and cycling accepted quests, missing coordinates, instance restrictions, cross-continent destinations, drag lock/reset, and quest-log recovery. Actual arrow alignment, texture visibility and client-specific quest-map behavior should also be checked in-game.

Install `ChalkBox-2.2.12.zip` over the existing addon directory, keep SavedVariables and use `/reload`.
