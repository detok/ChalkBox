# Item Insights / Tooltip Coordinator — experimental sandbox

**Status:** experimental feature OFF by default inside the unified `2.2.28-quest-beta` prerelease. This does not claim that all features are verified on the live Forever client.

## Enable or undo

Open Settings → AddOns → ChalkBox → LootSense → **Item Insights
(Experimental)**. The coordinator is OFF by default **per character**.
Turn it ON to replace the independent addon item-tooltip sections with one
coordinated block. Re-hover the item after changing settings.

Alternatively, type `/chalk tooltips on` or `/chalk tooltips off`.
The page also provides **Restore Legacy Tooltips**, which returns the
original Core, LootSense, AuctionSense, Intelligence, DropSense and
DisenchantSense item-tooltip rendering path without reinstalling anything.

If this feature behaves strangely, turn it OFF; existing item notes are
restored at the next hover. The coordinator does not modify Blizzard's
item data, native colors, secure frames, inventory, auctions or combat state.

## What gets coordinated

* Core's accepted-quest vendor buying and do-not-sell facts.
* LootSense's current quest and personal KEEP protections, known/possible
  profession recipe, camp utility, curated future-quest reference and quest
  objective progress.
* AuctionSense's price and provenance only if the market-tooltip setting is
  enabled and a saved scan exists; old or variant-mixed prices carry warnings.
* Intelligence's **fresh last-computed** action and explanations if Intelligence
  itself is enabled. Cached decisions older than five minutes are intentionally
  omitted so an old bag allocation doesn't direct a sale. The hover does **not**
  trigger market scans, bag scans, full recipe planning or profit optimization.
  Open AuctionSense → My Items to prepare updated Inventory Intelligence advice.
* DisenchantSense's read-only material model if its own tooltip option is
  enabled and the item is not protected.
* DropSense's observed personal loot facts **only on native loot buttons**
  when its own tooltip option is enabled.

Accepted quests and personally protected items take precedence over any
economic action. Future-quest references are **possible later uses**, not
accepted-quest requirements or automatic bans on auctioning. They remain
protected against *destructive disenchant suggestions*, as in legacy mode.
An unavailable safety provider makes speculative economic action fail closed.

Normal hover is short: recommendation, reason and a little evidence.
**Shift + re-hover** shows extra market provenance, quest details,
bank-snapshot observations and craft assumptions. Modifier-driven live
redraw without re-hover is not promised; client behavior needs testing.

## Fault isolation and rollback

The coordinator is enabled by the user's saved per-character flag. When OFF,
LootSense and Core execute their previous rendering functions, and no
coordinator facts are read. When ON, Core can independently use its already
cached accepted-quest item facts even outside a merchant, so a missing
LootSense callback does not silently remove a critical warning. Each module's read-only provider is guarded.
A failed coordinator call restores the Core warning and the old LootSense
rendering path for that hover where possible. Repeated native callbacks
look for the coordinated marker to avoid duplicate addon lines.
Rendering doesn't repaint native Blizzard tooltip rows.

The normal data modules and their original settings remain fully independent.
This is a **presentation migration**, not a rewrite of crafting, pricing,
merchant or loot intelligence.

## In-client validation checklist (not yet performed)

1. With the coordinator OFF, hover bag quest item, learned reagent, grey junk,
   camp item, loot-window item and merchant/buyback entry. Original notes
   must be unchanged.
2. Enable the coordinator and re-hover. Each tooltip should have no more
   than one `ChalkBox | Item Insights` header; Blizzard item data remains
   intact.
3. Hover an accepted quest item and an item manually kept with `/chalk keep`.
   No auction/vendor/disenchant recommendation may override them.
4. Hover a known material, possible catalog material, and a future-quest
   reference. Only a verified recipe is labeled learned; future quest
   references remain qualified.
5. Turn Intelligence ON separately and open My Items to generate an analysis.
   Hover a material and check reserve versus surplus. Turn Intelligence OFF
   without changing the coordinator: the extra Intelligence action disappears.
6. Compare old and new auction price tooltips with fresh, stale and mixed
   variant scans. Prices must be labeled as asks, not sales.
7. Check native loot buttons and merchant offers (including page 2 and
   buyback). No own-bag auction action should appear on vendor inventory.
8. Hold Shift *before* re-hovering and inspect detailed evidence. Check
   screen edges and UI scaling for clipping.
9. Switch the coordinator OFF and confirm the original individual tooltip
   blocks return immediately on re-hover.
10. Check another character: first-time coordinator setting should still be
    OFF. Neither mode should create secure-frame taint or perform item actions.

**Automated regressions** cover standalone composition, protection priority,
false-price warnings, duplicate events, provider failures, opt-in behavior,
real Core+LootSense combined callbacks in both modern/legacy client modes,
Core merchant fallback and LootSense integration. These are not a
substitute for actual Forever client playtesting.
