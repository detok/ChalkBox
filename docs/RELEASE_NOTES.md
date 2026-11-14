# ChalkBox 2.0.12 — Clickable Discoveries picker and refreshed AddOns icon

## Discoveries
The Area / Dungeon zone picker could appear **behind the journal or other game menus**, leaving recorded zones visible but impossible to select. The picker now opens on its own high-level UI layer, anchored beneath the existing Area field. You can actually click the entries. It closes automatically when the Discoveries journal closes.

- Direct zone and dungeon list, mouse-wheel navigation and paging unchanged
- Your manually browsed area, map sync, saved loot history and source filters preserved
- Existing Discoveries layout and map button position unchanged

## AddOns selection icon
ChalkBox's in-game addon icon now matches the newer gold-and-teal ChalkBox project emblem used in the CurseForge artwork. The release packager renders the canonical SVG master as a **native 64×64, 32-bit uncompressed TGA**. Both game-flavor manifests already reference the same correct IconTexture path, so no extra installation or texture configuration is needed.

## Validation
- Automated Lua 5.1, Discoveries frame-layering, zone-selection and package tests
- Packaging checks assert the game TGA is in the installable ZIP in the expected format
- Native world map, bank compatibility fixes, QuestSense and other ChalkBox modules remain unchanged

**Install:** Replace the existing ChalkBox addon folder with **ChalkBox-2.0.12.zip** and restart or `/reload` the game. To see a changed icon on the character-selection AddOns screen, restart the client if it cached the old artwork. Keep SavedVariables.

**ChalkBox-CurseForge-Media-2.0.12.zip** contains the separate promotional files. Do not install that ZIP as an addon.

For WoW Forever; live-client visual confirmation is still required. Retail and Classic Era remain unverified.
