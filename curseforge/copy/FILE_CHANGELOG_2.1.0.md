# ChalkBox 2.1.0 — AuctionSense (test release)

### New: AuctionSense
- An original, independent auction-market tracker inside ChalkBox.
- Manual full AH scanning with progress, account-wide cooldown awareness and safe handling of incomplete results.
- Searchable market browser: lowest per-item buyout, average asking price, listings, units and scan age.
- Optional auction prices in item tooltips.
- Saved faction/realm-specific snapshots and bounded price history.
- Read-only price API for LootSense, DropSense and future ProfessionSense features.
- No bidding, purchasing, automatic posting or third-party addon code.

### Reliability
- Old or mixed-variant snapshots cannot be used for trusted cross-module valuations.
- Failed or interrupted scans preserve the previous complete snapshot.
- New Lua tests cover market isolation, price math, UI, cooldown, scan failures and tooltips.

**Note:** Prices represent listed asks, not recorded sales. WoW Forever test release; full in-client verification remains necessary.
