# ChalkBox 2.2.19 — AuctionSense full-scan reliability (Beta)

## Fixed
- Full auction replication stays pending while the Forever server prepares results. The earlier 25-second timeout could discard a valid snapshot before it arrived. The request now ends on actual server response, an explicit dropped-request event, or closing the Auction House.
- Full-snapshot events that arrive before the listing count becomes readable are handled by waiting for that same snapshot rather than discarding it.
- Real per-unit weighted average asks and listing counts from a successful full scan remain available after a normal Browse Scan refreshes low prices. Their original timestamp is preserved and shown; expired full samples are hidden rather than invented.
- Mixed-variant safeguards, partial-result rollback, scan cooldowns, and original browse scanning remain in place.

## Forever limitations
The modern `C_AuctionHouse.ReplicateItems` and `REPLICATE_ITEM_LIST_UPDATE` APIs are present for Forever, but server availability varies; actual full-scan completion cannot be guaranteed from mock tests. A normal Browse Scan supplies minimum unit price and total units, not per-listing average/number of lots. No average or listing count is fabricated.

## Verification
Lua 5.1 regressions cover delayed full-scan results, long waits, explicit server throttle-drop, weighted averages, cooldown, browse refresh preserving full samples, and sample expiry. Live Forever-client confirmation is still required before treating full scans as verified.

This is a beta candidate; keep SavedVariables and the previous install until tested.
