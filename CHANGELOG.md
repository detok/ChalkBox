# Changelog

## 2.2.0 — Discoveries becomes a World Map extension (test release)
- Dock Discoveries to the World Map as a compact 488px side panel instead of an independent draggable 660px popup. Prefer the available right side, then left, with an in-map edge fallback when the map fills the screen. Never alter Blizzard's own map position, size, zoom or textures.
- Parent Discoveries to the existing WorldMapFrame and close it when the map closes. Refuse opening the browser while the World Map is hidden. Preserve the map button and its saved independent position.
- Fix the Creature Source selector by replacing Forever's transient context menu and broken cycling fallback with a real, clickable, paged and mouse-wheel-capable list. Sort uses the same reliable control; Area retains its working direct picker.
- Simplify the layout so Area and Creature are together, Sort and Search are together, and the table/footnotes are more compact. Show a clear message when an area lacks identified creature-source data.
- Preserve DropSense item counts, personal observed loot rates, area/dungeon browsing, map sync, user settings, AuctionSense price links and the rest of ChalkBox. No loot-event, item-use, combat, SavedVariables-schema or data-collection changes.
- Extend UI regressions for map-owned lifecycle, side docking and maximized-map fallback, direct source selection, source statistics and normal map button behavior.


## 2.1.9 — Market belongs inside Blizzard's Auction House (test release)
- Replace the nearly opaque AuctionSense overlay with Blizzard's **auctionhouse-background-index** artwork and native inset border, matching the built-in Browse results.
- Switch Market using the existing Auction House `SetDisplayMode` lifecycle. Blizzard's Browse, Search, Sell and Auctions page frames hide while the Market tab is selected and restore normally when switching back. Do not edit the global display-mode list or native tab registry.
- Spread low/average/listings columns across the full native inset width; align search to the right and pager controls to opposite footer edges.
- Retain dynamic 1–7 result rows, browse/full-scan API calls, market snapshot distinctions, pricing colors, saved data and protected-combat restrictions.
- Extend regression coverage for Blizzard artwork, content switching, native Buy/Sell/Auctions controls, responsive pagination and existing tooltips.


## 2.1.8 — Restore adjustable separate-bag position (test release)
- Restore the previously working Blizzard separate-bag vertical offset. The 2.1.5 combat hotfix disabled this functionality without proving it was the source of a blocked-action error.
- Restore the saved bag offset, including negative/upward values on login. Recalculate from Blizzard's current native anchor on each layout update so offsets never accumulate.
- Restore a properly working horizontal slider under The Bar settings: **left raises bags**, **right lowers bags**, 0 returns to Blizzard default. Clean labels and live value; Reset Bags is functional again.
- Continue deferring bag updates during combat or while the bank is open; only adjust the native first player-bag column when the expected Blizzard anchor is available. Never modify individual item buttons or call item-use APIs.
- Preserve full-width Bar behind portrait effects, safe top-UI shift, auction UI/scanners, Emota combat guard, native DPS reports, and SavedVariables.
- Expand bag layout and settings regressions (positive/negative offsets, combat deferral, no stacking, bank handling, saved-position recovery and UI control).


## 2.1.7 — Bar layering and honest bag controls (test release)
- Keep the original full-width 18px Bar and 2.1.6 safe top-UI spacing, but render the Bar at BACKGROUND strata, level 1. Blizzard portraits, resting ZZZs, buffs and native HUD art can draw over the strip.
- Remove the disabled, nonfunctional bag-offset slider and its overlapping scale labels from The Bar settings. Replace it with clear native-bag layout status; no pretend controls or irrelevant reset button.
- Clarify that Blizzard's separate bag windows stack upward when several bags are opened. ChalkBox's protected container offset remains suspended to avoid blocked item-use actions.
- Preserve all existing saved data, AuctionSense browsing, native DPS reports, Emota combat restrictions, top-UI layout, and bag-button protections.
- Add regressions for Bar frame strata and the absence of any bag slider on The Bar settings page.


