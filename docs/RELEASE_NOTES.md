# ChalkBox 2.0.9 — Discoveries map and location browsing

The existing Discoveries Area / Dungeon dropdown is now a real location browser. You can select **any outdoor zone or dungeon with recorded observations**, regardless of which region your world map is displaying.

### New
- A clearly marked **Follow world map** choice directly in the Area / Dungeon dropdown.
- Alphabetized **Outdoor zones** and **Dungeons** submenus, showing recorded item counts.
- Selecting a location automatically uses the matching Outdoor or Dungeons tab, with no navigation or changes to Blizzard's world map.
- Existing upper-right **Map sync** control now clearly shows ON/OFF and toggles between following and manual browsing.
- Manually selected area and sync preference persist per character. Turning sync off returns to your previous manual selection.
- Compatible nested menus with native MenuUtil and EasyMenu fallback.

### Preserved
- Journal size and layout; draggable world-map button and saved button position.
- Source filters, search, sort and paging.
- DropSense's existing observations, known-source rates, SavedVariables and other ChalkBox modules.

### Test
Open the normal world map, click **Discoveries**, then open the **Area / Dungeon** dropdown. Choose a recorded area from either submenu to browse its loot. To follow the world map again, select **Follow world map** (or use the existing Map sync control).

**Install:** Replace the existing addon folder with **ChalkBox-2.0.9.zip** and type `/reload`. Keep your SavedVariables. The separate **ChalkBox-CurseForge-Media-2.0.9.zip** is artwork/listing copy, not the addon.

WoW Forever beta/test build. Automated Lua 5.1 and packaging checks passed; the menu still needs final visual verification in the actual client. Other WoW versions remain unverified.
