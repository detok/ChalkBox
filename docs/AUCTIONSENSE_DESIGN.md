# AuctionSense — Architecture and future work

## Product rule

**A scan reports what someone asked, not what a buyer paid.** Keep the source, server market, age and sample size visible. Never conflate a tentative auction listing with a realized sale.

## Architecture (first release)

- Original, independent ChalkBox modules: `AuctionSense.lua` owns scanning, storage and public read-only data functions; `AuctionSenseUI.lua` owns the searchable native frame; existing `ChalkBox_Settings.lua` adds the module page.
- A scan begins **only after a player clicks Scan Market or explicitly issues `/chalk auction scan`**. The native `C_AuctionHouse.ReplicateItems()` request is limited by the server's approximately 15-minute account-wide restriction. No automatic retries or purchasing.
- `REPLICATE_ITEM_LIST_UPDATE` starts reading the server snapshot. Frames consume bounded batches. Incomplete item information gets a limited local retry before failure; never overwrite the last good snapshot with partial or corrupt data.
- Store bounded item aggregates in `ChalkBoxDB.auctionSense`, organized by normalized realm and faction, with a 24-hour age warning. This is deliberately not a seller database or an external upload service.
- Unit low = lowest valid buyout divided by listing stack count (rounded up to the next copper). Unit average ask = total buyouts divided by total units (rounded up). No bid-only ask is treated as a buyout.
- Base item IDs can group multiple equipment variants. Mark those aggregates mixed and withhold trusted value estimates instead of inventing one price for different variants.
- Preserve a short, bounded history of observed low asking prices to enable future trend analysis without bloating SavedVariables.

## Cross-module contract

`ChalkBox_AuctionPrice(itemLinkOrID)` → read-only asking-price details (low, average, quantity, listings, source, market, scan age, stale and mixed indicators), or nil if unscanned.

`ChalkBox_AuctionValue(itemLinkOrID,quantity)` → estimated **gross low asking value** and its price evidence, but only for a fresh, unmixed result; otherwise nil.

`ChalkBox_AuctionRows(search,limit)` → stable alphabetical market list for the UI.

LootSense may show a compact auction section for scanned items. DropSense records an optional market estimate alongside observation rows, without changing its recorded drops. ProfessionSense can use the same accessors for *future* material and recipe cost analysis. There is no automatic sale or crafting profitability inference yet.

## Next gates

1. **In-client API proof:** verify actual Forever replicated item fields, full-scan event timing, 15-minute throttle, cooldown behavior, native frame display and SavedVariables persistence.
2. **Reference-price quality:** build distribution-aware robust prices, reject one-listing bait and stacked-unit distortions, show a clear *confidence/coverage* label. Retain raw evidence only as much as necessary; do not suggest anything is a guaranteed value.
3. **Watchlist and trends:** opt-in tracked items and compact time-series charts. Use individual scan dates, not guessed hourly prices.
4. **Inventory and profession linkage:** optional bag sell candidates; recipe costs, auction fees and margins with disclosed material coverage. Never treat unlisted materials as free.
5. **Trading assistance:** optional protected-action-safe, user-driven workflows only after verifying Forever's purchase/post rules. No unattended clicks or bypasses.

## Boundaries

No other auction addon's source code, no third-party item database as a default authority, no external tracking or personal identity uploads, and no server-wide sales history claims.
