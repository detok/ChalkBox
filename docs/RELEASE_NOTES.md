# ChalkBox 2.0.0 — The Quiet Adventure Companion

**2.0 prerelease for World of Warcraft: Forever client testing.**

One addon, one settings menu, one installable ZIP. This is the launch-candidate consolidation of the tools built through v1.12: MacroForge, automatic DropSense with map Discoveries, LootSense/ProfessionSense, The Bar and repair learning, Session Journal, QuestSense, Adventure Prep, meter integrations, shared themes, QuietGuard, Emota and bag positioning.

## Fixed for this test release: Map Discoveries visibility

The **Discoveries** button previously attempted to attach to a world-map frame that could still be unloaded, at a fixed top-right coordinate that could be hidden behind Forever's map overlay.

- **Recover when the map loads late:** initialize on player/map addon events and temporarily retry until the world-map frame exists. Stop retrying once the button is attached.
- **Use the visible map canvas:** position the button toward Forever's top-left map controls, raise it above the map canvas, and refresh its position when the map reopens or changes.
- **Keep a guaranteed manual entry point:** \`/chalk drops map\` opens the standalone browser even if the button cannot attach.
- **New diagnostics:** \`/chalk drops map status\` reports whether the world-map frame exists, whether the button attached and is visible, the saved map-button toggle, and the selected map ID.
- **No replacements:** do not modify the map's quest tracker, map canvas engine, native quest pins, or other addons' map code.

**Important:** these are code-level fixes verified by automated tests. We still need a real Forever screenshot and a map open/close check to confirm placement at your UI scale.

## Discover and remember

- **DropSense:** records every *readable* loot-window item when enabled; per-character item totals and discovered zones, with dungeon observations kept separately. Creature-specific observed percentages are limited to clearly identified source windows. No official or all-kill drop-rate claims.
- **Map Discoveries:** optional map button plus standalone browser for outdoor drops, recorded dungeon records and creature-source comparisons. Map selection changes update the browser.
- **LootSense & ProfessionSense:** native item/quest/KEEP advice, learned recipe hints and highlights, optional potential crafting-use hints backed by the included 2,511-recipe catalog.
- **Session Journal:** review current and up to 20 previous sessions (observed XP, levels, net money, quests, loot sampling, camp messages and merchant repair quotes).

## Fight and progress with less clutter

- **MacroForge:** spellbook-aware macro templates, modifiers, trinket 13/14 attempts, pet/Auto Shot options, validated copy-ready output, up to 16 saved macro recipes, optional user-click native character macro creation. No GCD bypass or autonomous rotation.
- **The Bar:** compact 18px display with movable and hideable statistics, right-click menus, repair learning, and opt-in Junk/Total bag vendor resale.
- **Combat tools:** compact optional damage/healing/interrupt meter and an independent manual PARTY print command on Blizzard's existing damage-meter interface where supported.
- **QuestSense:** Smart/Nearby/All native quest watches, prioritizing accepted quests without fabricating coordinates.
- **Adventure Prep:** compact theme-aware camp reminder focused on actual available supplies and known buffs/tent eligibility. No unchanged-alert nagging by default.
- **Customization and quality of life:** unified global colors/opacity, QuietGuard, optional Emota behavior and separate bag positioning.

## Backward compatibility

- Preserve existing SavedVariables, individual module toggles, per-character saved loot, item KEEP records, learned repair history, MacroForge recipes, bar layouts and session history.
- No extra addon dependencies or external account. One top-level \`ChalkBox/\` directory in the release ZIP.
- Both Forever-compatible TOCs declare version **2.0.0**.

## Quality gate and what still needs testing

- Automated Lua 5.1 syntax and all module tests (including new late-loading world-map regression), installable ZIP structure and bundled library notices must pass.
- **In Forever:** verify the Discoveries button appears after opening the map from a fresh login, stays visible when the map changes and in windowed/fullscreen modes, and that \`/chalk drops map\` works as a fallback.
- Verify MacroForge shows real spells and class icons and can copy/install a test macro only on an explicit click; the Session Journal persists after relog; Combat Meter and camp toast display correctly; existing item protections remain intact.
- Add actual game screenshots to GitHub/CurseForge material only after this pass. The committed editorial artwork is not a gameplay screenshot.

See the [2.0 smoke-test checklist](TROUBLESHOOTING.md), [README](../README.md), and [MacroForge design](docs/MACROFORGE_DESIGN.md). Source repository: https://github.com/detok/ChalkBox.
