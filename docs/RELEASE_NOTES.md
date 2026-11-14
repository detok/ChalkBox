# ChalkBox 2.1.7 — Bar layering and bag UI cleanup

### The Bar
- Preserve the original **full-width 18px** Titan-style strip and 2.1.6 top-UI spacing behavior.
- Draw the Bar in **BACKGROUND** strata, frame level 1, below the normal Blizzard HUD. This lets the player portrait's resting ZZZ animation overlap the Bar instead of being covered by it.
- Do not reposition Blizzard's player portrait or secure action controls to fix visual layering.

### Bags
- Remove the abandoned vertical-offset slider and its badly overlapping UP/DOWN labels from Options > The Bar.
- Show a short, accurate note: separate Blizzard bags naturally stack upward from the lower-right when opened.
- Existing bag-offset preferences remain saved but **are not applied**. Native bag reanchoring and protected item-button decoration remain suspended from 2.1.5 to avoid combat item-use errors.
- Remove the misleading Reset Bags button from the Bar settings page; the underlying reset slash command remains if needed.

### Unchanged
- The Bar's stats, position, customization and safe top-UI push-down.
- AuctionSense/Market scan logic and native Auction House integration.
- Native DPS report choices, Emota safeguards, and all SavedVariables.

### Install
Replace the old ChalkBox folder with `ChalkBox-2.1.7.zip` and type `/reload`.
Lua 5.1 automated tests and ZIP packaging validate the change. Verify player portrait/ZZZ layering in the actual WoW Forever client.
