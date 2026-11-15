# ChalkBox feature claims and evidence (2.2.12)

Use this file when reviewing release announcements and the CurseForge listing. It reflects shipped code and automated tests; **live-client validation is still a separate step**.

| Feature | Shipped behavior | Must not claim |
| --- | --- | --- |
| LootSense, ProfessionSense | Personal KEEP, quest item name/progress when matched, observed learned recipe evidence and bundled potential recipe uses | That unknown items are safe to sell; every custom quest item has a matched title |
| DropSense | Readable loot-window item/source tracking, zones and dungeons, up to six recent outdoor loot-window positions | Official server odds, every kill counted, exact corpse/spawn location |
| Discoveries | Searchable, sortable map-docked personal journal, source/area filters, item hover, warm frame | Every zone already has a history or every atlas exists on each client |
| AuctionSense | Manual browse market asking prices, optional server-throttled full listings, scan age and market context | Realized sales, automatic trades, unprovided listing averages |
| AuctionInsights | Read-only bag appraisal and observed seller-mail Sales & Stats in the native AH | Complete lifetime sales/profit data |
| DisenchantSense | Read-only modeled outcomes and value estimates when supported | Guaranteed drops, exact unknown Forever odds, automated DE |
| QuestSense Navigation | Optional movable outdoor quest compass from real accepted quest waypoints; Auto, Next, manual selection, yard distance and conservative missing-coordinate message | No route database, instant dungeon GPS or modification of Blizzard map pins or quest watches |
| QuestSense | Native tracker management: Smart, Nearby, All; verified dungeon-specific Smart filtering with safe fallback | Best XP route, unverified custom dungeon matches, travel distances |
| MacroForge | Learned-spell wizard, templates, saved recipes, scroll preview, manual copy and explicit new install | Automated rotations, secure action bypasses, silent overwrite |
| The Bar + Repair Learning | Compact configurable edge HUD, saved layouts, safe chrome shift, observed quote estimates | Protected UI relocation or exact repair quote when away from merchant |
| Combat Meter | Optional meter, selected native statistics and gated manual PARTY reports | Always-readable combat data, automatic unrestricted spam |
| Session Journal | Current and up to 20 prior observed sessions | Retroactive history |
| Adventure Prep | Camping/rest/supply reminders, bounded toast and manual tent acknowledgement | That the tent proves an independent Camp Benefits buff |
| Emota / QuietGuard | Opt-in emote attempts and default-OFF social request filters | Guaranteed emote animation or automatic invite blocking for a new user |
| Appearance / Bags / Updates | Local ChalkBox theming, safe separate-bag offset, installed version and release link | Restyling Blizzard's entire UI or direct in-game GitHub HTTP polling |

## Visual and distribution claims

- Current visual direction: wood-derived Discoveries/MacroForge with a native outer frame, separate readable inset sections and fallback if requested atlas art is unavailable.
- The ten JPGs under `curseforge/screenshots/` are **genuine gameplay captures from an earlier build**. They are not proof the latest 2.2.10 UI has been visually accepted.
- Editorial SVG/PNG illustrations are separate from gameplay captures.
- The game ZIP is one root `ChalkBox/`; CurseForge media ZIP is for publisher assets only.
- No claim of official Blizzard endorsement or verified Retail/ordinary Classic support.

For test evidence and client QA, see [Maintainer runbook](https://github.com/detok/ChalkBox/blob/main/docs/MAINTAINER_RUNBOOK.md) and the repository CI. For a new release update the table when implementation actually changes.
