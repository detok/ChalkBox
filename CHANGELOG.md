Warning: truncated output (original token count: 19069)
Total output lines: 676

# Changelog

## 2.2.38 — Taint log and journal frames

- `/chalk taintcheck` saves the last blocked actions with function, module, stack, and time.
- A zero bag offset does not hook bag layout at login. The bar does not anchor to a protected world frame.
- The storybook and adventure chronicle match the session journal and have a Close button. Escape closes them.
- The combat meter no longer registers for WoW Forever's blocked combat-log event; it continues to use Blizzard's native damage feed.

## 2.2.37 — Market tab realm line restored

- A blank normalized realm name falls through to the ordinary realm name.
- An existing saved market stays visible and keeps its original key.

## 2.2.36 — Reload emote wait actually covers the world appearing

- The one-second wait started too early and the emote call was wrapped in pcall, which the client reported as UNKNOWN() under the name ChalkBox Emota.
- Automatic emotes wait five seconds after the world appears. The call is direct. Later emotes are unchanged.

## 2.2.35 — No blocked-action popup on reload

- Automatic emotes wait one second after login or `/reload`. Everything else about Emota is unchanged.

## 2.2.33 — Login block fix and Black Market

- Login and reload no longer move the minimap, buffs, unit frames, or bag anchors. `/chalk taintcheck` reports a blocked action if one was recorded.
- Black Market listings are saved on their own. They do not mix into auction prices, Fill price, or Inventory Intelligence. `/chalk bmah` and the AuctionSense Black Market view show them. Nothing is bid.

## 2.2.32 — Chronicle, intelligence, posting help, storybook, and a scan that answers

- The auction Scan Market button stays clickable and says what it is doing. `/chalk auction debug` prints the API path and the throttle.
- Adventure Chronicle records new levels, quests, deaths, and party dungeons without rewriting old sessions.
- Inventory Intelligence loads again, off until enabled, and keeps old notes.
- Fill price copies a saved ask only when you click it, and never presses Post.
- `/chalk journal` opens a read-only storybook of the other modules.

## 2.2.31 — Feature contract and journal

- Added `docs/FEATURES.md`, the intended behavior of every feature.
- Session journal counts quiet time longer than ten minutes, keeps the highest drop counts, and leaves an unfamiliar save untouched.

## 2.2.30 — Meter, bar, scans, and transfer

- Combat meter reports why it is empty, survives locked numbers, keeps an empty live fight empty, labels pets, and holds its dragged size.
- When Blizzard's damage meter is missing, locked, or empty, a personal combat-log count of you and your pet is shown. Those numbers are not saved.
- Bar resize grips drag. Stat text stays inside its module. Icons stay off until explicitly enabled. Saved widths are kept.
- Auction browse keeps a page it already received, and falls back to the classic auction list when the modern API is missing.
- Protected auction tabs, protected bags, and the whole quest tracker frame are left alone.
- Data transfer keeps the higher discovery count, dedupes sales, and writes a backup before import.

## 2.2.29 — Stable restoration release

- Restored the AuctionSense Market tab, Browse/Full scans, My Items, Sales and historical data presentation from the last stable 2.2.26 implementation. Experimental Inventory Intelligence Lab is paused in shipped addon without deleting saved data.
- Removed all automatic and manual Combat Meter chat reports. The native reporter and copy window are omitted from the install ZIP, reporting menus removed and old commands silently disabled.
- Local combat stats, QuestSense, The Bar, Discoveries, LootSense, MacroForge and data transfer remain.
- Published as a versioned stable CurseForge-ready ZIP with retained character SavedVariables.

## 2.2.28-quest-beta — Cleaner QuestSense Smart and Nearby

- Smart priority options are Closest First and Lowest Level First, with completed quests last by default and an optional completed-first override.
- Nearby uses zone micro-map children and each quest's own validated waypoint map to find more true local quests without cross-zone guesses.
- Five/ten is the combined watch selection budget; existing manual overflow is preserved rather than removed without consent.
- Newly accepted eligible quests receive a slot and remain manually owned; clearing navigation focus releases its Nearby exemption.
- Expanded solo group-quest detection, Nearby status diagnostics and simulated five/ten candidate regression tests.
- Preserves the built-in Blizzard quest tracker without insecure sort overrides.

## 2.2.27 — QuestSense Smart priorities (Beta)

- Prefer actual Forever quest-helper distances for Smart's nearest objectives, with current-zone priority and configurable completion/level/title/log ordering.
- Improve Nearby's local subzone quest evidence and optional short-distance radius.
- Add Smart Rules under QuestSense settings through the existing tracker-header menu.
- Preserve manual watches, dungeon-only focus, navigation and protected quest-log behavior. Native tracker visual sorting and collapsible zone headings are not part of this beta.

## 2.2.26 — Adventure Tools & World Map

- Discoveries: Display learned flight paths and recorded outdoor loot locations on local World Maps, with per-item map highlighting.
- LootSense: Offer selected future-quest item context.
- AuctionSense: Show observed asking-price history charts and connected item-value information.
- The Bar: Adjustable stat module widths and remembered bank vendor value.
- Combat Meter: Ranked PARTY/SAY reporting and compact display controls.
- QuestSense & MacroForge: Optional map-pin navigation and native macro-editor workbench integration.
- Emota: Optional Hunter pet interactions on supported Forever clients.

