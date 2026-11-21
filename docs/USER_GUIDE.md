# ChalkBox player handbook


**Stable 2.2.36:** Includes 2.2.35. The reload emote wait starts when the world appears.

**Stable 2.2.35:** Includes 2.2.33. Emota waits one second after a UI reload.

**Stable 2.2.33:** Includes 2.2.32. `/chalk taintcheck` and `/chalk bmah`.

**Stable 2.2.32:** Includes 2.2.31. `/chalk journal` opens the storybook.

**Stable 2.2.31:** Includes 2.2.30. Read [the feature list](FEATURES.md) for what each tool is supposed to do.

**Stable 2.2.30:** Combat meter fallback, bar resize, auction scans, and a simpler data transfer. Saved data is kept.

**Previous 2.2.29:** Original AuctionSense Market/scanning interface restored. The experimental Intelligence Lab is paused; its saved data is preserved. ChalkBox Combat Meter reporting is completely removed, while the local meter display remains.

**ChalkBox 2.2.29 (stable) · World of Warcraft: Forever**

ChalkBox is a set of optional quality-of-life features inside **one addon**. Use Blizzard's **Options → AddOns → ChalkBox** pages or type `/chalk` (also `/cb`). Features that display observations are not proofs of unseen game data; ChalkBox should be conservative when Forever withholds information.

For installation and updates, start with [Getting started](GETTING_STARTED.md). For exact slash syntax, see [Commands](COMMANDS.md).

## Find your way around

The ChalkBox home page groups modules under **Discover & Track**, **Combat & HUD**, and **Personalize & Manage**. Several settings have nested pages in Blizzard's left sidebar, such as **The Bar → Modules / Appearance**, **LootSense → Appearance**, **Emota → Race Behavior / Emote Catalog**, and **Adventure Prep → Toast Appearance**.

The **Global Appearance** page controls ChalkBox's palette and panel visibility. These controls do not recolor Blizzard's own World Map or game menus. If a window is missing, check its own module's enabled/display setting before assuming the entire addon failed.

## LootSense and professions

**Use it for:** Understanding why the item under your cursor might matter.

- Quest items receive priority over general crafting hints. When the currently accepted quest objective can be matched to the item, a tooltip can show the **quest's title and collected/required progress**. Some items still simply say **KEEP — Quest Item** when a dependable objective match is unavailable; ChalkBox does not invent a quest title.
- **Future quest items** are a separate, hand-researched, small lookup by exact item ID. For Hops and other selected materials, a purple **FUTURE QUEST** note gives the *possible* quest, required amount and zone even when the quest is not accepted. It is labeled **Reference only**, filtered by known completion/faction, and never replaces the live accepted-quest name or progress above. See [the item-by-item research log](FUTURE_QUEST_DATA.md). Purple markers appear on supported **separate Blizzard bag windows**, without changing Blizzard's normal quest glow; they hide in combat and can be turned off under **LootSense → Appearance**. Combined bags/addon bags are not yet supported by the marker.
- **Personal KEEP** is a user decision. Shift-click an item into `/chalk keep [item]`, or use the LootSense settings page. Remove with `/chalk forget [item]` or the saved list controls.
- **Learned-recipe ingredients** are distinguished from **potential reference-catalog uses**. Open your profession window and use **Scan Open Profession** or `/chalk loot scan` if current learned recipes are not reflected.
- **RecipeAdvisor / ProfessionSense** use observed character profession data plus a bundled Forever-only recipe catalog. A catalog entry does not mean your character has learned that recipe.
- **LootSense Appearance** offers filters for extra ingredient insights. Quest protection and personal KEEP selections remain higher priority. Bag item-button decoration is intentionally conservative to avoid protected-action issues.

**Does not:** Automatically sell, delete, move, equip, disenchant or declare an unknown item safe to discard.

## DropSense and Discoveries

**Use it for:** Building your own observed loot journal.

From settings or `/chalk drops map`, the native World Map opens first when the client exposes Blizzard's map-toggle API; Discoveries remains attached to the map and never becomes an independent window. If native map opening is restricted, open the World Map yourself and select **Discoveries**.

