# ChalkBox 2.2.30 — Stable WoW Forever Release

The meter, the bar, auction scans, and moving your saved data now work as one addon. Your existing SavedVariables, layouts, and widths are kept.

- **Combat meter:** `/chalk meter status` says why the window is empty. Locked combat numbers no longer crash it. An empty live fight stays empty until you choose Last. Pets are labeled as pets. The window keeps the size you drag. When Blizzard's built-in meter is missing, locked, or empty, the window counts your damage and your pet from the combat log with its own fight timer.
- **The Bar:** The gold resize grip actually drags. Words stay inside each stat. Icons stay off until you turn them on with `/chalk bar icons on`. Saved widths are not rewritten.
- **Auction scans:** A browse that cannot load another page keeps the prices it already has. If the modern auction API is missing, the classic auction list is read instead. Failed scans still leave the last good snapshot alone.
- **Auction house tab:** Protected auction tabs are not given an addon click hook. Market still does not change Blizzard's auction mode.
- **Bags and quests:** A protected bag frame is not nudged. The quest menu attaches only to a real tracker header.
- **Data transfer:** Export and import copy the real records. Counts keep the higher number, and a backup is saved before anything changes.

## Previous: 2.2.29

# ChalkBox 2.2.29 — Stable WoW Forever Release

**CurseForge-ready stable build.** One installable ZIP carries ChalkBox and its optional data-transfer helper.

## What's changed

- **Combat Meter:** Now a personal, display-only meter. All ChalkBox manual PRINT, PARTY/SAY reporting, automatic after-combat messages, queued sends, copy-report windows and reporting menus have been removed. Legacy slash commands are silent no-ops. The live DPS/healing display, icons, window layout, fight selections and confirmed session reset remain available.
- **QuestSense:** Closest First or Lowest Level First, completed quests last by default, improved verification of objectives on nearby zone micro-maps, five/ten selection budget and solo exclusion of verified group quests. Blizzard's protected tracker stays in control.
- **AuctionSense restored:** The Market tab, Browse/Full scanning, My Items, Sales, and saved price history use the last stable 2.2.26 implementation. Experimental Intelligence is paused and removed from this build; its saved data remains untouched. Other professions and market features remain available.
- **The Bar:** Small optional Blizzard icons, colored tooltip details, adjustable module widths and retained Mac notch support.
- **Discoveries, LootSense and data transfer:** Retained map markers, observed drops, loot hints and cross-computer import/merge.

## Install / CurseForge

Upload **ChalkBox-2.2.29.zip** as the game file. The separate **ChalkBox-CurseForge-Media-2.2.29.zip** contains publishing artwork and copy only; it is not installable.

Keep your existing SavedVariables. Unpack the archive into the WoW Forever `Interface/AddOns` directory; the game ZIP includes `ChalkBox/` plus `ChalkBoxTransfer/`.

This release intentionally disables ChalkBox combat chat reporting instead of claiming delivery works on the current client. Blizzard's own damage meter and chat controls are unaffected.