## 2.2.25 — Bank valuation, adjustable HUD, chat reporting and navigation (Beta)

- Show the last observed per-character bank vendor value in The Bar and a small frameless label above the bank's coin bar; preserve missing/partial-value honesty and separate auction asking-price estimates.
- Add per-module, per-character Trail Bar width grips in Edit Mode, with persistence, clamping, drag-to-reorder and reset intact.
- Replace broken meter report formatting with plain separate ranked PARTY/SAY chat lines. Fix false native meter Edit Mode guard; remove copy fallback, stray pipes and embedded newlines. Pace PARTY lines at 200ms and keep SAY on the direct click, as established damage-meter addons do. Auto-report remains opt-in.
- Extend AuctionSense's read-only historical asks chart and add learned flight-master map markers plus optional navigation following a selected map pin.
- Allow Hunter Emota idle PET reaction only when the native client exposes it; preserve user opt-in and combat safeguards.
- Expand regression coverage for bank display, saved widths, maps, auctions and protected chat reporting. No SavedVariables reset or automatic trading.

## 2.2.24 — Release candidate polish and experimental charts (Beta)

- Consolidated the compact combat meter into a gear/right-click menu, with actual-user-count height fitting and a five-row fresh default. Saved manually resized row caps are retained.
- Reused Blizzard native meter's validated Top 3/5/10 PARTY/SAY reporting engine and opt-in auto-report preferences; manual chat-copy fallback remains and never bypasses Forever restrictions.
- Matched Combat Meter background-only opacity to The Bar's theme and preserved legibility of text, icons and values.
- Restored AuctionSense's initial Buy highlight and the first native tab highlight after leaving Market without changing Blizzard's auction mode.
- Added The Bar Bags left-click action using Blizzard's native ToggleAllBags outside combat and layout editing.
- Added an **experimental, settings-only AuctionSense Charts** page reading actual saved seven-observation low-price history, with native Line and texture fallback. No new scans, storage expansion or claimed sales price.
- Hardened graph API fallback and tests. Existing AuctionSense/SessionJournal SavedVariables schema and protected trading actions remain unchanged.
- GitHub **prerelease only** until WoW Forever live verification; 2.2.22 stable remains downloadable.

## 2.2.23 — Forever combat report reliability (Beta)

- Respect chat lockdown and addon messaging restrictions; show a native copyable manual report whenever Forever rejects addon-sent combat chat.
- Avoid auto-SAY outside instances and do not treat a successful API request as confirmation of delivery.
- No changes to combat data, scanners, macro tools, layout or saved player settings. 2.2.22 remains stable.

## 2.2.22 — Full auction snapshot completeness (Beta)

- Monitor growing Forever replicated auction counts through the entire scan and confirm a final stable count before committing.
- Bound unreadable indexes and guard corrupt cumulative price totals while preserving previous complete snapshots.
- Keep all UI layouts, item calculations and protected trading controls unchanged.

## 2.2.21 — Forever full-scan lifecycle and Market tab (Beta)

- Track full snapshot cooldown from request acceptance, allow ten-minute reply window, and settle growing listing counts before processing.
- Surface actual waiting/receiving/processing status and prevent the Market tab label from truncating on the native auction frame.

## 2.2.20 — Large Forever auction snapshots (Beta)

- Remove the too-small 150,000 listing hard limit that rejected real Forever AH responses; retain bounded batch processing and a high corruption safety ceiling.
- Add large-snapshot regression and retain all previous market observations on interrupted scans.

## 2.2.19 — AuctionSense Forever replication reliability (Beta)

- Wait for real full listing data without the premature 25-second abort, using the modern Forever replication event and actual dropped-request signal.
- Handle early event before its item count becomes readable and preserve real full-snapshot averages/listing counts across browse refreshes with separate data age.
- Preserve the fast browse scan, account-wide throttle, market rollback, and safe data estimates.

## 2.2.18 — Item tooltip polish (Beta)

- Give DropSense observed counts and source-specific sample rates clearer hierarchy without changing calculations.
- Use the shared tooltip palette for LootSense explanations and quest progress.
- Apply gold monetary emphasis to AuctionSense asking prices and clarify DropSense settings terminology.
- Preserve all existing saved data and decision logic.

## 2.2.17 — QuestSense arrow size/default and MacroForge native UI polish
- **Original WoW classic arrow** is now the default on fresh characters; existing HD/Blizzard style preferences are preserved.
- **Arrow size slider** under QuestSense → Navigation: 32–72px in 4px steps, with a smaller 48px default, saved per character. Adjusts the compact arrow and yard-distance label without affecting navigation math or quest selection. Chat: `/chalk nav size 48`.
- **MacroForge native footer button** now sits next to Blizzard's Delete button and before New/Exit when the client's own controls are available and have room; otherwise it does not cover the native interface.
- **Settings → Open MacroForge** now closes the options overlay, opens the actual Blizzard macro editor if supported, and docks the existing workbench beside it at a readable scale if there is screen space. Narrow-screen or unsupported editors safely keep the standalone Forge.
- Additional Lua 5.1 regression coverage for native editor controls, window workflow, arrow sizes and preserved saved state. No macro write changes or SavedVariables migrations.