## 2.1.6 — Auction and Bar layout repair (test release)
- AuctionSense: dynamically show 1–7 rows per page based on actual native Auction House height; anchor search/paging controls and disclaimer within the body above Blizzard's footer.
- Rename the fourth Auction House tab to the shorter **Market** so the native tab strip fits cleanly. The panel still identifies itself as AuctionSense.
- The Bar: restore the original full-width 18px strip. A shared top-UI layout manager offsets only unprotected, default-anchored Blizzard frames by 18px, with exact restoration and combat deferral. Never mutate `UIParent`.
- Regression tests for AH height-sensitive pagination, native tab/footer behavior, full-width Bar, protected top-frame safety, 18px reversibility and combat deferral.
- Preserve the 2.1.5 combat-protection changes (no protected bag item button mutations, no combat emotes), working auction scanners, saved data and Blizzard-native damage report features.


## 2.1.5 — Combat safety: protect Blizzard's UI and item actions (urgent hotfix)
- Eliminate the UIParent screen-inset system. The Bar now anchors only its own non-protected overlay and never repositions or resizes Blizzard's root UI. Old saved `barReserve` settings migrate to safe overlay.
- Block Emota native-emote attempts (automatic or manual) during combat, including reaction events. Sit/sleep/stand poses are manual previews only; no idle automation can interrupt food/drink.
- Suspend the unsafe separate-bag offset hook and stock container reanchoring. Preserve previous saved bag offset for a future secure alternative; the slider is temporarily disabled. Do not modify Blizzard bag/item buttons or their parent frames.
- Suspend green reagent outlines that previously wrote textures and marker fields onto Blizzard item buttons. Item Insight recipe detection remains active, with preferences preserved.
- Keep XP, gold, gear, auction scanning, loot insights, Blizzard-native DPS reports and saved data enabled.
- Add regression traps preventing any Bar UIParent write, any bag-frame hook/move and any Emota combat dispatch.


## 2.1.4 — Clear, consistent in-game tooltips (test release)
- Make the existing item insight status the only header; compact the learned-recipe, possible-use, camp tool and bonus-XP explanations into one useful evidence line.
- Unify add-on tooltip colors: green useful/known values, gold costs/values, blue counts, amber cautions and red urgent warnings. Leave Blizzard quality colors alone.
- Shorten AuctionSense item summaries, identify per-unit prices and market source, and remove its repeated module banner.
- Tighten Drop Journal annotations and Discoveries map hints; keep personal loot sampling distinct from official drop odds.
- Make Bar hover numbers more readable through semantic colors without changing stat calculations, layout or number of rows.
- Shorten camp tool notes and reminder toasts; make warnings visibly amber. Remove internal-brand preview captions and redundant MacroForge window branding.
- Keep shop quest warnings unmistakable with short BUY FOR QUEST / DO NOT SELL labels.
- Preserve the 2.1.3 Blizzard-native combat print options, auction scans, SavedVariables and other modules. Extend regression coverage.


## 2.1.3 — Native meter report controls and clean item tooltips (test release)
- Expand Blizzard's original damage meter gear menu with direct **Print to PARTY**, **Print to SAY**, and **Top 3/5/10** rank controls, always using the selected native meter stat and session.
- Add opt-in reports after combat, with configurable PARTY/SAY channel, DPS/damage/healing stat, minimum combat length (0/10/20/30s), and cooldown (30/60/120s). Auto reporting defaults OFF; failed/secret/incomplete combat data is never sent.
- Keep native WoW combat data as the source of truth, cap chat to one message, and avoid duplicate automatic reports.
- Remove the redundant **CHALKBOX | ITEM INSIGHT** line from item tooltips; present only the useful classification and evidence. Shorten the **Drop Journal** tooltip heading without a repeated addon brand.
- Preserve existing scanning, combat display and saved settings. Extend native meter and item tooltip regressions.


## 2.1.2 — AuctionSense quick-read tooltips (test release)
- Use consistent green low ask, amber average ask, blue listing counts and red/amber warnings.
- Present price facts on separate short lines, with clear missing values instead of invented browse statistics.
- Add native row-hover price summaries, market/source/scan age and compact scan button hints.
- Shorten panel status and freshness warnings; retain the working AH tab and both scanners.
- Expand regression tests for hover behavior and tooltip color hierarchy.


