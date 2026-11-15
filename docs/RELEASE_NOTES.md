# ChalkBox 2.2.8 — Discoveries loot locations and native UI polish

## Discoveries: where did I loot this?
DropSense now records the character's position **when the loot window opened**, if the player is outdoors and Forever returns a readable position on that zone's map. In Discoveries, hover an item to see up to three of its most recently recorded locations, with the zone and percentage map coordinates. Up to six distinct spots are kept per item/area. Repeated samples within 2.5 map percentage points are grouped with a count, so common farming routes do not balloon the saved data. The same bounded history is stored separately for a confidently identified creature source.

Locations are **observed loot-window positions**, not precise NPC spawn/death locations. If the loot source is ambiguous, only the zone's item location is recorded; source-specific drop probabilities are unaffected. Instances, unsupported coordinate APIs and old records without positions show no fabricated points. This feature is additive to the existing `ChalkBoxZoneDB.dropSense` version-2 data, leaving all old item quantities, source windows and drop histories unchanged. No automatic map pinning in this release.

## Restore Blizzard's own settings background
Remove the opaque ChalkBox background rectangle from Options > AddOns. Blizzard's original background and transparency show through again; native controls, page grouping and settings are unaffected.

## Restore map artwork in Discoveries and MacroForge
Both windows reuse the existing native World Map parchment atlas when available. Dark glazes are lighter so the art can actually be seen, with readable local control backgrounds. If the client temporarily lacks the atlas, each window retries the same atlas when it reopens. If it remains unavailable, existing solid backgrounds remain a safe fallback. The WorldMapFrame itself is not modified.

## Safety, testing and installation
- All data remains local to the character. The journal records only when DropSense is already enabled, and only for actual observed item loot windows.
- No changes to protected Blizzard interactions, auctions, quests, combat, macro generation or saved preferences.
- Lua 5.1 regression coverage includes map coordinate validation, source attribution, deduplication and six-spot cap, dungeon and API fallback, background opacity and map atlas retry, and ordinary native settings transparency.
- Artwork appearance and any client-specific atlas behavior still require a final WoW Forever in-game visual check.

Install `ChalkBox-2.2.8.zip` over the existing addon directory, preserve SavedVariables, and enter `/reload`.
