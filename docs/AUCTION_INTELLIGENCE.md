# AuctionSense Intelligence — experimental, off by default

An optional read-only forecast and inventory-decision layer for WoW Forever. No cloud service or in-game language model is required; the engine uses explainable calculations, locally recorded professions, and market observations. It never crafts, auctions, vendors, disenchants, moves inventory, changes native Auction House mode, creates a floating window, or replaces Blizzard tracker methods.

## How to enable

Settings → AddOns → ChalkBox → AuctionSense → Intelligence (Experimental). Enable Inventory Intelligence for this character. It is OFF by default, including on upgrade. Normal AuctionSense > My Items notes, scans, mail receipts, and LootSense tooltip behavior are unchanged when disabled.

Select Skill Up or Make Gold. New suggestions appear inside the existing My Items rows and hovered bag-item tooltips.

Commands:
- /chalk intel on or off
- /chalk intel skill or gold
- /chalk intel target 10, target 25, or target 50
- /chalk intel margin 15, margin 25, or margin 50
- /chalk intel reserve ITEM_ID QUANTITY (zero clears the reserve)
- /chalk intel ignore ITEM_ID or unignore ITEM_ID
- /chalk intel learn on or learn off
- /chalk intel profession leatherworking (or another supported profession)

## What the engine knows

A learned recipe is proven only by live C_TradeSkillUI.GetRecipeInfo(recipeID) learned status from the player's profession window. The bundled LibProfessionDB can enrich that same observed recipe, but cannot declare unknown recipes learned. Exact required reagents and their quantities come from GetRecipeSchematic where possible. Unknown/alternative reagent slots, unknown crafted outputs, and variable yields are excluded from automatic craft planning rather than guessed.

The optimizer uses the player's currently accessible bag items, their quantities and vendor values, observed realm/faction auction asking prices and scan ages, opt-in name-matched verified seller-mail receipts for ordinary trade goods, and explicitly set per-item reserves and ignored-item preferences. KEEP and bound protections override economic suggestions.

## Skill Up mode

Forecasts a selected number of skill points using observed known recipes and supported difficulty thresholds. Skill cap is explicitly reported, and forecasted materials after a rank unlock are not claimed to provide immediate skill gains.

The system uses orange/yellow/green difficulty weights for selecting *provisional* economical routes (1, 0.65, 0.25 respectively). These are **heuristic cost weights**, not tested success rates or promised skill points. Missing, mixed, borrowed, or inconsistent metadata marks the plan uncertain; if no credible route exists, the engine says so. Reserves reduce auction/craft availability.

## Make Gold mode

Observed net ask = lowest recently observed asking price times (1 minus estimated auction cut). The default 5% cut is a labeled estimate; multiple verified seller invoices can inform a cut-rate estimate. Conservative additional risk buffers reduce the estimate and do not represent probabilities of selling.

All observed ingredient costs contribute to opportunity cost, including materials already owned. Missing reagent price information prevents a profit craft recommendation. Output must also have a fresh nonmixed price. Requires estimated gain at least 2,000 copper and the selected relative margin.

Compares selling as-is to direct known recipes and two-step known recipe transformations, linked by actual input/output item IDs. Allocates shared inventory conservatively: once ingredients are assigned to a proposed craft they are unavailable for other recommendations. No automatic purchases or trades.

## Inventory pressure

The bag scan also observes available slot counts when the client's container API exposes them. Suggestions still require explicit user action. Real slots freed depend on stack composition and where items go; the beta does not promise a specific number of slots freed. Gold-per-freed-slot optimization is a follow-up requiring stronger accounting and tests.

## Learning without invention

Existing verified seller-mail invoices, historic scan observations, explicit reserves/ignores, and bounded records of actual skill rank changes inform future advice. An item disappearing from bags is not proof of a sale. A change in skill rank is not proof of which recipe caused it. An expired auction cannot be inferred from mere absence, and name-only sale invoices may be ambiguous.

Settings are stored per character in ChalkBoxProfessionDB.intelligence; the engine does not create this table merely because ChalkBox loads with the toggle off. Previous AuctionSense database tables remain unchanged. Turning the toggle off reverts annotations while retaining explicit user preferences for later experiments.

## Safety and QA

ProfessionSense records live learned recipe information. AuctionIntelligence performs calculations. AuctionInsights supplies existing bag and mail evidence. AuctionSenseUI and LootSense display only optional text. No secure UI actions or new network requests. Lua 5.1 and all existing tests are part of GitHub Actions. Manual WoW Forever validation remains necessary before any stable release, especially for item variants, strange hides/pristine materials, skill caps, incomplete schematics, crafting outputs, and unexpected client taint.

The goal is a trustworthy decision aid, not a trading bot or guaranteed-profit calculator.