## 2.2.16 — Native quest-tracker context menu, 3 arrow styles and MacroForge macro-editor integration
- **QuestSense quick menu:** Right-click Blizzard's quest tracker header for **QuestSense Settings**, **Off**, **Smart**, **Nearby**, and **Navigation On/Off**. Additive header-only hook using modern/legacy game menus; never replaces quest-row interactions, the tracker, or Blizzard map pins.
- **Three arrow appearances** in QuestSense → Navigation: **Original WoW** (first minimap arrow), **Blizzard Navigation** (newer native atlas), and **ChalkBox HD** (256px art). Existing HD/Classic preferences are preserved, and all navigation logic remains unchanged.
- **MacroForge sidecar:** A small MacroForge tab above Blizzard's `/macro` editor opens the full existing Forge workbench alongside the native window on wide screens. When there isn't enough space, Forge opens standalone without moving Blizzard's editor. Closing the native editor closes only a docked Forge; the old `/chalk macro` shortcut remains.
- All actions are opt-in. No native macro content edits, insecure combat work, quest tracker replacements, forced UI repositioning or SavedVariables migrations. Extend Lua 5.1 regressions, docs and packaging.

## 2.2.15 — Full Scan resilience, native selected quest watch, Discoveries map pulse & HD arrow
- AuctionSense Full Scan now keeps real item ID/quantity/buyout information from replica listings with uncached names instead of discarding an otherwise valid scan. Uncached names display as `Item #ID`; server refusal and 15-minute account-wide cooldown diagnostics are clearer. Normal browse scanning and stored price history remain intact.
- QuestSense Navigation ensures its currently selected accepted quest stays **visible in Blizzard's native quest-watch tracker**, even in Nearby mode, without removing unrelated manual watches or changing super-tracking. Changes defer while unsafe and report a full watch list.
- Discoveries item-hover now **briefly pulses a gold dot on the visible map** at the latest personal outdoor loot-window location. It disappears on leave/map/filter change and never creates permanent pins or guesses corpse positions.
- The bare floating compass now includes a tiny **yard-distance label underneath** and a **Sharp HD / Classic** toggle in QuestSense Navigation settings. The new HD design is a 256-pixel transparent TGA generated reproducibly from original SVG artwork; the old Blizzard arrow remains available.
- Add targeted Lua 5.1 regressions, packaging checks and current player/publisher documentation.

## 2.2.14 — Correct QuestSense bearings, follow selected quests and find your corpse
- Correct the compass bearing using WoW's actual world-coordinate axes: **+X north, +Y west**. Prefer the client-native north-up navigation atlas; stabilize bearings near the destination and across angle wrap.
- **Follow the selected quest:** honor current Blizzard super-tracking and user selection in the quest log; choosing another quest releases stale manual overrides. When a selected quest has no reliable coordinates, show unavailable instead of silently following an unrelated quest. When nothing is selected, keep the fallback quest stable rather than repeatedly switching to the nearest.
- **Corpse recovery:** while dead/ghosted, follow the actual corpse marker returned by the current/parent map. If the marker is unavailable, clearly withhold directions. On resurrection, return to the previous quest selection.
- Retain the **arrow-only UI** with right-click Auto/Next/Hide, saved drag/lock, and tooltip. No existing QuestSense watch list, user waypoint, or Blizzard super-tracking writes.
- Add directional regression checks for all cardinals and facing changes, next-waypoint resolution, target selection events, corpse-parent fallback, and death/resurrection safety.

## 2.2.13 — QuestSense arrow-only UI
- Simplify the optional quest compass to **only the floating 64px MinimapArrow**. Remove its permanent opaque box, outer border, title/distance panel and visible action buttons. Preserve existing target, position, locking, waypoint reads, navigation logic and saved settings.
- **Right-click the arrow** for the three native menu actions: **Auto (follow tracked)**, **Next quest**, **Hide arrow**. Support both native MenuUtil and legacy EasyMenu clients, with QuestSense settings as a compatibility fallback.
- **Hover** for quest name, straight-line distance or clear GPS-unavailable message. An unavailable direction now leaves a muted gray arrow rather than displaying a potentially wrong heading; valid directions stay fully visible.
- Preserve left-drag positioning and saved location; the existing settings page still offers enable/disable, previous quest, lock and reset. No quest-watch, map-waypoint, super-tracking or gameplay API changes.

## 2.2.12 — QuestSense Navigation compass (test release)
- **QuestSense Navigation:** add a compact, optional, movable native-bordered arrow that follows verified accepted quest waypoints, displays the current quest and straight-line yard distance, and safely hides its direction when the player position/facing or destination cannot be resolved.
- **Auto / Next / Hide** directly on the compass, with a new **QuestSense → Navigation** settings page for activation, previous quest, position lock, reset and status. `/chalk nav` commands support the same actions and `follow QUEST_ID`.
- Auto prefers the super-tracked quest when it has an actual waypoint, then the closest known outdoor waypoint on the same world region. Explicit manual choice takes priority, and old selections survive brief waypoint/quest-log unavailability.
- **No quest/watch side effects:** never set or clear Blizzard map pins, replace user super-tracking, edit watch lists, automate movement or guess locations. Navigation starts OFF, is per character, and leaves all original QuestSense configuration untouched.
- Add regression coverage for real waypoint APIs, coordinate/facing geometry, eastern-kingdoms continent zero, cross-region and instance guards, saved position/lock, manual priority, failed/missing API data and cosmetic fallbacks.

