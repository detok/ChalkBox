# ChalkBox architecture and safety boundaries

**Maintainer reference · addon version 2.2.11**

ChalkBox is **one Lua 5.1 addon** for WoW Forever. No separate addon, backend process, runtime HTTP client or outside service is required. The code runs inside the game client under native Blizzard event and UI constraints. All tests simulate supported events/APIs, but in-client testing remains necessary.

## Boot and load order

- The installable ZIP root is exactly **`ChalkBox/`**.
- `ChalkBox.toc` (Interface 11509) and `ChalkBox_Camelot.toc` (Interface 16001) declare the **same ordered modules**, license and version. Their differing interface IDs are intentional; they do not by themselves certify every game flavor.
- `scripts/package.py` lists the same Lua files in the same order. The manifest test fails when those inventories differ.
- Bundled `LibStub` and `LibProfessionDB-1.0` load before ChalkBox's own modules. Keep vendor data, pinned license notices and bundled module order unchanged unless intentionally updating the source and tests.
- `Core.lua` establishes core item/quest awareness; `LootSense.lua` owns the root `/chalk` slash dispatcher; `ChalkBox_Settings.lua` registers native AddOns pages.

## Source map

| Area | Key files | Responsibility |
| --- | --- | --- |
| Quest/vendor and item safety | `Core.lua`, `LootSense.lua` | Accepted quest item matching, merchant context, personal KEEP and tooltip evidence |
| Profession evidence | `ProfessionSense.lua`, `RecipeAdvisor.lua`, `Libs/LibProfessionDB-1.0/` | Learned recipes versus possible catalog uses |
| Loot tracking / journal | `DropSense.lua`, `MapDiscoveries.lua` | Loot-window observations, source/area aggregation, outdoor position samples and native World Map sidecar |
| Market / DE | `AuctionSense.lua`, `AuctionSenseUI.lua`, `AuctionInsights.lua`, `DisenchantSense.lua` | Explicit AH read scans, realm/faction snapshots, bag/sales insights and modeled DE outcomes |
| Quests | `QuestSense.lua` | Native watch-list reconciliation, conservative zone and instance matching, saved manual watches |
| Macro wizard | `MacroForge.lua`, `MacroForgeUI.lua` | Learned spell validation and macro generation; presentation and explicit copy/install |
| HUD / screen | `TrailBar.lua`, `TrailBarStats.lua`, `TrailBarLayout.lua`, `ScreenLayout.lua`, `BagLayout.lua` | Stats, per-character layout, safe native top chrome shift, bounded separate bag offset |
| Combat | `CombatMeter.lua`, `NativeMeterPrint.lua` | Optional native-data window and gated manual reports |
| Camp / character behavior | `CampSense.lua`, `CampAura.lua`, `ReminderToast.lua`, `Emota.lua`, `PersonalityContext.lua`, `QuietGuard.lua` | Readable buff/prep hints, native emotes and opt-in social filtering |
| Adventure Journal / future Chronicle | `SessionJournal.lua`, `docs/ADVENTURE_CHRONICLE_DESIGN.md` | Existing v1 bounded session summaries with a framed native window; future event ledger is design-only, no new historical event recording |
| Sessions and maintenance | `SessionJournal.lua`, `RepairLearning.lua`, `Theme.lua`, `UpdateCheck.lua`, `ChalkBox_Settings.lua` | Bounded history, quote-learning, theme, update information and native settings |

## Persistence and ownership

The TOCs declare three data roots:

| SavedVariables root | Lifetime | Examples in source |
| --- | --- | --- |
| `ChalkBoxDB` | Account-wide | General controls, QuietGuard, AuctionSense snapshots, Bar stat preferences |
| `ChalkBoxZoneDB` | Per character | `dropSense` observations, `sessionJournal`, `macroForge` recipe data, quest watch settings, `trailLayout` |
| `ChalkBoxProfessionDB` | Per character | Learned-profession observation data |

Never delete a player's SavedVariables during a normal update. Prefer additive optional fields, bounded collections and version-aware migrations (existing DropSense version 2 is preserved). **Do not retroactively invent observations**: e.g., old loot data cannot acquire real coordinates or source-confirmed odds after the fact.

## Evidence hierarchy

1. **Directly accepted quest or personal KEEP evidence** must outrank speculative reagent hints.
2. **Learned recipe data observed from the player's profession UI** is distinct from a static reference catalog's potential uses.
3. **Readable loot windows** establish personal observed outcomes, *not all kills or official drop probabilities*.
4. **Auction listings** establish asks with source/age/realm context, *not completed sales*. Seller-mail receipts have their own limited evidence.
5. **Player position at LOOT_OPENED** is not a precise enemy death or spawn point. Do not attribute coordinates inside dungeons.
6. **QuestSense dungeon matches** require current instance identity plus reliable instance map/quest category evidence. Generic `Dungeon` labels, absent POIs or an unaccepted quest marker cannot authorize a watch.

When the client cannot provide data, label it **unknown**, preserve the current safe state, or skip the operation. Do not manufacture certainty.

## Protected game actions and client variability

- Guard APIs with `type(func)=="function"` and safe reads; Forever may expose secret/unavailable values.
- No automatic buying, selling, posting, disenchants, inventory moves, combat rotations, macro presses, protected frame actions, or unsolicited messages.
- Defer watch changes in combat and while the World Map/quest log is open. Restore manually selected watches after filtering instead of clearing all watches.
- MacroForge can **display** code, allow Ctrl+C, or explicitly create a new macro outside combat; its generated commands obey Blizzard's physical-keypress and cooldown rules.
- Keep Blizzard's native Settings surface transparent. MapDiscoveries should **dock** to the map without altering WorldMapFrame geometry. The art atlas has a readable fallback when unavailable.
- The Bar may shift eligible Blizzard top frames safely; never move `UIParent` or protected action bars. Bag adjustment is deferred during combat and first bank initialization.
- QuietGuard filters are default OFF; do not overwrite an existing saved opt-in. Emota automatic behavior is opt-in and must not fire during combat.

## Module interfaces

Global functions named `ChalkBox_*` are small integration contracts between runtime modules. Prefer a read-only snapshot for external data, e.g. `ChalkBox_DropRead`, `ChalkBox_AuctionPrice`, `ChalkBox_QuestStatus` or `ChalkBox_ForgeStatus`. Never return a mutable SavedVariables table to a UI panel when a detached copy will do.

Avoid cross-module circular initialization and protected-client API assumptions; UI modules should display information, not silently make decisions on behalf of other modules. Test behavior with mocked WoW APIs in `tests/test_*.lua` and complete one manual client pass.

## Updating the architecture

For every significant feature: identify owning module, data provenance, saved state, UI destination, failure behavior, test fixture and in-client acceptance steps **before** editing code. Update [Development](DEVELOPMENT.md), [Maintainer runbook](MAINTAINER_RUNBOOK.md) and [Player handbook](USER_GUIDE.md) when changing public behavior.

[Documentation home](README.md) · [Developer guide](DEVELOPMENT.md) · [Release process](RELEASE_PROCESS.md)
