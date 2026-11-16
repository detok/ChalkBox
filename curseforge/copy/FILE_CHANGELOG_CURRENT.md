# ChalkBox 2.2.19 — AuctionSense full scan reliability

- Stop discarding Forever full-scan responses after a fixed 25-second timeout; wait for the actual server response or an explicit dropped request.
- Handle full-scan events whose listing count becomes readable a moment later.
- Preserve real weighted average asking prices and listing counts from a successful full snapshot when refreshing low prices through Browse Scan. Show the source and age.
- Retain the last good market data on failed scans. No fabricated averages and no changes to protected trading controls.

Beta: full snapshot needs verification on the current Forever client/server before public publication.
