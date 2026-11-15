# ChalkBox 2.2.12 — QuestSense Navigation Compass

## New: optional quest arrow

- **QuestSense Navigation:** a compact, movable quest compass with the destination quest name, directional arrow, and **straight-line yard distance** when Forever provides usable world coordinates.
- **Auto / Next / Hide** controls directly on the window. Auto follows your **Blizzard super-tracked quest** when it has a real waypoint, otherwise picks the nearest known outdoor quest destination. Manual Next, Previous and explicit `/chalk nav follow QUEST_ID` let you choose.
- New **Options → AddOns → ChalkBox → QuestSense → Navigation** page for enable/disable, lock, previous/next, reset position and live status. `/chalk nav` offers equivalent controls.
- Works with **real accepted quest waypoints and map markers**, not a copied quest database. It starts **OFF by default** on new characters and remembers the arrow position and selected quest per character.
- **No interference with Blizzard or other addons:** does not set/clear your map pins, edit quest watches, change super-tracking, or automatically move your character. If GPS is unavailable inside a dungeon, quest location is unknown or the destination is in a different region, it hides its direction and explains why.

The existing Smart / Nearby / All QuestSense tracker modes and the rest of ChalkBox remain unchanged.

**Note:** This is a simple *outdoor straight-line compass*, not a full TomTom route planner. Final arrow alignment and Forever-client API behavior should be verified in-game.

Full history: https://github.com/detok/ChalkBox/blob/main/CHANGELOG.md

Playable addon: **ChalkBox-2.2.12.zip** — https://github.com/detok/ChalkBox/releases/tag/v2.2.12
