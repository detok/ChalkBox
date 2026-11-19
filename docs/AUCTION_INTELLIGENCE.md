# AuctionSense Intelligence — experimental, off by default

An optional read-only forecast and inventory-decision layer for WoW Forever. No cloud service or in-game language model is required; the engine uses explainable calculations, locally recorded professions, and market observations. It never crafts, auctions, vendors, disenchants, moves inventory, changes native Auction House mode, creates a floating window, or replaces Blizzard tracker methods.

## How to enable

Settings → AddOns → ChalkBox → AuctionSense → Intelligence (Experimental). Enable Inventory Intelligence for this character. It is OFF by default, including on upgrade. Normal AuctionSense > My Items notes, scans, mail receipts, and LootSense tooltip behavior are unchanged when disabled.

Select Skill Up or Make Gold. New suggestions appear inside the existing My Items rows and hovered bag-item tooltips. The two modes share the selected profession goal; **automatically calculated Skill Up material reserves are also protected in Make Gold mode by default**. The user can explicitly disable that protection for comparison/testing. The settings page shows the goal profession and rank, plus a button to pin the last scanned profession without allowing another opened profession to change it.

Commands:
- /chalk intel on or off
- /chalk intel plan (read-only top action summary in chat; no automatic trades)
- /chalk intel skill or gold
- /chalk intel target 10, target 25, or target 50
- /chalk intel margin 15, margin 25, or margin 50
- /chalk intel reserve ITEM_ID QUANTITY (zero clears the reserve)
- /chalk intel ignore ITEM_ID or unignore ITEM_ID
- /chalk intel learn on or learn off
- /chalk intel profession leatherworking (pin a specific skill goal; other professions will not replace it)
- /chalk intel profession auto (return to automatic primary profession)
- /chalk intel protect on or off (keep your Skill Up reserves protected in Make Gold; ON by default)

## What the engine knows

A learned recipe is proven only by live C_TradeSkillUI.GetRecipeInfo(recipeID) learned status from the player's profession window. The bundled LibProfessionDB can enrich that same observed recipe, but cannot declare unknown recipes learned. Exact required reagents and their quantities come from GetRecipeSchematic where possible. Unknown/alternative reagent slots, unknown crafted outputs, and variable yields are excluded from automatic craft planning rather than guessed.

The optimizer uses the player's currently accessible bag items, their quantities and vendor values, observed realm/faction auction asking prices and scan ages, name-matched verified seller-mail receipts for ordinary trade goods when learning is enabled, and explicitly set per-item reserves and ignored-item preferences. KEEP and bound protections override economic suggestions.

**Bank stock:** Only when Intelligence is enabled, the existing BankValue scan of **visible character bank tabs** optionally passes exact item IDs and observed quantities to the planner. It saves a bounded last-seen per-character snapshot and shows its age/partial-scan state beside affected materials; bank counts are never silently credited as craftable **bag** inventory. No additional bank queries occur while disabled. Guild/account banks are excluded.

## Skill Up mode

Forecasts a selected number of skill points using observed known recipes and supported difficulty thresholds. **No AH price scan is required to build a skill material forecast**: currently held materials and known ingredient quantities are sufficient to establish a tentative reserve. Missing ingredient prices affect route cost confidence, not recipe eligibility. Skill cap is explicitly reported, and forecasted materials after a rank unlock are not claimed to provide immediate skill gains.

The bundled Forever LibProfessionDB stores difficulty as **{orange, yellow, green, gray}**, a four-number positional array. The planner reads and validates those thresholds, and also accepts equivalent named records for compatibility. It calculates a **provisional recipe route** with named recipes, suggested craft quantities, required ingredients, and reserves per item. The item tooltip explicitly shows its own relevant recipe and training block where available.

The system uses orange/yellow/green difficulty weights for selecting *provisional* economical routes (1, 0.65, 0.25 respectively). These are **heuristic cost weights**, not tested success rates or promised skill points. Missing, mixed, borrowed, or inconsistent metadata marks the plan uncertain; if no credible route exists, the engine says so. Reserves reduce auction/craft availability.

## Make Gold mode