1. Ensure **DropSense → Record drops automatically** is on, or type `/chalk drops on`.
2. Open a readable loot window. Observed item appearances are recorded; re-opening the same corpse should not count as another loot attempt.
3. Open the **World Map → Discoveries** button or type `/chalk drops map`. The journal docks beside the map; you can reposition the map button and reset it with `/chalk drops map reset`.
4. Select **Outdoor** or **Dungeons**; use **Area / Dungeon**, **Creature**, **Sort**, and **Search Items**. The area picker can follow the current map or browse a previously recorded location independently.
5. Hover an item row to inspect observations. **Rate** is computed only with a sufficiently identifiable creature source. With a mixed or unknown source, the journal does **not** pretend that the item has a creature-specific chance.

### Where did I loot it?

In version 2.2.8 and later, each item can retain up to **six distinct recent outdoor locations** in a zone. Hover the item to see up to three recent samples and how often nearby loot observations clustered there. If the creature was identified confidently, creature-specific samples are tracked separately. **Hover a Discoveries item with recorded coordinates while viewing that zone on the World Map to see a **temporary pulsing dot at its latest observed loot-window location**; the dot disappears when you stop hovering. These are your character's map coordinates when the loot window opened**, not confirmed spawn, death or official drop-location coordinates.

Older records, dungeon observations and readings without an accessible map position have no made-up coordinates. The journal does not place permanent pins automatically.

**Map marker rendering (experimental draft):** On supported Forever clients, native Blizzard MapCanvas pins position the temporary loot pulse and known flight-master markers during zoom/pan/zone-map transitions. A saved zone loot sample appears in a nested subzone only when Blizzard provides a valid conversion and that sample actually falls within the subzone. If that data is absent, the marker stays hidden rather than appearing in the wrong place. Older map clients use the existing conservative compatibility renderer. No change to which loot samples or learned flight paths are recorded. Use `/chalk drops map flights status` to see the current native/compatibility renderer and learned-vs-positioned counts.

### What the numbers mean

**Found** describes item quantity observed, **Loots** is the number of loot windows in which it appeared, and **Rate** is an *observed window frequency* from an identified source. It is **not** the official server drop rate, and unlooted kills are not counted. The `/chalk drops chance 5 20` calculator uses a chance *you supply* rather than one discovered from server data.

## Auction tools and disenchanting

These are three related but distinct systems:

| Area | What it does | What it cannot prove |
| --- | --- | --- |
| **AuctionSense** | A native Auction House tab for explicit market scans, searchable observed asking prices, quantities and scan age | That an item actually sold for its asking price |
| **AuctionInsights** | **My Items** bag appraisal and **Sales & Stats** based on captured seller mail/invoices in the native AH context | A complete lifetime account sales ledger |
| **DisenchantSense** | Read-only probability/value hints for eligible gear, using supported Forever brackets, Classic-reference probabilities and available auction asks | A guaranteed outcome, exact undisclosed Forever odds or automatic disenchanting |

**Full listings:** This is a heavier server snapshot of individual auctions, unlike regular Browse Scan. On Forever, the server can take much longer than 25 seconds to respond. ChalkBox now keeps waiting for the response or an explicit dropped-request event, rather than discarding a slow reply. A successful request is subject to the approximately 15-minute account-wide cooldown. A valid price, stack count and item ID can be recorded even when an item name has not finished caching, which ChalkBox labels `Item #ID` rather than discarding the listing.

**To scan:** Visit an auctioneer, open Blizzard's Auction House and choose the **AuctionSense** tab. Press **Scan Market** for the normal browse snapshot. **Full listings** is a separate, more expensive request; on supported servers it can have roughly a 15-minute cooldown. Scans happen only when you start them. The panel shows the realm/faction market, observation time and available data; stale or mixed equipment variants can make a value unreliable.

**Black Market:** Open the Black Market window. ChalkBox reads the list when the client sends it and keeps it apart from auction asking prices. In the AuctionSense panel, choose **Black Market** for what is listed now and what was seen before. `/chalk bmah` prints the count. ChalkBox does not bid. If this client has no Black Market, that command says so.

