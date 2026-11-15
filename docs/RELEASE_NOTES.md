# ChalkBox 2.2.2 — Disenchant economics

## Is it worth more as enchanting materials?
For supported green and blue weapons or armor, ChalkBox now compares a modeled disenchant result with the item's market asking price and vendor value. It works inside the existing **LootSense item tooltip** and **Auction House → Market** hover, not a separate window.

- **Expected DE value:** weigh possible Classic dust/essence/shard outcomes by their probabilities and average yield, using your own same-realm/faction AuctionSense lowest asking prices.
- **Gear comparison:** displays which *gross asking-price estimate* is higher (DE vs original item if tradable, otherwise vendor). Uses a 10% buffer to call close results `Close estimate`.
- **Hold Shift:** see material probabilities, quantity ranges, and per-unit asking prices. Or use `/chalk de [item link]` for a short chat breakdown.
- **Missing or stale data:** if any possible reagent is not priced, is older than 24h or is mixed, ChalkBox shows `2/3 material prices` instead of calculating a fake total.
- **Control:** Options → AddOns → ChalkBox → AuctionSense → **Show disenchant estimates on gear tooltips**. Also `/chalk de on|off`.

## Trust limits
The probabilities are a **Classic-based model**, not verified drop probabilities for every WoW Forever item. Some crafted and custom items cannot be disenchanted or yield different materials. Only item levels 5–65, uncommon and rare equipment are currently modeled. Epics, known crafted wands, and unsupported metadata are intentionally excluded.

Asking prices are **not actual sales or profit**. Deposits, fees, market liquidity, sale rates, bind status, enchanting requirements, and other costs are not accounted for. DE consumes the item permanently; always verify before using it.

Your buddy's auction history is not automatically shared. Each player scans their own realm/faction auction market to populate the material prices.

## Safe implementation
ChalkBox never casts Disenchant, touches item buttons, automates trading, or modifies protected combat UI for this feature. KEEP/quest protections suppress DE recommendations. Existing AuctionSense market scans, full-width Bar, bag slider, Discoveries, native DPS reporting, Emota safeguards, SavedVariables and the prior item-use safety hotfix remain in place.

The baseline table is described at https://warcraft.wiki.gg/wiki/Disenchanting_tables and https://www.wow-professions.com/forever/disenchanting-guide.

## Install
Install `ChalkBox-2.2.2.zip` over the previous ChalkBox folder, preserve SavedVariables, and /reload. Automated Lua 5.1 regression/packaging checks run in GitHub Actions; WoW Forever in-client tooltip verification is still required.
