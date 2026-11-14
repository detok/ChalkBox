# ChalkBox 2.1.6 — Native UI fit corrections

### AuctionSense / Market
- The Auction House's fourth tab is now labeled **Market**, sized to fit the Blizzard tab row. The module's panel retains the AuctionSense title.
- The market browser is contained within the auctioneer's inner panel instead of crowding the native frame border and bottom tab controls.
- Prices, status, filters, seven result rows, Previous/Next and scan disclaimer are spaced vertically without list/footer collisions.
- Browse and Full listings scanners, realm/faction data separation, and results are unchanged.

### The Bar
- The 2.1.5 safety overlay no longer stretches underneath top-right buffs or bag windows.
- It automatically reserves the right-hand UI corner and compresses its own optional metrics at smaller widths.
- No Blizzard UIParent, bag buttons, frame geometry or protected action controls are modified.
- Existing XP, gold, pet, repair, gear and bag statistics remain available.

### Important
The 2.1.5 combat-safety restrictions remain: bag offset and reagent outlines touching native item controls are suspended; Emota never dispatches emotes during combat.

### Install
Replace the ChalkBox addon folder using `ChalkBox-2.1.6.zip`. Preserve SavedVariables, and type `/reload`.
GitHub Actions checks Lua 5.1, regression tests and packaging. In-client Forever UI verification remains necessary.
