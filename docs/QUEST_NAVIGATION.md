# QuestSense Navigation

**Available in ChalkBox 2.2.17 · WoW Forever · optional and OFF by default**

QuestSense now includes a small movable **quest compass**, without installing TomTom or a separate questing addon. This is an original, deliberately simple **outdoor straight-line navigation** tool, not a full travel-path planner.

## Turn it on

- **Options → AddOns → ChalkBox → QuestSense → Navigation** → check **Show navigation arrow**.
- Or type `/chalk nav on`.

The navigator is **only a small floating arrow**, without a surrounding window, opaque panel, or buttons. **A small yard-distance label appears just below it.** **Left-drag** it to a comfortable position, **right-click** for Auto / Follow Map Pin / Next / Hide, and **hover** for the selected quest and straight-line yard distance. The arrow dims to gray if the client cannot safely calculate a direction. **When dead or ghosted, your corpse has priority** if the game exposes its map marker; resurrection returns you to your quest. Choose one of **Original WoW** (the first minimap arrow, default on fresh characters), **Blizzard Navigation** (native tracked-arrow atlas), or **ChalkBox HD** (256px antialiased TGA) in these settings. **Arrow Size** controls the 32–72px arrow and yard-distance display together, with a smaller **48px** fresh default. Saved appearance preferences are preserved on upgrade. Use **Lock arrow position** in settings to prevent accidental movement. Position and manual quest choice persist **per character**. It starts hidden for new characters.

The arrow shows direction when available; its hover tooltip displays the selected quest name and *straight-line yards* when the game gives enough location data. The display belongs to ChalkBox only; your Blizzard World Map and personal waypoint are left alone. **QuestSense does add the followed accepted quest to Blizzard's existing native watch list when necessary** (and safe), without changing the selected quest, super-tracking, or removing other manual watches.

## Blizzard quest-tracker right-click menu

On compatible Forever builds, **right-click the existing Blizzard quest-tracker header** to open a small ChalkBox menu: **QuestSense Settings**, **Off**, **Smart**, **Nearby**, and **Navigation On/Off**. This uses an additive header hook and does not modify Blizzard's quest-row menus, selection, super-tracking or watched-quest interface. Existing slash commands and the Settings pages work on clients where the header is not hookable.

## Quick controls

| Control | What it does |
| --- | --- |
| **Auto** (arrow's right-click menu or settings) | Follow the most recently selected quest in the Blizzard quest log or the active super-tracked quest; only fall back to a stable nearby quest when nothing is selected |
| **Follow Map Pin** (arrow's right-click menu) | Point to your existing Blizzard World Map waypoint. Disabled until a valid pin exists; the arrow follows when you move it. Removing the pin restores Auto. Corpse recovery still takes precedence. |
| **Next** (arrow's right-click menu) | Manually cycle to the next accepted quest with a real waypoint |
| **Hide** (arrow's right-click menu) | Turn off the small navigator without disabling QuestSense or discarding your quest watches |
| **Previous Quest** (settings) | Cycle backwards through valid quest destinations |
| **Lock arrow position** (settings) | Disable/enable dragging |
| **Reset Position** (settings) | Restore the default top-center position |
| **Status** (settings or chat) | Show the target, active selection mode, usable waypoints and reason for missing coordinates |

## Commands

| Slash command | Action |
| --- | --- |
| `/chalk nav size 48` | Size the arrow (32–72px, 4px steps), including its yard display |
| `/chalk nav original` / `classic` / `hd` | Select Original WoW, Blizzard Navigation or ChalkBox HD arrow art |
| `/chalk nav on` | Enable compass |
| `/chalk nav off` | Hide compass |
| `/chalk nav auto` | Return to Auto (super-tracked or nearest known waypoint) |
| `/chalk nav pin` | Follow the player's existing Blizzard World Map waypoint, without creating or deleting one |
| `/chalk nav next` | Follow next accepted quest with a known waypoint |
| `/chalk nav prev` | Follow previous accepted quest with a known waypoint |
| `/chalk nav follow 12345` | Explicitly follow accepted quest ID 12345 **only** if it has a verified waypoint |
| `/chalk nav lock` / `unlock` | Save drag lock |
| `/chalk nav reset` | Restore default position |
| `/chalk nav status` | Diagnostic target and location state |

## Where the location comes from

The compass asks the *game* for `C_QuestLog.GetNextWaypointForMap(questID, mapID)` on your current map, then `C_QuestLog.GetNextWaypoint(questID)`. When that returns no usable data, it may use a matching **accepted quest's actual map marker** on the current map or a supported parent zone map.

For **Follow Map Pin**, the compass reads only `C_Map.GetUserWaypoint()` and refreshes on `USER_WAYPOINT_UPDATED`. It accepts either plain `{x,y}` or vector-like position data and uses the same world-position math as quest navigation. If the pin is missing, it switches back to Auto; if its coordinates are temporarily unavailable or in a different region, the arrow dims instead of guessing. This does not set, clear, or super-track the Blizzard waypoint.

It reads `C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition`, `C_Map.GetWorldPosFromMapPos` and `GetPlayerFacing` for outdoors player-relative direction and yards. It reads `C_SuperTrack.GetSuperTrackedQuestID` for the actively super-tracked quest and `C_QuestLog.GetSelectedQuest` to detect a changed selection in the Quest Log, without ever writing to those APIs. **While dead/ghosted**, it reads `C_DeathInfo.GetCorpseMapPosition` for the current map and supported parents. The native navigation atlas points up before rotation; actual WoW world X is north/south and Y is west/east, so bearing uses `atan2(worldDeltaY, worldDeltaX) - GetPlayerFacing()`.

**No copied route database. No invented objective coordinates. No actual route or ETA calculation.** Distances are straight lines, not travel times, road distances or flight paths.

## Intentional restrictions

- **Inside dungeons, raids or other instances:** player map position and facing may be restricted. The direction hides and the UI explains why; native QuestSense **dungeon watch filtering continues independently**.
- **Other continents / incompatible world map region:** the quest may be named but its arrow is hidden instead of aiming across unrelated coordinate systems.
- **No waypoint returned for a quest:** Auto skips it, and explicit Follow requires a verified point. A manually selected quest that briefly loses its waypoint is remembered but will display that location is unavailable.
- **Missing quest log / secure APIs:** no fabricated direction, no watch-list cleanup and no destructive reset.
- **Player map waypoint:** Follow Map Pin **reads** Blizzard's existing marker. It does not call `SetUserWaypoint`, `ClearUserWaypoint`, or alter native super-tracking, so other waypoint addons can coexist.

## Troubleshooting

If no arrow appears, run `/chalk nav status`. The compass starts off on fresh characters. If it says **No accepted quest waypoints**, open the quest log and select a quest that has an actual objective marker. If it says **No GPS inside instances**, try outside. If **Quest is in another region**, follow a local quest or travel into the matching area first.

Actual in-game arrow texture alignment and Forever-specific world transforms still need visual validation beyond mocked Lua tests. Report any wrong-turn cases with the map, your facing and the selected quest ID through [GitHub Issues](https://github.com/detok/ChalkBox/issues).

[Player handbook](USER_GUIDE.md) · [Command reference](COMMANDS.md) · [Maintainer runbook](MAINTAINER_RUNBOOK.md)