If a browse result does not provide listing-level information, an **average ask or number of listings cannot be assumed**. If a previous full scan supplied real averages and listing counts, those remain visible with their original full-scan age after Browse Scan refreshes the minimum price. Do not interpret listing asks as real completed sales. Existing complete snapshots should survive an incomplete or failed scan.

**Experimental charts (2.2.24 beta):** Open **ChalkBox → AuctionSense → Charts (Experimental)** from Blizzard's AddOns settings. Enter a previously scanned item name or ID and select **Find Item**. The chart plots up to seven existing, dated observations of the **lowest asking price per unit** with hover details, using native lines or a texture fallback. One point is not a trend; a missing item has no invented graph. It does not start scans, retain weekly history, or establish actual selling prices. See the [release candidate test](RELEASE_CANDIDATE_TEST_2.2.24.md).

**To use the estimates:** Enable optional auction/disenchant tooltip hints in AuctionSense settings. For a specific item, shift-click it into `/chalk de [item]`. Tooltips may show ranges, partial price coverage or an unconfirmed bracket. Nothing is automatically bought, posted, mailed, sold or disenchanted.

## QuestSense

**Use it for:** Managing Blizzard's *existing accepted-quest tracker*, not automatically selecting the best leveling route.

Enable **Automatic quest tracking** and choose:

| Mode | Behavior |
| --- | --- |
| **Smart (recommended)** | Scores accepted quests using nearby map/header evidence and recently accepted quests. **In a recognized party dungeon**, narrows watches to accepted quests confirmed for that specific instance from dungeon map information or a directly matching quest-log section/title. |
| **Nearby only** | Conservatively tracks quests matched to your current zone, temporarily hiding remote watches and restoring prior manual selections as they become relevant |
| **All accepted** | Attempts accepted quests in quest-log order, subject to the available auto-watch capacity |

The automatic limit is **5, 10, 15 or 20**, with a fresh default of **10**. Manually watched quests get preference. QuestSense respects deliberate manual unwatching and saves suspended manual watches for restoration.

**Dungeon caveat:** Forever may not return complete dungeon quest-map information. If ChalkBox cannot verify any matching quests for the current dungeon, **it preserves the existing tracker**, rather than hiding everything or guessing from a generic "Dungeon" tag. It does not make dungeon decisions while combat, the World Map or the quest log makes editing unsafe. Check `/chalk quests status` for the actual instance, matched count and reason.

**QuestSense → Navigation (optional):** Enable a small movable arrow from the child settings page or type `/chalk nav on`. The arrow **floats by itself**, with no background box, labels or permanent buttons. **A small yard-distance label** sits under the floating arrow. **Hover** for the quest name and full GPS state; **right-click** for **Auto / Next / Hide** and **left-drag** to move. The settings page offers three appearances: **Original WoW** (default on newly configured characters), **Blizzard Navigation**, and **ChalkBox HD (256px)**. A **32–72px Arrow Size slider** controls the arrow and its distance label together; default size is 48px, and existing saved styles are not overwritten. Right-click the **header of Blizzard's own quest tracker** for **QuestSense Settings**, **Off**, **Smart**, **Nearby**, and **Navigation On/Off** where the native tracker exposes mouse events. No quest-row actions are replaced. The selected accepted quest stays visible in Blizzard's native quest tracker; no competing ChalkBox quest list is created. Auto honors your selected quest in the Blizzard quest log or the active super-tracked quest; if neither exists, it sticks to a known outdoor target rather than changing targets constantly. **When dead or ghosted**, your corpse takes priority if Forever provides its actual map coordinates; resurrection returns to the chosen quest. Settings provide Previous, Lock and Reset Position. It never changes Blizzard's quest watches or map pins, and displays an unavailable message rather than guessing inside dungeons. See [QuestSense navigation](QUEST_NAVIGATION.md).

QuestSense **does not** estimate enemy difficulty, quest XP per hour, exact travel distance, or a best questing route. Smart is a watch-priority system rather than a routing agent.