## 2.2.11 — Adventure Journal native frame and Chronicle design (Gate A)
- Replace the unfinished translucent Session/Adventure Journal window with the warm World Map-derived wood body, native Blizzard outer border and two bronze-framed reading sections already familiar from Discoveries. On older clients, use a slim bronze outer-frame fallback.
- Correct the invisible-background regression: a global theme opacity of zero no longer makes the Journal disappear. Atlas lookup is guarded, missing native art gets an opaque fallback, and reopening retries the atlas.
- Register `ChalkBox_JournalThemeRefresh` for live Global Appearance updates. Keep current/saved session navigation and all 12 existing observations.
- **No session migration or new gameplay recording.** Existing version-1 per-character session history is untouched. Add a separate Full Adventure Chronicle design for validated, bounded milestones, deduplication, privacy, older-session compatibility and future Today / Timeline / History views.
- Add Lua 5.1 tests for native/fallback borders, atlas retry, zero-alpha readability, warm inset depth and unchanged saved data. The full recorder remains a subsequent stage.

## 2.2.10 — Smart QuestSense dungeon filtering (test release)
- **QuestSense Smart:** entering a named party dungeon automatically switches the normal auto-tracker to quests confirmed for *that instance* using current-instance map POIs or an exact dungeon-name quest-log category/title match. Nearby and All accepted behavior remain unchanged.
- Temporarily hide manual quests not matched to the dungeon while keeping their watch choices in existing `suspendedManual` state. Restore them and ordinary Smart tracking when leaving; switching dungeons switches quest filters. Respect manual unwatch and automatic watch limits.
- When Forever supplies no confident dungeon mapping, **preserve existing watches** and report a diagnostic reason; never guess from a generic Dungeon quest tag, use unaccepted POIs, clear the tracker, or change watches in combat / while map or quest log is open.
- Periodically recheck dungeon Smart watches, as Nearby already does, to recover missed zone / quest update events. No extra windows, SavedVariables changes or changes to dungeon scripts, other modules, or the macro system.
- Lua 5.1 regressions cover two distinct dungeons, instance map-floor ancestry, manual suspend/restore, unknown-instance fallback, deferral, no unaccepted quest watches and the existing outdoor modes.

## 2.2.9 — Warm wood and framed MacroForge (visual polish)
- **MacroForge:** add the same Blizzard `UI-DialogBox-Border` frame as Discoveries around the entire movable wizard, with a thin bronze-outline fallback for clients without BackdropTemplate. Keep its native map/wood artwork and two-column layout.
- Replace the flat blue-gray section fill with warm charcoal, a restrained bronze rim, a one-pixel beveled highlight and a subtle drop shadow. Make the selected spell, native buttons, warning area and macro preview read clearly without changing their controls or placement.
- **Discoveries:** retain the existing map-textured wood and neutral gray-blue item rows, but adjust the wood tint warmer and slightly clearer to visually harmonize with MacroForge. Preserve map docking, item tooltips, coordinate history and other discovery behavior.
- All visual changes only; no SavedVariables migrations, macro generation changes, protected UI actions, network access or drop-tracking changes. Updated UI regression tests cover native/fallback outer frames, wood palette and inset depth.

## 2.2.8 — Discoveries loot locations and native background fixes (test release)
- **Discoveries:** remember up to six recent, spatially distinct outdoor player positions where each item was observed in a loot window, rounded to 0.1% map coordinates. Nearby repeats merge and count observations. When a loot source can be identified unambiguously, store its own independent item locations; mixed-source windows remain zone-only. Show the three newest spots and zone name in the item's Discoveries hover tooltip.
- **Honest location semantics:** these are the player's position at loot-window opening, not a guaranteed corpse death point. Dungeons, unavailable/invalid map coordinates and historical pre-feature data remain without coordinates. No invented locations, automatic map markers, extra map manipulation or official drop-rate claims. Keep existing v2 SavedVariables and old loot counts intact.
- **Native AddOns settings:** remove the nearly opaque ChalkBox rectangle created in 2.2.6; Blizzard owns the original transparent settings canvas.
- **Discoveries + MacroForge:** restore visibly textured native World Map parchment by reducing oversized dark glazes, verify atlas existence when the native query is available and retry a late-loaded atlas on reopening. Retain solid themed fallbacks when art is missing.
- Lua 5.1 tests cover location precision, dedup, source isolation, bounded retention, dungeons, missing APIs, visible map texture, retry behavior and the native settings surface.

## 2.2.7 — MacroForge UI and Bar edit flow (test release)
- **MacroForge:** match Discoveries' native parchment/map atlas with a readable dark glaze and solid fallback; add consistent inset frames around the existing workbench sections and retain the original two-column arrangement.
- Replace the single-line-looking Macro Preview with a clipped multiline scroll area that keeps long macro text inside its frame; preserve select/copy and intentional installation. Give warnings under Saved Builds a bounded wrapped area and separate Macro Name below.
- Highlight the currently selected spell assignment and preserve original button/spellbook functions.
- **The Bar:** restore an empty-space context menu during Edit Mode, so Done editing is reachable without settings. Individual stats still right-click to cycle text alignment.
- **AddOn Compartment:** optional, default-OFF MacroForge launcher beside ChalkBox, guarded by the native API. Disable aft…7069 tokens truncated…tion correctness:** when following the map, an unrecorded zone no longer displays an unrelated zone's loot; unrelated dungeons aren't falsely linked to the viewed map.
- **Updates settings:** read installed version from the TOC, provide a selectable, accurate GitHub Releases URL and `/chalk update` status. Optional party/raid peer version comparison (OFF by default, throttled) can flag newer versions observed on other players, but never pretends to request GitHub directly.
- Preserve all existing saved loot and settings. Add regressions for menus, search, sorting, button position, map laziness and version notifications.


