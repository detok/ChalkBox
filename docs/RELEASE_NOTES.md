# ChalkBox 2.0.1 — Discoveries refresh + Updates (prerelease)

This is a focused 2.0 quality-of-life build. You confirmed that the 2.0 map button **now appears in WoW Forever**, so this release improves how the loot browser feels and adds trustworthy update awareness.

## Map Discoveries — easier to read and navigate

- Rebuilt the cramped Discoveries browser into a larger 660×616 themed window with item icons, alternating rows, readable quantity and sampled-window columns, pagination and a clear distinction between collection counts and observed creature-source rates.
- Replaced repeated **Next dungeon / Next source** clicks with real **Area/Dungeon**, **Creature Source**, and **Sort By** dropdown menus. Modern Forever menu API is preferred, with legacy and cycling fallbacks.
- Search item names and IDs in the current selection. Sort by quantity, item name, times appeared or source-specific observed frequency.
- **Outdoor** and **Dungeons** remain separate. Use the **Following map** control to return to the zone displayed by Blizzard's native map, or explicitly browse past recorded locations.
- A zone with no observations shows an honest empty state, never another area's items.
- The map button is now **draggable** and its position is remembered per character. Right-click to reset, click **Reset Map Button** under ChalkBox → DropSense, or type `/chalk drops map reset`.
- Retains the real-client-proven 2.0 fix for Forever's late-loading world map and the independent `/chalk drops map` backup.

## Updates — an honest checker, not a fake GitHub ping

WoW addon Lua **cannot make direct GitHub HTTPS requests**. The new **ChalkBox → Updates** settings page shows the actual installed addon's TOC version and gives you a selectable link to `https://github.com/detok/ChalkBox/releases` for Ctrl+C into a browser. `/chalk update` prints the installed version, any newer version previously encountered among other ChalkBox players and the release link.

Optional **compare versions with group members** uses a small, throttled WoW addon message, only when enabled (OFF by default). If another player has a higher semantic version, ChalkBox can notify you; it **does not establish the latest GitHub release** and **does not install or download anything**. CurseForge can manage updates externally once the project is listed.

## Compatibility

- One installable ChalkBox ZIP; both TOCs 2.0.1.
- No change to DropSense observation history, per-character saves, MacroForge, The Bar, loot protection, quest tracking, CampSense, or combat tools.
- Lua 5.1 regression tests exercise menu navigation, searched/source-specific rows, map button drag persistence and reset, the late-loading frame and update awareness logic.
- **Real WoW Forever client verification** is still needed for dropdown positioning, item icons and button drag at your UI scale.

[Source](https://github.com/detok/ChalkBox) · [Report a bug](https://github.com/detok/ChalkBox/issues/new/choose)
