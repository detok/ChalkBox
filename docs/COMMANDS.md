# ChalkBox command reference

**Verified against ChalkBox 2.2.10 source.** Primary command: `/chalk`. Alias: `/cb`. Most tasks also have controls in **Options → AddOns → ChalkBox**. Commands are local actions unless explicitly noted.

## Main settings and item protection

| Command | Purpose |
| --- | --- |
| `/chalk`, `/cb`, `/chalk settings` | Open ChalkBox settings |
| `/chalk theme` | Open Global Appearance |
| `/chalk loot status` | Item advice and profession evidence diagnostics |
| `/chalk loot scan` | Recheck the currently open profession window and refresh supported hints |
| `/chalk loot on` / `off` | Toggle extra item advice; basic quest protection remains |
| `/chalk keep [item link]` | Add a personally protected item. Shift-click its link into chat. Exact item name is also supported |
| `/chalk forget [item link]` | Remove that personal KEEP mark |
| `/chalk list` | Print the personal KEEP list |
| `/chalk de [item link]` | Show the current modeled disenchant outcome estimate |
| `/chalk de on` / `off` | Toggle DE tooltip estimates |

## Discoveries and loot

| Command | Purpose |
| --- | --- |
| `/chalk drops map` | Open Discoveries, attached to the World Map |
| `/chalk drops map status` | Diagnose the Discoveries map button and attachment |
| `/chalk drops map flights status` | Count character-confirmed flight paths, visible markers and native Map Filter integration |
| `/chalk drops map flights on` / `off` | Fallback visibility switch for **Known Flight Paths** in Blizzard’s Map Filter dropdown |
| `/chalk drops map reset` | Restore the draggable Discoveries map button |
| `/chalk drops map on` / `off` | Show or hide the map button |
| `/chalk drops on` / `off` | Start or stop sampling readable loot windows |
| `/chalk drops tooltip on` / `off` | Show/hide personal loot notes in item tooltips |
| `/chalk drops status` | Show recorded item, loot and zone totals |
| `/chalk drops chance 5 20` | Calculate probability of at least one success in 20 independent attempts at a supplied 5% chance |
| `/chalk drops reference 123 3.5` | Mark a 3.5% reference for an already recorded item ID 123; it is explicitly unverified |

**Known Flight Paths:** Discoveries extends the native World Map **Map Filter** checkbox with a single **Known Flight Paths (ChalkBox)** option. The addon marks only taxi-map nodes whose state was actually `CURRENT` or `REACHABLE` when that character visited a flight master. It never treats an unknown node as discovered, and never loads a public list of undiscovered nodes. Existing paths become visible after opening a flight master; nodes without verified map coordinates are intentionally omitted. Flight markers never change the native map or start travel.

**Important:** DropSense observation counts are loot windows, not every enemy kill. Outdoor positions are where *you opened the loot window*, not exact spawn locations. Generic reference chances are user-supplied, not verified server odds.

## Quests, navigation, MacroForge and auctions

| Command | Purpose |
| --- | --- |
| `/chalk quests on` / `off` | Enable/disable QuestSense automatic watch management |
| `/chalk quests smart` | Prioritize accepted quests; focus on verified current-dungeon quests when available |
| `/chalk quests zone` | Nearby-only current-zone watch filtering |
| `/chalk quests all` | Accepted quests in quest-log order, subject to limits |
| `/chalk quests limit 5` | Select the auto-watch limit (5, 10, 15 or 20) |
| `/chalk quests refresh` | Queue native quest-watch reconciliation when safe |
| `/chalk quests status` | Inspect watch counts, selected mode, zone, instance match and API diagnostics |
| `/chalk macro`, `/chalk forge` | Open MacroForge |
| `/chalk forge rescan` | Rescan actually learned, active spells |
| `/chalk forge status` | Spellbook/MacroForge diagnostics |
| `/chalk auction` | Open AuctionSense when supported and the AH is available |
| `/chalk auction scan` | Explicit **browse asking-price scan** at an auctioneer |
| `/chalk auction full` | Request full listings; server cooldown and API limitations apply |
| `/chalk auction status` | Current scan state and market snapshot |
| `/chalk auction tooltip on` / `off` | Show or hide AH asking-price annotations |

**Quest compass (OFF by default):** `/chalk nav on|off|auto|next|prev|follow QUEST_ID|original|classic|hd|size 32-72|lock|unlock|reset|status`. The small outdoor arrow follows only accepted quests with verified waypoints. Auto honors Blizzard's super-tracked quest first, then the nearest known target. It never sets/clears your map pin or deletes other manual quest watches. It can add the selected accepted quest to Blizzard's native watch list, and never guesses an instance direction. See [Navigation](QUEST_NAVIGATION.md).

