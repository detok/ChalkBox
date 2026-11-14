# ChalkBox 2.1.2 — AuctionSense quick-read polish

AuctionSense results now surface the numbers first. The tested 2.1.1 scanning and native Auction House tab remain unchanged.

### At-a-glance prices
- **Green:** lowest asking price per item unit.
- **Gold:** average asking price per unit, when observed from full listings.
- **Blue:** listing count. **Gray dash:** not available in browse data.
- **Amber:** mixed equipment variants or server scan cooldown. **Red:** stale scans and errors.
- Hover an item in the AuctionSense table for a short breakdown: unit low, average, listings, quantity, source, scan age and server market.
- Hover Scan Market / Full listings for short action hints.

### Data integrity
Market prices are asking prices, never completed sales. Browse data does not invent average prices or listing counts. Older saved snapshots and all other ChalkBox modules are preserved.

### Install and test
Replace the ChalkBox addon folder with ChalkBox-2.1.2.zip and type `/reload`. Open the Auction House and hover a scanned result. Check that low prices are green, missing averages show a dash, and warnings are obvious.

GitHub Actions checks Lua 5.1 syntax, addon regressions and ZIP packaging. In-client WoW Forever visual verification is still recommended.
