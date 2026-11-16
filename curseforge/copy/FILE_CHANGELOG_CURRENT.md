# ChalkBox 2.2.20 — Large Forever market scans

- Fix Full listings rejecting an actual Forever snapshot simply because it contains more than 150,000 auctions.
- Read large snapshots incrementally and keep bounded per-item totals for lowest unit price, average asking price, and number of listings.
- Retain the 15-minute replication cooldown, market-specific snapshots, and previous data on failure.
- No automated buying/selling and no fabricated market figures.

Beta: confirm full-scan completion in the real Forever client before public upload.
