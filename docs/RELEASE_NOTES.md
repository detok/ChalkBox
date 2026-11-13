# ChalkBox 1.8.1 — Real WoW class icons in the DPS meter

It is now easier to tell which player is which at a glance. Every ranked player has a compact **18 × 18 World of Warcraft icon** directly between their rank and name.

## Real in-game art, no other download

- Default **Class** mode uses the client’s original class emblems, including **Hunter, Warrior, Mage, Rogue, Druid, Shaman, Priest, Warlock, and Paladin**.
- The correct emblem is selected from Blizzard's own `classFilename` supplied in the `C_DamageMeter` result. No guesswork from player names or GUID parsing.
- Optional **Spec** mode uses the supplied native `specIconID` (the same kind of numeric WoW icon identifier that the macro picker uses) when present. If missing, it falls back to the player's class emblem.
- An unclassified source, such as a pet or an unidentified NPC, shows the neutral WoW question-mark icon, **not** an invented class.
- **Off** hides emblems and expands the available name space.
- Icons update when rankings change and clear when a row empties; the entire window still supports resizing, opacity, locking, printing, current/last/overall sessions, and six statistic modes.

## How to change icon style

Open **Esc → Options → AddOns → ChalkBox → Combat Meter** and choose **Class**, **Spec**, or **Off** in the icon row.

Alternatively, use:
- `/chalk meter icons class` — recognizable class emblems (default).
- `/chalk meter icons spec` — specialization art where Blizzard supplies it; class fallback.
- `/chalk meter icons off` — hide the emblems.

The choice is stored in your existing ChalkBox settings and survives reload.

## Technical and compatibility details

Blizzard's damage meter reports `classFilename` and optional `specIconID` as **NeverSecret** fields. ChalkBox only reads those identifiers and passes native texture/file IDs to UI texture methods. Protected player names and damage numbers remain protected and are never parsed or reformatted by the icons feature.

Classic class icons use the original WoW `Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes` texture sheet, with Blizzard-defined tile coordinates (and a matching first-party fallback if `CLASS_ICON_TCOORDS` isn't exposed). No web requests, scraped artwork, downloaded asset packs, or additional addon dependencies.

All existing QuestSense, CampSense, LootSense (including 2,511 bundled recipes), Toast Appearance, Emota, TrailBar and QuietGuard code remains functional and unchanged by this release.

## Install and test

Replace your existing `Interface/AddOns/ChalkBox/` folder with the single **ChalkBox-1.8.1.zip**, then `/reload`. Group with a different class or switch to **Last** after a fight; class icons should match the players without interfering with DPS totals.

This release remains a **public prerelease** until real WoW Forever in-game visual verification. The Lua 5.1 test suite checks actual Hunter/Warrior atlas coordinates, the unknown fallback, optional specialization icon file IDs, clean empty rows, style switching, saved settings, and the unchanged native secret-value protections.