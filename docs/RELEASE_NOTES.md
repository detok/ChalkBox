# ChalkBox 2.2.20 — Large Forever auction scans (Beta)

## Fixed
- Full AuctionSense replication no longer rejects an otherwise valid auction-house snapshot merely because it contains over 150,000 listings. The earlier hard cap caused the "Full snapshot exceeds safe scan size" error on busy Forever markets.
- The scanner keeps reading individual listings in small, frame-bounded batches and stores per-item summary values instead of every individual listing.
- The upper safety guard now allows up to 5,000,000 listing indices while retaining the 12,000 distinct-item cap, bounded history, and atomic rollback on failed or interrupted scans.
- Regression covers a 200,001-listing response beginning safely, without deleting previously scanned prices.

## Unchanged
- Full-scan responses still depend on Forever's server. The 15-minute throttle, actual weighted averages, real listing counts, read-only operation, normal Browse Scan, and protection of older snapshots are unchanged.
- The scanner does not invent average asks or numbers of lots from browse summaries.

## Verification
Lua 5.1 tests and installable-archive checks run in GitHub Actions. A full live Forever snapshot is still needed to verify completion, particularly on busy markets.

This is a beta candidate; preserve SavedVariables while upgrading.