## MacroForge

**Use it for:** Building legitimate WoW macros from your character's currently learned, active spells.

Type `/chalk macro` or open **MacroForge** in settings. When Blizzard's own `/macro` editor is open, a small **MacroForge** button in the native bottom action row (after Delete, before New/Exit) opens the full ChalkBox workbench alongside the native editor if enough screen space exists. On narrow screens it opens standalone, without moving or replacing Blizzard's macro interface. **Open MacroForge** from ChalkBox settings now closes that settings overlay first, opens the existing Blizzard /macro editor if available, and docks Forge beside it when there's room. Closing `/macro` closes only an attached workbench; saved builds and native macros remain untouched. Choose **Engage Target**, **Burst + Trinkets**, **Modifier Keys**, **Manual Sequence**, or **Mouseover Utility**. Select a slot on the left and a spell on the right. Check options such as pet attack, Auto Shot or trinket attempts where relevant.

The framed workbench shows generated macro text in a **multiline, scrollable preview**. **Select Text**, then press **Ctrl+C** to paste the text into WoW's `/macro` editor. **Install New** is an explicit, out-of-combat action that creates a *new* character macro and refuses to overwrite an existing one. **Saved Builds** retains named recipes, which are revalidated against your current spellbook.

The code is bounded by WoW's macro size limit and secure action restrictions. Auto Shot, pet commands and trinket lines are separate attempts, **not promised additional casts**. A `/castsequence` advances when game rules permit the next step; it cannot automatically skip a failed cooldown. MacroForge cannot run a combat rotation, bypass the global cooldown or react to procs without a new physical keypress.

An optional **Show MacroForge in AddOn Compartment** checkbox adds a shortcut below the minimap calendar on compatible clients. It starts off; disabling an already registered extra entry may require `/reload`.

## The Bar and Repair Learning

**Use it for:** A compact, configurable 18px screen-edge summary.

New Bar profiles start with **Left:** level/progress, XP/hour; **Center:** elapsed session time, time to level, rested XP; **Right:** bag slots, gear condition, repair estimate, junk vendor value, gold/net, world latency. The pet metric remains available but begins hidden. Older saved arrangements and valuation modes are not silently overwritten.

The Bar has **Balanced**, **Minimal**, **All**, and per-stat settings, plus opacity and position controls. Its width can hide the lowest-priority metrics on a small screen. **Left-click Bags NN free** to open or close Blizzard's normal bags (outside combat/edit mode); left-click Bag Value to switch its value mode. Right-click an ordinary stat for its controls. Right-click **empty Bar space → Edit layout**. Drag a module's main body to move it between left/center/right groups; drag the **small gold grip at its right edge** to resize that module without moving it (60–280 px). The width preview snaps to 4px increments and is saved per character on release. Right-click an ordinary stat for its **Width** submenu, or use `/chalk bar width bags 112` / `/chalk bar width bags reset` for precise changes. Right-click empty space again for **Done editing**. Reset Layout restores the original order, alignment **and widths**. If the bar becomes crowded, its existing adaptive layout hides lower-priority metrics rather than allowing overlap.

The optional **Shift top UI below the Bar** uses selective Blizzard-frame positioning; ChalkBox does **not** resize or move `UIParent` or protected action bars. Separate bag offset is configurable from -120px to +120px and deferred when the bank/combat state would make it unsafe.

**Repair Learning** uses real observed merchant repair quotes to estimate future repair costs away from the merchant. An estimate is visibly prefixed with `~`. It is not an exact quote; currency, conditions and vendor discounts can vary. `/chalk bar repair reset` clears the stored repair-learning samples.

## Combat Meter and Session Journal

The optional compact **Combat Meter starts hidden**. Open it from settings or `/chalk meter show`. The header has one **Menu** button; right-clicking the header opens the same menu. Switch DPS/damage/healing/HPS/taken/interrupts and Current/Last/Overall, choose icon style or lock, and resize the window. Its default maximum is **five rows**, automatically collapsed to actual visible participants; optionally increase the cap for raids. On-window and settings opacity controls adjust **only the background**, leaving names, DPS and class icons readable.