## 2.0.0 — The Quiet Adventure Companion (prerelease)

- **Fix Forever's Map Discoveries entry point:** late WorldMapFrame load now gets a retry until it can attach; button anchors against the visible top-left map canvas and raises above its overlay. Refresh when map opens or changes. Remove fragile reliance on the optional WORLD_MAP_UPDATE event.
- **Always-available fallback:** `/chalk drops map` opens the loot browser directly; new `/chalk drops map status` reports map frame, button, anchor and visibility for real-client troubleshooting.
- **2.0 presentation pass:** coherent README, banner/feature artwork usage, current install directions, all shipped module descriptions, honest limitations, refreshed CurseForge copy, launch checklist, screenshots plan and early-access release notes.
- **Feature set prepared for testing:** automatic all-item DropSense, outdoor/dungeon map browser, loot item protection and professions, MacroForge, configurable The Bar with repair learning and vendor bag value, Session Journal, camp reminders, quest watches, native and compact combat-meter print, shared themes, Emota, QuietGuard and bag positioning.
- **No breaking changes:** same one-addon ZIP layout, existing saves and module settings. Real-client verification still required before claiming a polished public 2.0 release.


All notable changes to the public ChalkBox addon are documented here.

## 1.12.0 — MacroForge

- Add **MacroForge** under native ChalkBox settings and `/chalk macro`, with a dedicated, movable spellbook-driven macro builder (lazy loaded).
- Use modern Forever `C_SpellBook` + `C_Spell` to read learned, active, non-passive spells and icons. Handle old global-API fallback gracefully. Invalidate scan on spellbook/talent change.
- Five templates: Engage Target, Burst + Trinkets, Modifier Keys, Manual Sequence and Mouseover Utility. Localized learned spell choices; class-aware suggested defaults, including Hunter abilities and companion commands.
- Generate explicit vanilla-style macros with trinket slot attempts, conditional modifiers, pet commands and manual sequences. No cooldown/proc autopilot or GCD bypass.
- Validate known spells and **255-byte conservative limit**, explain trinket/sequence/targeting limitations, and reject invalid builds.
- Save/load up to 16 character-specific *recipes*; respec invalidates stale spell selections instead of blindly reusing old text.
- Select generated text to **Ctrl+C**, then paste into WoW's `/macro`. Optional native **Install New** on a user click, out of combat, checks duplicate names and never overwrites existing macros.
- Add isolated Lua 5.1 tests for spellbook API/filtered talents, macro templates, slot warnings, modifiers, save/load, respec, byte limit, safe native install and lazy UI.
- Single ChalkBox install, no new runtime dependencies. GitHub prerelease for in-client MacroForge acceptance testing before wider CurseForge promotion.

## 1.11.0 — Automatic Map Discoveries

- Replace manual 32-item DropSense watchlist as the primary data collector: **automatically journal every item in readable loot windows** when enabled. Fresh installs record automatically; existing explicit off preferences remain respected.
- Persist bounded per-character item totals, outdoor zone associations, dungeon-specific discoveries, and known creature-source observations. Preserve prior 1.10.0 sampled counts as unsited legacy evidence, never retroactively guessed locations.
- Report **source-specific loot-window appearance percentages only** when the window is attributable to a single identifiable creature. Mixed-source loot, unrelated creatures, unclear windows and non-creature sources have counts but no invented source odds. Never imply kill-level or official server rates.
- Add optional **Discoveries** button to Blizzard's existing world map; open a movable journal following the selected map. Outdoor/Dungeon tabs, per-creature filters, pagination and instances associated by observed entry/exit; leave the native quest map untouched.
- Native DropSense settings now have three independent switches (automatic recording, loot-window tooltip, map button) and retain the independent-attempt chance calculator.
- Session Journal records known loot regions alongside XP, gold, quests, camping and repair observations; saves last 20 sessions.
- Enforce limits on saved unique items, mapped areas, creature types and per-zone items; flag capacity reached instead of silently asserting complete coverage.
- Extend Lua 5.1 tests for source separation, dungeon linkage, mixed loot, migration and native map integration.

## 1.10.0 — The Adventure Companion

- Add global ChalkBox appearance controls: charcoal/midnight/slate/custom RGB, accent color and background-only opacity multiplier for the Bar, toast, meter and session window.
- Redesign Adventure Prep notifications as concise, compact, legible branded alerts. Fix missing Camp Benefits decision branch and actual-kit-aware supply checks; suppress unchanged prompts by default, with optional repeat interval.
- Add **DropSense**, a separately opt-in, per-character loot-window observation journal for up to 32 watched item IDs/links. Show sample size, observed frequency and Wilson uncertainty in native loot item tooltips only. Add the independent-attempt drop calculator and clearly labeled player reference rate; never invent official Forever drop chances.
- Add a persistent, separately openable **Session Journal** covering current and last 20 adventures: session XP/levels, net gold, quest turn-ins, opted-in loot observations, camp prompts, verified repair quotes.
- Add independent LootSense filters for verified crafting uses, possible uses, and camp ingredient hints while retaining quest/personal keep protection.
- Keep old SavedVariables, optional module behavior, native controls and single installable ZIP.
- Expand Lua 5.1 tests and release docs. In-client layout and API testing still recommended.

