# ChalkBox 2.2.22 — First stable release

ChalkBox is now a stable public release for **World of Warcraft: Forever**.

The milestone that made this possible was a completed in-game AuctionSense full scan: live auction asking-price data populated the Market table and became available to the connected bag, loot and item-value tools. The complete set of Lua 5.1 regression and packaging checks also passes.

## What's included

- **AuctionSense:** a native Auction House Market tab, manual browse scan, and optional server-throttled full-listings scan. A completed full scan provides per-item low asks, weighted average asks, listing counts and quantities. Full scans handle delayed and later-arriving data, with visible progress and safeguards against overwriting good prices with incomplete snapshots.
- **AuctionInsights / Bags / DisenchantSense:** read-only bag valuations and supported observed seller receipts; disenchant material estimates use available fresh auction asking prices and clearly labeled reference outcomes.
- **LootSense / ProfessionSense:** context for quest items, personal KEEP choices, confirmed known recipes and possible profession ingredients.
- **DropSense / Discoveries:** personal loot observations, searchable map journal and recent observed outdoor loot-window locations where supported.
- **QuestSense / Navigation:** conservative accepted-quest tracking with dungeon-aware options and optional navigational arrow.
- **MacroForge:** manual macro building from known spells with preview, copy and safe explicit new-macro installation.
- **The Bar, Combat Meter, Adventure Journal, CampSense, Emota, QuietGuard, bag placement and appearance settings.**

## What the numbers mean

Market prices are **asking prices**, not confirmed sale prices. DropSense rates are personal observations. Disenchant yield probabilities remain reference models rather than verified Forever-specific odds. Some features depend on the Forever client exposing appropriate API data.

## Install or upgrade

Download **ChalkBox-2.2.22.zip** (not the GitHub-generated source archive or separate media kit) and extract the single `ChalkBox/` directory to your Forever client's `Interface/AddOns/` folder. On upgrades, **preserve SavedVariables**.

## Getting help

Use [installation help](https://github.com/detok/ChalkBox/blob/main/docs/GETTING_STARTED.md), [troubleshooting](https://github.com/detok/ChalkBox/blob/main/docs/TROUBLESHOOTING.md) or the [guided issue forms](https://github.com/detok/ChalkBox/issues/new/choose) for bugs, compatibility reports, setup questions and feature ideas. For market issues, include `/chalk auction status` and whether Scan Market or Full listings was used.

**Compatibility:** Developed for World of Warcraft: Forever; Retail and ordinary Classic compatibility are not claimed.

Thanks to the early players who tried real-world features and helped turn the working beta into a maintained release.
