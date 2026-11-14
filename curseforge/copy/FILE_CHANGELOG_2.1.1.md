# ChalkBox 2.1.1 — AuctionSense first-use fixes

### Interface
- Moves AuctionSense into the actual Auction House as its own tab, styled to match Blizzard's controls.
- Native Buy/Sell/Auctions tabs remain available and hide the AuctionSense panel.

### Scanning
- Scan Market uses Forever's browse-results API rather than relying on full ReplicateItems data.
- Reads all pages when available, showing real lowest asking price and available quantity.
- Advanced Full listings action is separate and observes the account-wide server cooldown.
- Handles synchronous responses, rejected or missing scan replies, and timeouts with clear status messages.
- Keeps prior complete market data when a new scan fails.
- Does not invent prices, listing counts or average asks when the server supplies only a browse summary.

### Compatibility
- No third-party addon code copied; no automatic auction buying, selling, or bidding.
- Saved data and the rest of ChalkBox's features are unchanged.

WoW Forever test build; please verify in-client behavior before production publication.
