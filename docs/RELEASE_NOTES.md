# ChalkBox 2.2.25 — Bank Value, Bar Resizing and Combat Report Polish (Beta)

**WoW Forever GitHub prerelease.** This is a new playable ZIP containing the full ChalkBox addon. The last verified stable baseline remains [2.2.22](https://github.com/detok/ChalkBox/releases/tag/v2.2.22). The combined feature branch passed Lua 5.1, documentation, packaging and publishing-kit checks, but every module has not been fully smoke-tested in the live client.

## What's new

- **Bank Value:** Tracks the vendor value of bank contents when Blizzard's bank APIs provide enough information, remembers the last successful per-character snapshot, and exposes the value in The Bar. The bank itself displays a small frameless text label in the lower-right gap above its coin bar, without covering stored items. Unknown values stay unknown. AuctionSense comparisons are labeled separately; listing asks are not sales.
- **The Bar:** Independently resize module widths using the right-edge grips in Bar Edit Mode, while body dragging still reorders modules. Widths persist per character, honor layout limits and can be reset from settings or slash commands.
- **Combat reports:** Manual Top 3/5/10 reports go to the *selected* PARTY or SAY channel using normal plain-text chat. Each player gets a separate ranked line. PARTY lines are spaced 200 ms apart, following established meter patterns; SAY lines send directly from the button click. No raw pipe separators, embedded newline escape codes, copy popup, surprise channel change or retry. Fixed the incorrect native-meter `IsEditing()` check that falsely blocked reports. Automatic reporting remains OFF by default. Combat values are never invented or read while secret/protected.
- **AuctionSense:** Experimental, read-only price-history chart under settings; it displays only real saved asks and timestamps, without launching scans or changing auction actions.
- **Map and quests:** Discoveries can show learned flight-master markers; the optional QuestSense navigation beacon can follow the user's selected map pin when reliable coordinates are available.
- **Emota:** Hunter idle behavior may include a native petting emote when the client exposes it and the feature is enabled; no emote is forced in combat.

This release retains the 2.2.24 improvements to compact meter menus, populated-row sizing, The Bar's native bag toggle and AuctionSense native Buy/Sell/Auctions tab highlights.

## Install

1. Download **ChalkBox-2.2.25.zip** from this GitHub release's **Assets** (not Source code, and not the separate CurseForge media ZIP).
2. Close WoW Forever. Extract its single `ChalkBox/` folder into `Interface/AddOns/`, replacing the existing addon folder.
3. **Keep SavedVariables** to preserve character layouts, bank snapshots, auction data and histories. In-game, verify ChalkBox → Updates shows **2.2.25**.

## Verify in Forever

Check a bank readout, resize a Bar module and reload, switch Market back to native AH Buy, and manually print a completed DPS fight to PARTY/SAY while grouped/out of combat. Confirm rows display in order. Test optional map flight markers and navigation only where genuine learned data is present.

**Known limits:** The client may restrict outgoing addon chat or withhold protected values. Successful chat API calls do not guarantee server delivery; native line renderer and bank placement still depend on client UI. Auction price history is based on observed asks, not completed sales.

**Release channel:** GitHub beta/prerelease. A stable promotion should follow a full in-game smoke pass. CurseForge publication, when used, requires a matching real Forever flavor and its own publisher verification.