## 2.1.1 — AuctionSense native AH tab and scan repair (test release)
- Move AuctionSense into Blizzard's actual Auction House as a tab; no floating window or hidden settings-only interface.
- Read all-market browse results through the current Forever browse API, including incremental pages and server throttle readiness. Show lowest asking prices and total units; leave unsupported averages and listing counts blank.
- Separate full replicate requests behind **Full listings (15m)**; fix synchronous event race by registering the job before requesting.
- Detect missing browse responses within 12 seconds, handle browse failures, bound page reads and preserve the previous complete snapshot.
- Keep tooltip integration, realm/faction prices, saved loot data and other ChalkBox modules intact.
- Test AH tab switching without protected PanelTemplates manipulation, browse pagination, real versus unavailable price fields, failed requests and full-scan events.


## 2.1.0 — AuctionSense foundation (test release)
- New original, read-only AuctionSense module with native AddOns settings and a searchable market browser.
- Explicit user-initiated WoW Forever full-market scans. Scan in frame-budgeted batches with a conservative 15-minute cooldown, no automated retries or transactions.
- Save complete snapshots atomically per realm/faction; preserve prior data if the AH closes, metadata is incomplete, or the client rejects the request.
- Display lowest per-item buyout, quantity-weighted average ask, listings, units and scan age. Flag mixed equipment variants and old scans; never claim recorded prices are completed sales.
- Keep bounded price history and item storage. Provide shared `ChalkBox_AuctionPrice`, `ChalkBox_AuctionValue` and `ChalkBox_AuctionRows` accessors for LootSense, DropSense and future ProfessionSense uses.
- Optionally show the saved asking prices on item tooltips and pass current, non-ambiguous market-value metadata to DropSense.
- Add Lua regression tests for actual AH scan events, item stack math, error recovery, market isolation, saved history, tooltip behavior, and search UI.


## 2.0.12 — Clickable Discoveries picker and new addon icon (prerelease)
- Move the Area / Dungeon popup above the entire Discoveries journal into an independent top-level overlay; keep it aligned with the original dropdown and hide it when the journal closes.
- Prevent the zone list from being visible but blocked by other controls or the world map.
- Render the newer ChalkBox project logo into a 64×64, 32-bit, game-compatible TGA during reproducible addon packaging; retain the same IconTexture path in both WoW flavor manifests.
- Test the popup's parent, strata, anchor, behavior on close, and included icon encoding.
- Preserve all map sync, area browsing, DropSense history, filters and existing fixes.


## 2.0.11 — Direct zone browser and clearer drop stats (prerelease)
- Replace nested Area / Dungeon menus with a visible, scrollable and paged list of every recorded zone and dungeon.
- Browse locations independently of the world map or choose Follow world map; retain existing UI, saved preferences, search and filters.
- Clean up Discoveries and DropSense wording: Found, Drops, Rate and specific mob drops / tracked loots.
- Never pool unrelated mobs into one drop percentage or claim looted corpses are all kills.
- Add regression checks for actual dropdown controls, paging and source-specific drop statistics.


## 2.0.10 — First-bank-open safety (prerelease)
- Stop BagReagents from scanning or creating overlays for character-bank, reagent-bank, and other non-inventory item buttons.
- Defer bag highlighting and native bag layout hook setup while a bank is open, including the first time Blizzard lazily initializes its bank frame.
- Do not reposition Blizzard's container frames on BANKFRAME_OPENED; restore configured player-bag positioning safely after closing the bank.
- Add regressions for new-character first bank open, bank frames in container enumeration, bank close, and resuming regular bag behavior.
- Preserve the native bank, all SavedVariables, UI preferences, and prior Discoveries/QuestSense fixes.


## 2.0.9 — Discoveries location browser (prerelease)
- Extend the existing Area / Dungeon dropdown with a Follow world map choice and grouped Outdoor zones / Dungeons menus covering all places in the player's observed-loot history.
- Alphabetize locations with item counts; selecting a zone or dungeon switches tabs automatically and does not move the native world map.
- Make the existing map-sync control a visible on/off toggle, with map following selectable directly from the area dropdown.
- Save map-sync preference and last manually browsed location per character, and restore manual selection when map sync is turned off.
- Support nested controls on both modern MenuUtil and legacy EasyMenu clients; preserve source/search/sort filters, journal layout, map button location and current loot history.
- Expand Lua regression coverage for map-independent browsing, cross-category selection, map sync, persistence, and old-client menus.


