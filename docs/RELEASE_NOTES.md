# ChalkBox 2.2.14 — Quest Compass Direction and Corpse Navigation

## Accurate direction, without losing the minimal arrow

The optional QuestSense arrow uses corrected **WoW world-coordinate geometry**: world X is north/south, world Y is west/east. The previous bearing computation reversed those axes, causing incorrect headings. The arrow now prefers Blizzard's north-up `Navigation-Tracked-Arrow` atlas, updates smoothly as your character turns, normalizes headings across the north/south wrap and stabilizes at very short distances instead of spinning.

## Point toward the quest you actually selected

**Auto now follows the quest selected in the Blizzard quest log or actively super-tracked in the game's objective tracker**, instead of unexpectedly hopping to a different nearby quest whenever a waypoint is missing. Selecting a different quest in the game releases a stale manual Next/Follow override. The compass prefers a real current-map next waypoint when supplied, then the quest's next step and genuine map POIs. It never invents coordinates.

If you have **no actively selected/tracked quest**, Auto may use a nearby known quest; it keeps that fallback target stable while you move instead of constantly switching to whichever quest becomes a few yards closer. Manually choosing Next or Follow still works.

## Corpse recovery overrides quests

While dead or ghosted, the arrow attempts to point to **your actual corpse**, using `C_DeathInfo.GetCorpseMapPosition` for the current map or a suitable parent map. It labels the destination **Your corpse** on hover. **Resurrection restores your previous quest selection**—no saved settings or quest-watch changes.

If Forever doesn't expose your corpse location, player position, or facing (especially inside instances), the arrow remains muted with a specific tooltip message rather than pretending it knows which way to go.

## No new UI clutter

It's still **only the floating arrow**, with the familiar **right-click Auto / Next / Hide** menu and hover tooltip. Your saved position, lock, manual selection, and opt-in preference are preserved. This change reads game data; it doesn't alter Blizzard's quest watches, map pins, super-tracking, or protected gameplay actions.

## Verification

Lua 5.1 mock regressions cover all four compass directions, facing rotation, zero-distance stability, selected/super-tracked quest changes, current-map waypoint preference, corpse override and resurrection, parent-map corpse coordinates, absent position data, and existing settings/menus.

**Real Forever-client confirmation remains necessary**, particularly arrow atlas orientation and corpse data availability on the specific build.

Install `ChalkBox-2.2.14.zip` over the current addon folder, keep SavedVariables, and use `/reload`.
