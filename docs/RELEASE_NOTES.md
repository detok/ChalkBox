# ChalkBox 2.2.22 — Full-scan snapshot completeness (Beta)

- During large Forever auction scans, AuctionSense continues watching the replicated auction count and processes additional listings delivered after reading has started.
- Before replacing a saved market snapshot, a full scan verifies the final auction count remained stable for an additional quiet window.
- Count regressions and implausible item-data totals abort safely without overwriting previously collected asking prices.
- Bounded unreadable-row tracking prevents runaway memory allocations if Forever supplies an incomplete replicated dataset.
- The existing native AuctionSense layout, browse scanner, market history, weighted asking-price calculation, listing counts, and secure Blizzard auction controls remain unchanged.

## Validation
Lua 5.1 tests cover snapshot growth during reading and existing delayed-response and cooldown behavior. A complete scan on the live Forever server is still necessary to validate that server responses are sufficiently complete for reliable full-snapshot pricing.