**Native quick actions:** On compatible Forever builds, right-click Blizzard's objective-tracker header to access QuestSense Settings, Off, Smart, Nearby and the Navigation toggle. The native `/macro` window may show a MacroForge button beside Delete in the native bottom row; `/chalk macro` always remains available.

**Safety:** Smart matching is conservative in dungeons; unverified quest matches do not clear your tracker. MacroForge never performs an unattended rotation. An AuctionSense scan observes asking prices rather than selling, bidding or purchasing.

## The Bar, bags and repair estimates

| Command | Purpose |
| --- | --- |
| `/chalk bar status` | XP rate, Bar layout and safe display diagnostics |
| `/chalk bar edit` or `edit on` / `off` | Toggle/finish Edit Mode; empty-Bar right-click also has **Done editing** |
| `/chalk bar layout` | Show positions of Bar modules |
| `/chalk bar layout reset` | Restore the release's default layout (does not reset other settings) |
| `/chalk bar move gear right` | Move a recognized module to left / center / right |
| `/chalk bar align gear left` | Change a recognized module's text alignment |
| `/chalk bar stat bagvalue on` | Enable the bag valuation metric |
| `/chalk bar stats balanced` | Apply Balanced, Minimal or All stat presets |
| `/chalk bar bagvalue junk` / `total` | Select junk-only or all-item vendor resale value |
| `/chalk bar repair status` | Check quote-learning sample count |
| `/chalk bar repair reset` | **Clear this character's repair quote history** |
| `/chalk bar top` / `bottom` / `off` | Bar placement/visibility |
| `/chalk bar reserve on` / `off` | Selective safe shift of eligible top Blizzard chrome |
| `/chalk bar reset` | Reset XP/hour and net-gold session counters |
| `/chalk bags offset -40` | Move separate bag windows 40px up (range -120 to +120) |
| `/chalk bags reset` | Return bags to Blizzard's position |
| `/chalk bags status` | Check bag offset, hook and deferred state |

The Bar's fresh layout differs from players' older saved layouts; upgrades do **not** forcibly overwrite customized positions. Repair numbers marked with a tilde are estimates.

## Combat, sessions, camp, personality and safety

| Command | Purpose |
| --- | --- |
| `/chalk meter show` / `hide` | Open/close the compact Combat Meter (starts closed) |
| `/chalk meter current` / `last` / `overall` | Select combat session |
| `/chalk meter dps` / `damage` / `healing` | Select supported display mode |
| `/chalk meter print` | **Explicit** post-fight report to PARTY using the same native Top 3/5/10 size and copy fallback as the gear menu |
| `/chalk meter reset` | Request reset confirmation |
| `/chalk meter status` | Available native API and meter layout state (rows = maximum; empty rows auto-collapse) |
| `/chalk meter rows 5` / `8` / `12` | Limit visible rows, up to five by default; raise cap for raids |
| `/chalk meter opacity 0-100` | Adjust **background only**; keeps names, icons and values readable |
| `/chalk meter lock` / `unlock` | Lock/drag and resize the compact window |
| `/chalk meter native status` | Native Blizzard meter extension diagnostics |
| `/chalk session` / `session last` | Open current or preceding Session Journal |
| `/chalk prep` | Print a camp/preparation checklist |
| `/chalk prep test` | Preview the preparation reminder |
| `/chalk prep tent done` / `clear` | Manually acknowledge tent use for one hour this session, or clear the acknowledgement |
| `/chalk prep tent status` | Check tent-state evidence |
| `/chalk emota status` | Personal emote/idle diagnostics |
| `/chalk emota auto on` / `off` | Toggle optional automatic native emotes |
| `/chalk emota idle preview` | Manually preview an idle emote |
| `/chalk guard` | Print QuietGuard filter status |
| `/chalk guard duel on` / `off` | Configure a single filter; other keys: guild, party, trade, channel |
| `/chalk update` | Installed version and GitHub release link |

The compact meter's **Menu** button or header right-click exposes PARTY/SAY reporting, shared native report size, auto-report options, settings, lock and confirmed reset. The experimental AuctionSense chart is under **Options → AddOns → ChalkBox → AuctionSense → Charts (Experimental)**; it has no scan shortcut or slash command. Left-click the Bar's **Bags NN free** to toggle Blizzard bags outside combat/edit mode.

**The Combat Meter does not broadcast a report without an explicit user action unless you separately enable supported native post-combat behavior.** QuietGuard protections default OFF on fresh installs. Emota automatic reactions are optional and avoid combat.

## Diagnostics and help

Run the exact `status` command for the affected module before opening a [bug report](https://github.com/detok/ChalkBox/issues/new/choose). An error message is much more useful than "doesn't work." The complete source handlers are in `ChalkBox/LootSense.lua` (root command dispatcher) and the individual module files.

[User handbook](USER_GUIDE.md) · [Troubleshooting](TROUBLESHOOTING.md) · [Documentation home](README.md)