## 1.9.3 — Repair Learning

- Upgrade The Bar's repair estimate from a last-merchant single-rate reference to a **persistent per-character learning model** using up to 32 unique actual repair quotes.
- Distinguish real vendor quotes from **~ estimated** travel costs. Prefer exact equipment fingerprints when available, fall back to similar durability pools only, and robustly filter divergent samples.
- Track the last confirmed prediction difference when the next distinct vendor quote arrives; show history size, estimate source and confidence in the repair tooltip.
- Migrate existing 1.9.2 `repairReference` into an initial fallback rather than destroying previous calibration, until new quotes are learned.
- Add `/chalk bar repair status` and `/chalk bar repair reset` to inspect or clear the local character model.
- Avoid duplicate training data from polling, skip invalid/unknown or secret values, cap persistent storage and never repair automatically.
- Add dedicated Lua regression coverage for learning, deduplication, similar vs mismatched gear, bounded persistence, legacy fallback, reset and the live stat integration.

## 1.9.2 — The Bar: repair pricing and contextual controls

- Rename the user-facing **TrailBar** settings to **The Bar**, while preserving the existing `/chalk bar` commands and saved layout keys.
- Add a **Repair** module to The Bar, enabled by default and safely hidden on narrow displays when it cannot fit.
- At repair merchants, use `GetRepairAllCost` for an **exact** repair-all price. Away from vendors, show **~** estimates only after a valid character-specific observed quote; before calibration show **Repair --**, never an invented formula.
- Invalidate estimates when the equipped total durability pool has changed substantially. Clearly explain that the merchant quote includes repairs for items in bags while estimates use currently equipped wear, and that discounts can change costs.
- Add right-click native Blizzard menu controls on every module and empty Bar background: show/hide modules, move left/center/right, choose alignment, edit/reset layout, top/bottom/hide, and jump to native settings. Keep the EasyMenu fallback and in-combat safety guards.
- Retain left-click Junk/Total for Bag Value and Edit Mode's original right-click alignment shortcut.
- Expand Lua 5.1 tests for vendor-only exact quotes, sample calibration, cache invalidation, menu actions and saved layouts.

## 1.9.1 — TrailBar Vendor Value

- Add an optional **Bag vendor value** TrailBar module with two one-click modes: **Junk** (poor/gray quality only) and **Total** (all equipped-bag contents).
- Compute each stack at its actual vendor sell price in copper. Ignore bank/worn gear and never automate selling.
- Left-click the module outside Edit Mode to flip modes, use the native **Value: Junk / Value: Total** settings button, or `/chalk bar bagvalue junk|total|toggle`. The selected view persists.
- Hover for both precise resale totals. Uncached/secret item data are explicitly flagged as unresolved; `>=` indicates a verified lower bound, never a fake exact value.
- Keep the original 18px bar and responsive layout, with no changed stat visibility on existing users until the new module is enabled. Expand saved per-character layout validation for the new stat.
- Add Lua 5.1 coverage for stacked vendor pricing, gray-only filtering, uncached item information, opt-in behavior, switching and native controls.

## 1.9.0 — The Polish Update

- Add drag/drop TrailBar Edit Mode: move/reorder every module between left/center/right sections, right-click text alignment, **per-character saved layout**, reset and in-combat safety; preserves the existing responsive 18px layout.
- Replace the bluish TrailBar panel with Blizzard-like charcoal and add **0–100% background-only opacity** slider, retaining crisp labels and the XP underline.
- Reorganize the native ChalkBox settings landing page with dedicated **TrailBar Appearance**, **LootSense Appearance** and **Emota Race Behavior** pages, preserving all original controls.
- Restyle LootSense advice as a separated native **CHALKBOX | ITEM INSIGHT** tooltip section rather than `LootSense: ...`, retaining all real learned vs potential classifications.
- Add subtle customizable emerald **known-recipe reagent outlines** to supported Blizzard bag item buttons; strictly requires actually scanned learned recipes, never offline catalog speculation, and never replaces inventory clicks/rarity.
- Add Emota race chooser with implemented/placeholder distinctions and per-race **Off / Subtle / Default / Expressive** weighting. Existing default personality is unchanged.
- Replace the separate-bag position slider with a **vertical signed -120..+120** control: stock Blizzard position centered, upward negative and downward positive, with reset button and slash support.
- Test native bag hooks, recipe highlights, per-character layout/drag/align, appearance alpha, race flavor states, signed bag offsets, intact legacy features and deterministic ZIP contents.
- Update GitHub readme, user guide and CurseForge listing draft; continue direct GitHub Release distribution.

## 1.8.6 — Adaptive rich-stat TrailBar

- **Actually implemented** new TrailBar readings: equipped bag free/total slots (ordinary vs specialized in tooltip), weighted equipment durability and lowest-condition warning, rested bonus XP as % of one level, optional home/world latency and optional Hunter pet health.
- Guard all readings against missing Forever APIs, protected/secret combat values and invalid data. Never infer pet health or count unavailable items as free.
- Add **TrailBar Stats** to native ChalkBox options, with nine switches and working Balanced, Minimal and All presets. Defaults feature bags, gear and rested XP; latency starts off.
- Rebuild the 18px widget layout to fit left/center/right groups without overlap and hide lower-priority fields on narrow displays without changing saved choices.
- Add `/chalk bar stat <module> on|off`, `/chalk bar stats <preset>` and `/chalk bar stats` diagnostics.
- Retain the existing XP progress line, money, session time, UIParent screen-space reservation, separate-bag offset, DPS features and all other ChalkBox modules.
- Extend Lua 5.1 regression tests for native readings, specialty bag counts, weighted durability, rested XP, secret Hunter health, native settings, profiles and adaptive layout.
- Refresh GitHub README, user guide and CurseForge listing draft for the real release.

