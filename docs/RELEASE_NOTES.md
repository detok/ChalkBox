# ChalkBox 2.1.0 — Introducing AuctionSense (test release)

AuctionSense is a new, original ChalkBox module for observing auction asking prices. It is **read-only**. No buying, bidding, posting, automatic listing searches or third-party addon code.

### What's new
- **Scan Market** manually requests a full-market snapshot while you're at an auctioneer.
- The scanner reads the supported WoW Forever `C_AuctionHouse.ReplicateItems` data in small, frame-budgeted batches instead of freezing the UI.
- Search the new AuctionSense window by item name or ID. See the **lowest buyout per item**, **quantity-weighted average asking price**, quantity, listing count and last scan.
- Saved data is separated by realm and faction. An account-wide 15-minute scan cooldown is respected locally; the server remains authoritative.
- Results publish **only after a complete scan**. A closed AH, timeout, unavailable item data or unsupported API leaves your previous complete snapshot intact.
- A bounded history of low asking prices is retained per item. Old scans are marked; equipment with mixed item variants is flagged and cannot supply trusted valuations.
- Optional item-tooltip pricing can be enabled independently of LootSense advice.
- DropSense exposes optional *estimated gross asking value* metadata through the new common price lookup, and ProfessionSense can use the same API when its future margin analysis is built.

### Find it
Open **Options → AddOns → ChalkBox → AuctionSense** or type `/chalk auction`. At the Auction House, click **Scan Market**. You can also type `/chalk auction scan` while the AH is open. The market window can be opened anywhere to view your previously saved data.

### What the values mean
- **Low**: cheapest currently listed buyout divided by stack size, in copper per item.
- **Avg Ask**: quantity-weighted mean of currently listed buyouts per item, not a sale price.
- **Stale**: over 24 hours since that market was scanned. Old or mixed-variant prices are excluded from the cross-module valuation helper.
- This first release groups listings by base item ID. Equipment with multiple variants is marked and should be checked in Blizzard's AH before listing.

### Next steps
Once Forever in-game scanning and visuals are verified: robust reference prices from the listing distribution, watchlists, item history and trend charts, bag appraisal and recipe profit estimates. No automation will place protected auction transactions.

**Install:** Replace your ChalkBox addon folder with **ChalkBox-2.1.0.zip** and type `/reload`. Keep SavedVariables. **ChalkBox-CurseForge-Media-2.1.0.zip** is a separate listing/media kit, not the addon.

New AuctionSense functionality passed Lua 5.1 regression and packaging tests. A live WoW Forever scan is required before claiming full compatibility; Retail and Classic Era have not been validated.
