# ChalkBox 1.11.0 — Map Discoveries & Automatic DropSense

DropSense graduates from a manually selected loot watchlist to **automatic personal discovery tracking**. The official WoW Forever drop tables are not accessed or guessed.

## Automatic recording
- Collect every distinct item ID, actual quantity and appearance in **readable native loot windows** while DropSense tracking is enabled. No separate addon or external service.
- Record outdoor zone ID/name when accessible via Forever's `C_Map`, and separately store dungeon/raid instance ID and difficulty when `GetInstanceInfo` is available. Only link instances to an outdoor area after an observed entry or exit.
- Group **single-source creature** opportunities by creature ID within each region. Count the same physical corpse only once if re-opened in the short dedupe window.
- Multi-source, gathering, container and unidentified loot still contribute item/area totals but **do not create misleading per-creature observed rates**.
- A percentage means *the item appeared in X of Y readable loot windows from that identifiable creature type*—it is not an official chance, all-kills probability or Blizzard loot-table number. A 95% Wilson interval is shown where appropriate. Empty/unopened loot opportunities remain invisible.
- Save bounded per-character data; when a capacity limit is reached, status and map UI report it rather than silently claiming complete records.

## Map integration
- A small, **optional Discoveries button** appears on the existing Blizzard World Map. No map rewrite, quest marker changes or forced dependencies.
- Clicking it opens a movable native-style window tied to the **map currently viewed**, not necessarily where the character stands.
- **Outdoor / Dungeons** views; observed instances remain separate from outdoor loot. **Source** cycles recognized creature types; previous/next pages browse items.
- Missing instance-to-outdoor association is reported as unknown, not inferred from arbitrary dungeon geography. For a zone with no observations the window displays a clean empty state.
- Toggle map button in **ChalkBox → DropSense** or `/chalk drops map on|off`.

## Continued session history
- Session Journal includes observed loot regions, up to the three most frequently sampled zones/instances per session.
- Previous 1.10.0 manually watched items and their counts/references migrate as **legacy unsited observations**; neither their locations nor exact creature denominators are invented.
- Automatic tracking defaults on for first-time installs but preserves any explicit previous opt-out. Tooltip and map-button visibility remain independently configurable.
- Other existing The Bar, camping, repair learning, LootSense and theme features are unaffected.

## QA
Lua 5.1 regression coverage for same-source denominators, source mixing, area isolation, verified dungeon link, 1.10.0 migration, native World Map button/panel, and packaging. Full ZIP install remains **one ChalkBox folder**.

**Remaining live-client verification:** native map layout at different UI scales, lazy WorldMapFrame loading, instance entry/exit event behavior, and GetLootSourceInfo return forms in actual Forever builds. The addon degrades conservatively if these aren't available.