## 1.8.5 — Blizzard damage-meter PRINT integration

- Add **ChalkBox: PRINT top 3 to PARTY** to the gear/settings menu of Blizzard Forever's built-in damage meter, using its supported `MENU_DAMAGE_METER_WINDOW_SETTINGS` extension point.
- Report the selected **native window's** damage/DPS/healing/interrupt statistics and selected current, overall, or saved fight; fall back to the last fight if the current session is empty and the client supports that lookup.
- Keep privacy and combat safeguards: manually initiated, never in combat or Edit Mode, never solo or in a raid, no handling secret combat values, no chat redirection and a three-second repeat guard.
- Add `/chalk meter native on|off|status` to enable or disable the built-in gear-menu entry (enabled by default).
- Keep ChalkBox's separate meter unchanged and optional: `/chalk meter hide` lets you use only the Blizzard meter while retaining the native-print integration.
- Add Lua 5.1 coverage for native gear-menu extension, currently selected stat/session, historical fights, protected data, and chat restrictions.
- Preserve LootSense, the separate-bag slider, Action Bar behavior and all other ChalkBox features.

## 1.8.4 — Separate-bag position control

- Add a default-off **0–80-point vertical offset** for Blizzard's individual bag windows (including profession bags), with a 30-point starting suggestion for bags clipping off the top.
- Show an adjustable slider under native **ChalkBox → TrailBar** settings, plus `/chalk bags offset 30`, `/chalk bags reset`, and `/chalk bags status`.
- Securely post-hook Blizzard's `UpdateContainerFrameAnchors()` so the whole open bag stack moves together, without replacing item slots, inventory or sorting.
- Respect the original combined-bags position, never shift in combat, and reapply after combat rather than causing protected-frame errors.
- Regression tests cover no stacking on repeated layout, saved slider behavior, slash commands, combat deferral and stock reset.
- Preserve TrailBar's existing 18px display, DPS meter, QuestSense, LootSense and all other features.

## 1.8.3 — LootSense First Aid material accuracy

- Prevent broad Cloth item-subclass guesses from being labeled as First Aid materials; First Aid now needs recipe evidence.
- Validate saved First Aid ingredient and learned-recipe claims against the bundled Forever First Aid recipe data, filtering stale or mismatched profession scan records.
- Preserve Leatherworking recipes using Small Lustrous Pearl and correctly recognize actual First Aid ingredients such as Linen Cloth.
- Add a targeted Lua 5.1 regression test for mismatched saved pearl data and valid Leatherworking and First Aid cases.
- All DPS meter, party PRINT, RESET, custom layout, QuestSense, camping and other ChalkBox features remain unchanged.

## 1.8.2 — One-line party DPS report and on-window reset

- PRINT sends a **single, manual top-three summary to PARTY chat** after combat, for the meter's selected statistic and fight scope; fallback to last fight when current is empty.
- Uses Forever's modern `C_ChatInfo.SendChatMessage` API (legacy fallback for Classic), respects protected combat values, refuses solo/raid misdelivery, avoids duplicate clicks and respects 255-character chat limit.
- Adds an on-window **RESET** button between PRINT and LOCK; calls the existing confirmation before clearing shared Blizzard meter data, never during combat.
- Keeps the compact class-icon header, opacity, lock/resize, QuestSense and the one-ZIP distribution.
- Expanded Lua 5.1 tests cover chat restrictions and actual group targeting without leaking protected data.

## 1.8.1 — Native class and specialization icons for the DPS meter

- Show compact genuine WoW **class emblems** beside combatant names, default on, using Blizzard's class sheet and `C_DamageMeter.classFilename`.
- Offer **Class / Spec / Off** choices from the native Combat Meter options and `/chalk meter icons class|spec|off`.
- Spec mode uses Blizzard's `specIconID` fileID when supplied, with an accurate class fallback. Unknown/pet sources use a neutral question mark instead of inventing a player class.
- Icons fit inside the existing compact resizable rows; hiding them restores name width. Empty rows clear their icon to prevent stale player identification.
- Protected player names and combat numbers remain untouched. Zero external files/dependencies, still one ZIP with all other modules preserved.
- Extend mock tests for atlas coordinates, native fileID handling, unknown sources, icon toggles, row cleanup and settings integration.

## 1.8.0 — Forever QuestSense rebuilt, movable top toast, cleaner DPS meter

- Replaced zone-POI-dependent QuestSense with a **C_QuestLog accepted-quest** watch manager that works even when Forever map pins aren't available.
- Smart (default), Nearby only and All accepted tracking modes, with optional 5/10/15/20 auto-watch limits.
- Respects manual watches/untracking, protects state while world map/quest log/combat is open, retries after unsafe periods, and surfaces useful diagnostics.
- Moved Adventure Prep toast to screen top by default; new Toast Appearance native page provides position lock, 35–100% opacity, 25-second move preview and Reset to Top. Locked notices remain click-through.
- Removed the DPS meter X button while preserving show/hide through settings and slash commands.
- Added regression coverage for absent map APIs, map/combat deferrals, muted manual watches, GUI toast drag/alpha settings, and no-X meter control.
- Kept the single ZIP and 2,511 bundled MIT Forever recipes.

