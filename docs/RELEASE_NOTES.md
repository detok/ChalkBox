# ChalkBox 2.1.9 — Native Auction House integration

### What changed
- The **Market** tab is still inside Blizzard's original Auction House, but its contents now follow Blizzard's own display-mode switching system. The built-in Buy/Search/Browse/Sell/Auctions pages are no longer visible behind ChalkBox.
- The dark slab has been replaced by the same `auctionhouse-background-index` texture used in the native Browse results, paired with Blizzard's inset border.
- Market results use the available horizontal space. Price columns, search/filter box, pager and disclaimer now line up with the Auction House frame.
- Search in Market continues to filter **saved scanned market data**. It does not trigger a live Blizzard search. Use **Scan Market** for a live browse snapshot or **Full listings** only when available. Market prices remain asking prices, not recorded sales.
- Previous/Next and visible rows still adapt to the actual content height. Normal Buy/Sell/Auctions tabs and their Blizzard behavior remain available.

### Preserved
No changes to the underlying AuctionSense scan engine, item tooltips, Native DPS meter reports, full-width Bar, Emota combat protections, or bag offset controls. SavedVariables are untouched.

### Install and verification
Replace the existing ChalkBox folder with `ChalkBox-2.1.9.zip` and type `/reload`. Verify that entering/exiting **Market** leaves native Buy/Sell/Auctions usable in WoW Forever. Lua 5.1 regression tests and addon packaging run on GitHub Actions.
