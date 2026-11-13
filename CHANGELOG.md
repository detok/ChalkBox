# Changelog

All notable changes to the public ChalkBox addon are documented here.

## 1.7.0 — Built-in native DPS and combat meter

- Added a compact, class-colored, draggable ChalkBox combat meter with an obvious marker for your own character.
- Modes: DPS, Damage Done, HPS, Healing Done, Damage Taken and Interrupts. Sessions: Current Fight, Last Fight and Overall.
- Added show/hide, lock, 5/8/12 rows, 85/100/115% scaling, position reset and deliberate reset confirmation in native AddOns settings.
- Uses Blizzard's native `C_DamageMeter` API and event-driven updates. Secret values are passed directly to protected-safe text/status bar UI setters, never processed in Lua.
- Preserved working LootSense with 2,511 bundled Forever recipes, CampSense, TrailBar, QuestSense, QuietGuard and Emota.
- New Lua 5.1 tests cover native combat API, protected values, modes, visibility and resetting; one ChalkBox ZIP still ships.

## 1.6.1 — Forever profession scan and tooltip fixes

- Let `C_TradeSkillUI` establish an active owned profession when legacy profession APIs are unavailable, instead of blocking recipe scans.
- Listen to `TRADE_SKILL_LIST_UPDATE` and `TRADE_SKILL_DATA_SOURCE_CHANGED`, plus a short delayed scan, so recipes loading after the panel opens are captured.
- Fall back to alternate reagent APIs when a modern recipe schematic is missing or empty.
- Continue LootSense tooltip advice when `GetItemInfo` has not cached an item yet.
- Add actionable `/chalk loot status` diagnostics for enabled state, active profession, scanner backend, and learned-recipe count.
- Preserve one-ZIP bundle, exact MIT notices, and all other gameplay modules.

## 1.6.0 — Complete offline Forever recipes in one download

- **Bundled the MIT-licensed LibProfessionDB 1.9.1 Forever-only database** (2,511 recipes), with original Pimptasty copyright/license and the public-domain LibStub loader.
- Replaced the optional external database install with a truly self-contained ChalkBox ZIP.
- Fixed recipe matching against static entries lacking localized recipe names. Names resolve from the client spell API first, then crafted-item names, with an honest ID fallback.
- Made offline recipe indexing deterministic, improved tooltip advice when you already have enough materials, and retained the distinction between **known recipe** and **potential use**.
- Added an integration test loading all 2,511 real bundled recipes and archive/license checks.
- Original standalone addons are still excluded; CampSense, TrailBar, QuietGuard, Emota and QuestSense unchanged.

## 1.5.1 — Public launch

- Established **detok/ChalkBox** as the one-and-only public home for the combined addon.
- Reorganized into a clean installable `ChalkBox/` folder, with a matching **single ZIP release**.
- Kept the original addon icon and all ChalkBox feature modules and Lua regression tests.
- Added open-source licensing, installation and user documentation, issue templates, and CI.
- Removed the old multi-addon collection build, standalone-source packages and standalone regression targets.
- No gameplay feature rewrite; the module baseline is v1.5.0. Optional third-party database compatibility remains a prerelease feature.

## 1.5.0 — Recipe-aware LootSense

- Tracked names and available reagent quantities from **learned** character recipes.
- Prioritized known-recipe evidence over broad profession-family hints.
- Added optional separately installed LibProfessionDB adapter for *potential* recipe uses.
- Added Shift-expanded known recipe detail and `/chalk loot status` diagnostics.

## 1.4.0 — Buff-aware camping

- Added Camp Benefits / Welcoming Campfire aura checks.
- Added a compact, timed center-screen toast and test button.
- Recognized additional Forever campsite ingredients, including Light Leather.

## 1.3.0 — More adventuring awareness

- Added QuietGuard social-invite controls and CampSense checklist.
- Added race/class context and resting-area behavior to Emota.

## 1.2.0 — Emota idle personality

- Randomized intermittent idle emotes, no-repeat rotation, and safe temporary poses.

## 1.1.1 — TrailBar layout

- Reserved screen space for TrailBar instead of placing it over gameplay UI.

> Earlier development happened in a private collection repository. The public repository contains **only ChalkBox**; it deliberately does not publish the historical standalone addons.
