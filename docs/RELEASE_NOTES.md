# ChalkBox 2.0.11 — Discoveries direct zone picker and cleaner drop rates

The Discoveries Area / Dungeon field now opens a **visible, scrollable zone picker**. No more nested submenus. Browse every outdoor zone or dungeon with recorded loot, then return to Follow world map whenever you want.

## Changes
- Alphabetized list of every recorded zone and dungeon, with item counts.
- Nine visible rows; mouse-wheel scrolling and Previous / Next pages for large journals.
- A Follow world map choice in the same picker. Manual zone selection pauses map sync without moving Blizzard's world map; saved selections survive relogging.
- Picker works even when Forever's MenuUtil and EasyMenu aren't loaded.
- Clearer item columns: **Found** (item copies), **Drops** (loot occurrences), **Rate** (percentage of looted corpses from a specific creature that yielded the item).
- Short creature-specific readouts, e.g. **Defias Bandit · 4 drops / 12 loots · 33.3%**.
- When an item has only one identified mob source, its personal observed rate can be shown from the whole-zone view. If several mob types dropped it, choose the creature to prevent a misleading mixed rate.
- Shorter tooltips, DropSense settings, and summary text.

**Important:** A loot attempt is not necessarily a kill. ChalkBox only counts readable, attributed loots, not every corpse you kill or every zero-loot kill. These percentages are your personal sample, not official server drop chances.

## Preserved
Current Discoveries window layout, item icons, filters, search, sorting, native map button and its position, saved loot history, saved preferences, QuestSense, The Bar, bank compatibility fix, and other ChalkBox modules.

**Install:** Replace your existing ChalkBox folder with the folder inside `ChalkBox-2.0.11.zip` and type `/reload`. Keep SavedVariables. The separate `ChalkBox-CurseForge-Media-2.0.11.zip` is for publication artwork and copy, not installation.

WoW Forever beta/test build. Automated Lua 5.1 and packaging tests passed; in-game visual confirmation remains necessary.
