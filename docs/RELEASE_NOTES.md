# ChalkBox 2.2.29 — Stable WoW Forever Release

**CurseForge-ready stable build.** One installable ZIP carries ChalkBox and its optional data-transfer helper.

## What's changed

- **Combat Meter:** Now a personal, display-only meter. All ChalkBox manual PRINT, PARTY/SAY reporting, automatic after-combat messages, queued sends, copy-report windows and reporting menus have been removed. Legacy slash commands are silent no-ops. The live DPS/healing display, icons, window layout, fight selections and confirmed session reset remain available.
- **QuestSense:** Closest First or Lowest Level First, completed quests last by default, improved verification of objectives on nearby zone micro-maps, five/ten selection budget and solo exclusion of verified group quests. Blizzard's protected tracker stays in control.
- **AuctionSense and professions:** Previous optional inventory intelligence, recipe guidance, item-value history and price insights remain.
- **The Bar:** Small optional Blizzard icons, colored tooltip details, adjustable module widths and retained Mac notch support.
- **Discoveries, LootSense and data transfer:** Retained map markers, observed drops, loot hints and cross-computer import/merge.

## Install / CurseForge

Upload **ChalkBox-2.2.29.zip** as the game file. The separate **ChalkBox-CurseForge-Media-2.2.29.zip** contains publishing artwork and copy only; it is not installable.

Keep your existing SavedVariables. Unpack the archive into the WoW Forever `Interface/AddOns` directory; the game ZIP includes `ChalkBox/` plus `ChalkBoxTransfer/`.

This release intentionally disables ChalkBox combat chat reporting instead of claiming delivery works on the current client. Blizzard's own damage meter and chat controls are unaffected.
