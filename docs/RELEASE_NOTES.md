# ChalkBox 2.1.1 — AuctionSense tab and scanner repair

**AuctionSense 2.1.0 did not meet the intended user experience.** Its detached window was hidden behind AddOns settings and its full replicate request could remain waiting without results. This test release addresses both shortcomings.

### Auction House integration
- AuctionSense now opens **as an actual Blizzard-style tab inside the Auction House**, not a separate window.
- The original Auction House frame remains the owner. AuctionSense hides when native AH tabs are selected or when the AH closes, without directly editing Blizzard's protected tab selection tables.
- Search, status and scanned prices are displayed in the AH panel. The AddOns setting page remains for tooltip preferences, not as the main interface.

### Scan Market — the default
- Clicking **Scan Market** starts a deliberate full browse query using `C_AuctionHouse.SendBrowseQuery`.
- The addon gathers `GetBrowseResults`, follows browse-results events and requests more pages only when the server's throttled system is ready. This is the modern Forever auction API path used by the native Browse interface.
- The summary contains the **lowest per-unit asking price** and **total units listed**, *not* a verified per-listing average or count of auctions. Unsupported fields show a dash.
- Data is never saved as complete until `HasFullBrowseResults()` reports completion.
- If Forever never responds within 12 seconds, AuctionSense reports an explicit error; previous complete scan data is preserved.

### Full listings (15m) — advanced
- Separate button attempts `C_AuctionHouse.ReplicateItems`, with the roughly 15-minute account-wide server restriction.
- Fixed a race where `REPLICATE_ITEM_LIST_UPDATE` could arrive synchronously before AuctionSense registered its scan state.
- A rejected or unanswered full listing scan reports a useful error without overwriting prices. The API's presence alone is not a guarantee that the Forever server will complete it.

### Existing data and integrations
Market snapshots remain grouped by realm/faction in SavedVariables. LootSense market tooltips and the read-only shared price APIs for DropSense and future ProfessionSense use are preserved. No auction purchases, bids, posts or protected trading actions are automated.

### Install and test
Replace the old ChalkBox folder with **ChalkBox-2.1.1.zip**, type `/reload`, then open an auctioneer. Click **AuctionSense** in Blizzard's Auction House tab row and try **Scan Market**. The normal scan is distinct from **Full listings (15m)**.

The code and packaging passed automated Lua 5.1 regression tests but **a live WoW Forever client test is still required** to confirm rendering, network responses and protected frame behavior. Do not publish this as a proven production auction scanner without that check.