Observed net ask = lowest recently observed asking price times (1 minus estimated auction cut). The default 5% cut is a labeled estimate; multiple verified seller invoices can inform a cut-rate estimate. Conservative additional risk buffers reduce the estimate and do not represent probabilities of selling. If there is no fresh AH quote, **at least two independently captured, recent exact-name seller invoices within the same 30-day window** can provide qualified evidence for a trade-good auction recommendation; one invoice (or one recent plus one ancient) cannot. The no-quote fallback applies a separate 30% caution haircut, and does not invent a current market quote.

All observed ingredient costs contribute to opportunity cost, including materials already owned. Missing reagent price information prevents a profit craft recommendation. Output must also have a fresh nonmixed price. Requires estimated gain at least 2,000 copper and the selected relative margin.

Compares selling as-is to direct known recipes and two-step known recipe transformations, linked by actual input/output item IDs. Allocates shared inventory conservatively: once ingredients are assigned to a proposed craft they are unavailable for other recommendations. **It now searches bounded combinations** (a limited-width, limited-depth lookahead) so competing recipes share the same stock budget and it can prefer a more valuable mix over the first/highest-margin recipe. This is **not** a mathematically proven global optimum: search and quantities are capped for game-client performance. Auction and seller-mail evidence is cached per appraisal, and unchanged inventory snapshots reuse their previous analysis to avoid doing the same work on every AH refresh. No automatic purchases or trades.

## Inventory pressure

The bag scan also observes available slot counts and the number of occupied stacks per exact item. When a proposed auction or vendor action would remove **every observed unit** of an item, the advice can show how many occupied bag slots that would *potentially* clear **if you complete the action**. The planner ranks full-group auctions ahead of other suggestions when only a few slots are free, but never assumes a partial sale clears a specific slot. Crafting outputs may consume slots; no automatic inventory moves occur. Gold-per-freed-slot as a fully optimized objective remains future work.

## Learning without invention

Existing verified seller-mail invoices, historic scan observations, explicit reserves/ignores, and bounded records of actual skill rank changes inform future advice. An item disappearing from bags is not proof of a sale. A change in skill rank is not proof of which recipe caused it. An expired auction cannot be inferred from mere absence, and name-only sale invoices may be ambiguous.

Settings are stored per character in ChalkBoxProfessionDB.intelligence; the engine does not create this table merely because ChalkBox loads with the toggle off. Previous AuctionSense database tables remain unchanged. Turning the toggle off reverts annotations while retaining explicit user preferences for later experiments.

## Safety and QA

ProfessionSense records live learned recipe information. AuctionIntelligence performs calculations. AuctionInsights supplies existing bag and mail evidence; BankValue supplies only an already-accessible open character-bank snapshot when explicitly enabled. AuctionSenseUI and LootSense display only optional text. The OFF fast path gates bag analysis, tooltip writing, bank item observations, status lookups, and auction-receipt invalidation **before any Intelligence data work**. No secure UI actions or new network requests. Lua 5.1 and all existing tests are part of GitHub Actions. Manual WoW Forever validation remains necessary before any stable release, especially for item variants, strange hides/pristine materials, skill caps, incomplete schematics, crafting outputs, and unexpected client taint.

The engine internally produces KEEP, HOLD, CRAFT, AUCTION, VENDOR, CHECK DE, or SCAN AH decisions. The UI instead uses plain English, e.g. **Keep 40**, **Auction 10 | Keep 40**, **Use 12 in crafts**, with a reason, main supporting recipe, required quantity, reserve shortfall and evidence qualifier where relevant. **"Use 12 in crafts" means twelve units of this ingredient, not twelve completed items.** Right-click on a My Items row reserves the *entire observed count of that item in your bags*, not only a stack. Shift-right-click ignores it. The tooltip can never guarantee that the auction will sell or that a green/yellow recipe yields a point.

Previously saved incorrect profession labels are pruned from Intelligence's own recipe cache only where the bundled Forever catalog proves an actual mismatch; unfamiliar Forever-only recipes are never deleted merely because they are absent from the reference database.

It no longer defaults to a vague REVIEW label when a meaningful next action is known. **SCAN AH** is specifically for cases where neither current quotes nor trustworthy personal sales justify a sale; it is not a claim to know market demand that the client has never observed.

The goal is a trustworthy decision aid, not a trading bot or guaranteed-profit calculator.