## 2.0.8 — QuestSense Nearby auto-sync (prerelease)
- Keep Nearby only restricted to quests confirmed by the current area's quest map or quest-log zone heading; newly accepted distant quests and unscoped POI hints no longer bypass the filter.
- Temporarily hide nonlocal manually selected quest watches instead of permanently discarding them; restore their manual selection when relevant again, when another tracking mode is selected, or when auto-tracking is disabled.
- Reconcile Nearby every 12 seconds, in addition to debounced event updates, to recover from missed changes without manual Refresh.
- Preserve watch limits and native manual decisions; never edit during combat, map/quest-log display, or dungeon instances, or when locality cannot be verified.
- Show the active tracking mode and temporarily hidden count in settings; expand Lua regression tests.


## 2.0.7 — Compact Bar hover tooltips (prerelease)
- Replace lengthy stat hover explanations with 1–2 essential detail lines.
- Keep live values and data distinctions for XP, bags, vendor value, repairs, gear, ETA, rested XP, pets, session, latency and gold.
- Regression-test real hover events, color, text length and data accuracy.
- Preserve right-click menus, layout, saved data, bag performance and Discoveries.


## 2.0.6 — The Bar menu cleanup (prerelease)
- Right-click a stat for only its relevant controls: Show/Hide, Move, Align, and Bar settings, with contextual vendor-value and repair options.
- Right-click empty bar space for Modules, Position, Edit layout, Reset layout, Stat settings, and Appearance.
- Add consistent gold, cyan, green, gray, and amber text cues to modern and legacy dropdown menus; highlight the current position and alignment.
- Shorten noisy action messages and Bar settings descriptions.
- Expand regression tests for native/legacy menu structure, colors, and callbacks; preserve all saved layouts, character settings, metrics, and bag refresh improvements.


## 2.0.5 — Discoveries journal initialization and legibility (prerelease)
- Fix eight incorrectly constructed static text labels that could interrupt Discoveries window creation and leave floating buttons.
- Give all journal font strings explicit contrast and subtle shadows.
- Strengthen normal-map and lazy-loaded-map tests to reject invalid font templates, coordinates and incomplete windows.
- Keep 2.0.4 bag refresh optimizations and all saved gameplay data unchanged.


## 2.0.4 — Discoveries window and bag responsiveness (prerelease)
- Draw Discoveries above the native Map & Quest Log in a real Blizzard-style panel, preserving the journal's background and controls together.
- Coalesce rapid bag marker scans and inventory-related TrailBar refreshes; cache vendor valuation for 750ms.
- Keep all existing observations, settings, character state, layouts and module options unchanged.


## 2.0.3 — Discoveries panel visibility (prerelease)
- Keep the standalone Discoveries panel legible even with transparent global appearance settings.
- Add a visible frame edge, bring the journal forward when opened and guard theme failures.
- Regression-test transparent and failing theme callbacks while preserving all existing data and controls.


## 2.0.2 — Settings and CurseForge preparation

- Grouped native AddOns settings beneath their parent modules. The Bar now owns Modules and Appearance; LootSense owns Appearance; Adventure Prep owns Toast Appearance; Emota owns Race Behavior and Emote Catalog.
- Reorganized the ChalkBox home page into three sections. Standardized the shared panel header, divider, and return-to-ChalkBox navigation.
- The optional compact combat meter always starts closed on login. Manually showing it remains available by settings or slash command.
- Updated README and CurseForge copy for the current complete module set, including Discoveries, MacroForge, repair learning, Session Journal, QuestSense, CampSense and updates.
- Added a reproducible CurseForge media kit ZIP with six original SVGs, nine rendered PNGs and ready-to-use listing files, separate from the playable addon ZIP.
- Preserved previous saved preferences and character history. Extended automated tests to cover the menu hierarchy, startup state and publishing assets.


## 2.0.1 — Discoveries UX and honest update awareness (prerelease)

- **Discoveries browser refresh:** wider, readable item rows with icons, collectible quantities, observed loot-window counts, conservative source-specific rates, and clearer empty states. Three true dropdowns for area/dungeon, creature source and sort; searchable item names/IDs; native menu API with graceful fallback.
- **Movable Discoveries button:** drag anywhere within the world map; per-character saved position survives reopen/relog. Right-click, DropSense settings or `/chalk drops map reset` restores default. Retain the working 2.0 map loading/attach fix.
- **Location correctness:** when following the map, an unrecorded zone no longer displays an unrelated zone's loot; unrelated dungeons aren't falsely linked to the viewed map.
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
