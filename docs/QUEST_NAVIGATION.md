# QuestSense Navigation

**Available in ChalkBox 2.2.13 · WoW Forever · optional and OFF by default**

QuestSense now includes a small movable **quest compass**, without installing TomTom or a separate questing addon. This is an original, deliberately simple **outdoor straight-line navigation** tool, not a full travel-path planner.

## Turn it on

- **Options → AddOns → ChalkBox → QuestSense → Navigation** → check **Show navigation arrow**.
- Or type `/chalk nav on`.

The navigator is **only a small floating arrow**, without a surrounding window, text panel, or buttons. **Left-drag** it to a comfortable position, **right-click** for Auto / Next / Hide, and **hover** for the selected quest and straight-line yard distance. The arrow dims to gray if the client cannot safely calculate a direction. Use **Lock arrow position** in settings to prevent accidental movement. Position and manual quest choice persist **per character**. It starts hidden for new characters.

The arrow shows direction when available; its hover tooltip displays the selected quest name and *straight-line yards* when the game gives enough location data. The display belongs to ChalkBox only; your Blizzard World Map, personal waypoint and native quest tracker are left alone.

## Quick controls

| Control | What it does |
| --- | --- |
| **Auto** (arrow's right-click menu or settings) | Prefer a valid Blizzard super-tracked quest, otherwise select the nearest accepted quest with a verified outdoor waypoint in the player's region |
| **Next** (arrow's right-click menu) | Manually cycle to the next accepted quest with a real waypoint |
| **Hide** (arrow's right-click menu) | Turn off the small navigator without disabling QuestSense or discarding your quest watches |
| **Previous Quest** (settings) | Cycle backwards through valid quest destinations |
| **Lock arrow position** (settings) | Disable/enable dragging |
| **Reset Position** (settings) | Restore the default top-center position |
| **Status** (settings or chat) | Show the target, active selection mode, usable waypoints and reason for missing coordinates |

## Commands

| Slash command | Action |
| --- | --- |
| `/chalk nav on` | Enable compass |
| `/chalk nav off` | Hide compass |
| `/chalk nav auto` | Return to Auto (super-tracked or nearest known waypoint) |
| `/chalk nav next` | Follow next accepted quest with a known waypoint |
| `/chalk nav prev` | Follow previous accepted quest with a known waypoint |
| `/chalk nav follow 12345` | Explicitly follow accepted quest ID 12345 **only** if it has a verified waypoint |
| `/chalk nav lock` / `unlock` | Save drag lock |
| `/chalk nav reset` | Restore default position |
| `/chalk nav status` | Diagnostic target and location state |

## Where the location comes from

The compass asks the *game* for `C_QuestLog.GetNextWaypoint(questID)`. When that returns no usable data, it may use a matching **accepted quest's actual map marker** on the current map or a supported parent zone map.

It reads `C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition`, `C_Map.GetWorldPosFromMapPos` and `GetPlayerFacing` for outdoors player-relative direction and yards. In the absence of a manually selected target, it can read `C_SuperTrack.GetSuperTrackedQuestID` to honor Blizzard's selected quest without ever writing to super-tracking.

**No copied route database. No invented objective coordinates. No actual route or ETA calculation.** Distances are straight lines, not travel times, road distances or flight paths.

## Intentional restrictions

- **Inside dungeons, raids or other instances:** player map position and facing may be restricted. The direction hides and the UI explains why; native QuestSense **dungeon watch filtering continues independently**.
- **Other continents / incompatible world map region:** the quest may be named but its arrow is hidden instead of aiming across unrelated coordinate systems.
- **No waypoint returned for a quest:** Auto skips it, and explicit Follow requires a verified point. A manually selected quest that briefly loses its waypoint is remembered but will display that location is unavailable.
- **Missing quest log / secure APIs:** no fabricated direction, no watch-list cleanup and no destructive reset.
- **Player map waypoint:** this addon **does not call** Blizzard `SetUserWaypoint` or clear your existing pin, so your own map marker and TomTom can coexist without ChalkBox fighting them.

## Troubleshooting

If no arrow appears, run `/chalk nav status`. The compass starts off on fresh characters. If it says **No accepted quest waypoints**, open the quest log and select a quest that has an actual objective marker. If it says **No GPS inside instances**, try outside. If **Quest is in another region**, follow a local quest or travel into the matching area first.

Actual in-game arrow texture alignment and Forever-specific world transforms still need visual validation beyond mocked Lua tests. Report any wrong-turn cases with the map, your facing and the selected quest ID through [GitHub Issues](https://github.com/detok/ChalkBox/issues).

[Player handbook](USER_GUIDE.md) · [Command reference](COMMANDS.md) · [Maintainer runbook](MAINTAINER_RUNBOOK.md)
