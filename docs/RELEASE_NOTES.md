# ChalkBox 2.2.21 — Forever auction lifecycle and Market tab (Beta)

- AuctionSense records the account-wide 15-minute replicate request cooldown when a full request is accepted, even if the addon later cancels or rejects the resulting snapshot.
- A full request can wait up to 10 minutes for the first usable server response, matching observed Forever delays, then reports failure instead of waiting forever.
- After the replicate event, incoming listing counts must stabilize for two seconds before processing; this avoids missing later parts of the snapshot.
- Truthful progress indicates waiting elapsed time, reported incoming listings, or the actual fraction of auctions processed. A changing label is not proof the server sent a response.
- The addon-owned Market tab reserves additional text width to prevent the native tab template from displaying "Ma..."; Blizzard's own auction modes/tabs remain untouched.
- The established browse scan, per-item weighted average and listing counts, bounded batched reads, old-price rollback, and protected trading state remain intact.

## Verification
Lua 5.1 regression tests cover a late server response, growing replicate counts, cooldown on accepted request, and honest Market UI progress. Real Forever-client validation is required to establish full-scan completion.
