# ChalkBox 2.2.9 — Wood and frame refinement

## MacroForge
The existing two-column workbench keeps its native World Map-style wood background, but no longer looks like a collection of flat gray blocks. Each module panel has a dark warm-charcoal fill, a thin bronze rim, a subtle highlighted top edge and a soft shadow. The entire movable MacroForge window now receives the same native Blizzard dialog-border asset as Discoveries, with a minimal bronze-line fallback if the client lacks BackdropTemplate support. The translucent window body is slightly warmer so the map-derived wood reads clearly.

No widget placement, saved recipes, macro execution, spellbook scanning, explicit install behavior, copy/select workflow, scrolling preview or warning sizing has changed.

## Discoveries
The existing wood texture is retained, with a modest warmer tint and lighter wood glaze to complement the World Map. The item's cool gray-blue rows stay unchanged because they aid scanning. The native window border, dropdowns, map attachment, coordinates, source statistics and SavedVariables remain exactly as before.

## Safety and testing
- Visual-only edits in `MacroForgeUI.lua` and `MapDiscoveries.lua`; no new saved fields or data migration.
- Lua 5.1 regression checks for framed native and fallback MacroForge windows, panel rim/shadow/fill, warm map art, Discoveries rows and all previously covered behavior.
- Real-client confirmation still needed for the wood colors, border draw order and visual contrast.

Install `ChalkBox-2.2.9.zip` over the existing ChalkBox addon folder, preserve SavedVariables and run `/reload`.
