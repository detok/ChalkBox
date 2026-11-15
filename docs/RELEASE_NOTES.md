# ChalkBox 2.2.4 — Your Items & Your Sales, inside Market

## Three views, one familiar Auction House tab
At any auctioneer choose Blizzard Auction House → **Market**, then select:
- **Prices:** The existing scan and pricing browser, unchanged.
- **My Items:** See items across your carried bags, combined by item ID. Review actual fresh lowest asks, item counts, vendor total and modeled disenchant expected value. Hovers show the details; protect/quest/bound items are never recommended for auctioning.
- **Sales & Stats:** Actual **seller-mail invoice** receipts captured when you visit a mailbox. Displays captured sale count, gross sale price, house fees and proceeds (including returned deposit). Readable compact row list, hover details, and search.

The Buy, Sell and Auctions tabs remain Blizzard's own. Market has no transaction buttons. Any suggested pricing is advisory and must be verified in the real Sell tab.

## How the receipt history works
ChalkBox observes **completed** native seller invoices from `GetInboxInvoiceInfo` during mailbox events; it skips pending sale notifications and buyer invoices. You do **not** have to click a ChalkBox scan to register those invoices.

Blizzard's supported mail APIs do not expose a stable unique mailbox ID suitable for perfect lifetime deduplication. ChalkBox uses a bounded per-character invoice signature and expiry-time approximation, avoiding repeat counts for an unchanged mailbox. Very similar invoices can sometimes be merged or counted separately. Items sold before installing the update or mail that disappears before being observed cannot be recovered. This is an **observed receipts ledger**, not full account transaction history. Mail gold is not automatically collected. The totals are *gross sale / after-cut invoice proceeds*, **not net trading profit**, as purchasing costs, unsold fees and all unsaved sales are excluded.

## Market pricing limits
Asking prices are not completed sales. Old (>24h), mixed-variant or missing prices are never used as a numeric appraisal. Bind/tradeability needs to be verified in-game; character KEEP and quest items remain protected. Disenchant expected value uses Forever-client brackets and Classic-reference yield probabilities and may not exactly match Forever servers.

## Safety and compatibility
No additional auction requests, posting, buying, mail retrieval, protected frame edits, item buttons or event-driven spellcasts. No external services, other addons, or new windows. AuctionSense's 2.2.1 taint hotfix, the original Market scanner, DisenchantSense and all ChalkBox modules remain. Sales stored in new `ChalkBoxDB.auctionInsights` data without rewriting the existing AuctionSense snapshot.

## In-game checks
1. Install `ChalkBox-2.2.4.zip` over your existing addon, keep SavedVariables, `/reload`.
2. Visit an auctioneer: Market → Prices → Scan Market, then My Items. Check quantity, fresh low ask, vendor and DE in the hover.
3. Visit a mailbox containing an actual **seller** invoice. Open the mailbox, then return to Auction House → Market → Sales & Stats and verify the receipt.
4. Reopen the mailbox and verify the same invoice isn't counted again. Switch back to Buy, use your bags, and confirm no blocked item use.

Automated Lua 5.1, full addon suite and ZIP checks run in GitHub Actions. In-client Forever confirmation is still required.
