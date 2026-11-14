# ChalkBox 2.2.0 — Discoveries: Map side panel

### Discoveries belongs to the World Map
- Click the existing **Discoveries** map button to open a compact side panel, attached to the World Map. It is no longer a separate draggable window.
- When space allows, the panel docks beside the map (right first, left if necessary). When the map occupies most of the screen, it attaches to the map's right inside edge so the panel stays visible.
- Closing the World Map closes Discoveries and its selectors. Discoveries cannot be opened as a standalone window when the map is hidden.
- Blizzard's map, zoom, quest tracking, frame anchors and artwork are never changed.

### Select creatures reliably
- **Creature Source** now opens a real clickable list instead of relying on a transient context menu that could silently fail in WoW Forever.
- Supports paging/mouse wheel for longer lists and highlights your current creature choice. Sort uses the same reliable picker.
- If DropSense has no identified creature source in a zone, the selector says so. It will not invent which mob dropped an item.

### A cleaner reading layout
- Group the Area and Creature choices, keep Sort and Search together, tighten the item list, and retain the sample sizes and personal drop-rate warnings.
- Outdoor/dungeon switching, selection, map-sync, search, item tooltips, and per-character saved choices remain available.

### Unchanged
DropSense loot capture and observed probabilities, AuctionSense market data, LootSense profession intelligence, bag offset, full-width Bar, Emota safeguards and native damage-meter reporting were not modified.

### Install and test
Replace the ChalkBox addon folder using `ChalkBox-2.2.0.zip`, preserve SavedVariables and type `/reload`.
Open World Map → Discoveries → Area → Creature → Sort, then close/reopen the map to confirm dock behavior. Automated Lua 5.1 regression and ZIP packaging checks run in GitHub Actions; actual Forever client visuals still require in-game validation.