**Combat reports retired in 2.2.29.** ChalkBox neither broadcasts nor prepares DPS/party/say summaries, automatically or manually. The old print/native report slash commands are silent no-ops, and report menus have been removed. Blizzard's combat meter and normal party chat remain unaffected. **RESET** still requires confirmation and clears the native shared combat sessions.

**Adventure Journal (Session Journal)** now opens in a fully framed, warm wood window with Session Summary and Field Notes sections; it remains readable even if global background opacity is zero. The existing recording still keeps the current session and up to **20 prior** snapshots of supported observed statistics: XP, gold, completed quests, sampled loot, camp reminders and other available events. It does not retroactively invent events from before installation. Use `/chalk session` or `/chalk session last` for that summary. `/chalk journal` opens the storybook, which reads the session, the chronicle, discoveries, quests, professions, auction asks, bank value, combat, and camp notes into one window. It does not change those records, and it waits until combat ends before refreshing. Left-click the level stat on the Bar to open the same window.

The Adventure Chronicle records new milestones only: levels, quest turn-ins, deaths, party dungeons, and rare drops the client identifies. Turn it on or off under **Session Journal → Adventure Chronicle**. Old session summaries are not rewritten.

## Adventure Prep, Emota and QuietGuard

**Adventure Prep** is a reminder/checklist system for known camping, tent/rested XP, food/buffs, supplies and class/pet-care signals. A tent's rested-XP effect does not prove the separate **Camp Benefits** effect is active. If the client cannot verify tent use, **Tent Used** / `/chalk prep tent done` acknowledges it for one hour of the current session; it does not grant an in-game buff. Toast appearance, lock and transparency are configurable.

**Emota** optionally tries native character emotes, jokes and idle behaviors with randomized pacing, race/class flavor and supported contextual checks. Automatic reactions are **opt-in** and avoid interruption during combat. Preview with `/chalk emota idle preview` and tune behavior under Emota's nested pages. The addon cannot guarantee a native emote animation merely because the request returned successfully.

**QuietGuard** uses optional guild, duel, party, trade and channel-request filters. **All five start OFF on a fresh installation.** A previously saved ON selection remains ON across upgrades. Blizzard's own social blocking settings can also block invitations independently of ChalkBox.

## Appearance, bags and updates

**Global Appearance** controls ChalkBox's background/accent choices while leaving Blizzard's native Settings transparency alone. Discoveries and MacroForge share a warm, wood/map-derived visual family, with safe fallbacks when the requested native atlas is unavailable. It does not re-skin the game itself.

**Bags** offers a bounded vertical offset for separate bag windows; layout changes defer around combat and bank frame initialization rather than manipulating protected inventory buttons.

**Updates** displays the installed addon version and a GitHub Releases URL you can copy. It **does not fetch a live GitHub version over the Internet from the WoW client**. An optional group-member version comparison uses versions seen from other ChalkBox players in the group; absence of a newer peer isn't proof there is no newer GitHub release.

## Getting help

Start with [Troubleshooting](TROUBLESHOOTING.md), then [Commands](COMMANDS.md) for diagnostics. When filing a bug, supply the ChalkBox version, actual WoW Forever client build, location or dungeon if applicable, reproduction steps and any Lua stack. Avoid sharing private chat or account details.

[Documentation home](README.md) · [Getting started](GETTING_STARTED.md) · [Release notes](RELEASE_NOTES.md)


**2.2.25 GitHub beta:** Adds the bank vendor-value label, per-module Trail Bar widths, standard ranked combat chat, experimental price-history charts and optional map additions. Read the [current release notes](RELEASE_NOTES.md). **2.2.22 remains the last fully accepted stable release.**


**Developer beta:** ChalkBox 2.2.27 is a QuestSense Smart experiment; 2.2.26 remains the supported stable release. [Beta notes](https://github.com/detok/ChalkBox/blob/feature/smart-quest-native-priorities/docs/RELEASE_NOTES.md).