## 1.7.1 — Boosted Rest Camp Tent detection and personalized DPS meter

- Detect Camp Tent's **Boosted Rest (1229451) harmful debuff** and sufficient Rested XP independently of ordinary Camp Benefits; suppress false reminders and show separate status.
- Add a one-hour, session-only **Tent Used** acknowledgment in Adventure Prep when aura detection isn't available.
- Remove the DPS meter's CHALKBOX header logo and unnecessary bottom explanation.
- Add direct on-window **LOCK/UNLOCK**, **PRINT**, opacity slider, and bottom-right drag-to-resize grip with saved width/row count.
- Print native fight numbers only to local chat **after combat**, refusing protected results instead of leaking or inventing data.
- Add opacity slider in native settings and `/chalk meter opacity N` commands; keep all other addon modules unchanged.
- Add new tests for harmful-aura detection, rested-XP thresholds, protected fight printing and drag/opacity/lock behavior.

## 1.7.0 — Built-in native DPS and combat meter

- Added a compact, class-colored, draggable ChalkBox combat meter with an obvious marker for your own character.
- Modes: DPS, Damage Done, HPS, Healing Done, Damage Taken and Interrupts. Sessions: Current Fight, Last Fight and Overall.
- Added show/hide, lock, 5/8/12 rows, 85/100/115% scaling, position reset and deliberate reset confirmation in native AddOns settings.
- Uses Blizzard's native `C_DamageMeter` API and event-driven updates. Secret values are passed directly to protected-safe text/status bar UI setters, never processed in Lua.
- Preserved working LootSense with 2,511 bundled Forever recipes, CampSense, TrailBar, QuestSense, QuietGuard and Emota.
- New Lua 5.1 tests cover native combat API, protected values, modes, visibility and resetting; one ChalkBox ZIP still ships.

## 1.6.1 — Forever profession scan and tooltip fixes

- Let `C_TradeSkillUI` establish an active owned profession when legacy profession APIs are unavailable, instead of blocking recipe scans.
- Listen to `TRADE_SKILL_LIST_UPDATE` and `TRADE_SKILL_DATA_SOURCE_CHANGED`, plus a short delayed scan, so recipes loading after the panel opens are captured.
- Fall back to alternate reagent APIs when a modern recipe schematic is missing or empty.
- Continue LootSense tooltip advice when `GetItemInfo` has not cached an item yet.
- Add actionable `/chalk loot status` diagnostics for enabled state, active profession, scanner backend, and learned-recipe count.
- Preserve one-ZIP bundle, exact MIT notices, and all other gameplay modules.

## 1.6.0 — Complete offline Forever recipes in one download

- **Bundled the MIT-licensed LibProfessionDB 1.9.1 Forever-only database** (2,511 recipes), with original Pimptasty copyright/license and the public-domain LibStub loader.
- Replaced the optional external database install with a truly self-contained ChalkBox ZIP.
- Fixed recipe matching against static entries lacking localized recipe names. Names resolve from the client spell API first, then crafted-item names, with an honest ID fallback.
- Made offline recipe indexing deterministic, improved tooltip advice when you already have enough materials, and retained the distinction between **known recipe** and **potential use**.
- Added an integration test loading all 2,511 real bundled recipes and archive/license checks.
- Original standalone addons are still excluded; CampSense, TrailBar, QuietGuard, Emota and QuestSense unchanged.

## 1.5.1 — Public launch

- Established **detok/ChalkBox** as the one-and-only public home for the combined addon.
- Reorganized into a clean installable `ChalkBox/` folder, with a matching **single ZIP release**.
- Kept the original addon icon and all ChalkBox feature modules and Lua regression tests.
- Added open-source licensing, installation and user documentation, issue templates, and CI.
- Removed the old multi-addon collection build, standalone-source packages and standalone regression targets.
- No gameplay feature rewrite; the module baseline is v1.5.0. Optional third-party database compatibility remains a prerelease feature.

## 1.5.0 — Recipe-aware LootSense

- Tracked names and available reagent quantities from **learned** character recipes.
- Prioritized known-recipe evidence over broad profession-family hints.
- Added optional separately installed LibProfessionDB adapter for *potential* recipe uses.
- Added Shift-expanded known recipe detail and `/chalk loot status` diagnostics.

## 1.4.0 — Buff-aware camping

- Added Camp Benefits / Welcoming Campfire aura checks.
- Added a compact, timed center-screen toast and test button.
- Recognized additional Forever campsite ingredients, including Light Leather.

## 1.3.0 — More adventuring awareness

- Added QuietGuard social-invite controls and CampSense checklist.
- Added race/class context and resting-area behavior to Emota.

## 1.2.0 — Emota idle personality

- Randomized intermittent idle emotes, no-repeat rotation, and safe temporary poses.

## 1.1.1 — TrailBar layout

- Reserved screen space for TrailBar instead of placing it over gameplay UI.

> Earlier development happened in a private collection repository. The public repository contains **only ChalkBox**; it deliberately does not publish the historical standalone addons.
