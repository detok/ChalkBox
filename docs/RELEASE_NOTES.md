# ChalkBox 2.2.1 — Protected item-use safety

### Investigation
A player reported that the Cozy Sleeping Bag sometimes triggers a "ChalkBox blocked an action" error and only works again after `/reload`.

Source audit found an unsafe Market-tab path introduced in 2.1.9:
- ChalkBox directly called `AuctionHouseFrame:SetDisplayMode` with an addon-owned table.
- Blizzard's Forever Auction House code stores that value in the frame's `displayMode`.
- Forever's bag item-use handler calls `AuctionHouseFrame:IsListingAuctions()` while the AH is open; that method reads the same display mode before normal protected item use.
- An independent Forever auction addon reported a **Cozy Sleeping Bag** blocked-action error with this exact suspected mechanism.

### Change
- Never call `SetDisplayMode` from ChalkBox or inject a custom table into Blizzard's AH trading state.
- Retain Market's integrated artwork and panel by temporarily hiding only safe, unprotected native content frames, then restoring them when leaving Market. No edits to Blizzard's display-mode list, protected native tab registry, or trading state.
- Verify the native Buy, Sell and Auctions pages restore correctly and Market continues scanning/displaying prices.

### What we did not change
The **vertical bag offset behavior**, saved bags, Item Insight, Emota, the full-width Bar, native DPS meter, Discoveries, auction scan engine and all SavedVariables are unchanged.

### Test and validation
Automated Lua 5.1 regression tests explicitly forbid any addon call to Blizzard's display-mode setter and simulate right-clicking a soulbound usable item while the AH is open. The ZIP is validated in GitHub Actions.

The exact blocked-function stack from the player's live client has not been captured. If an item is still blocked in WoW Forever after `/reload` and installing this version, enable `/console taintLog 1`, reproduce it and provide `Logs/taint.log` (and whether the Auction House was open or visited earlier). Avoid reproducing a suspected blocked action in combat.
