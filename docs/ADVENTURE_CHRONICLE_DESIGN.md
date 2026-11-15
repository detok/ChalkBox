# Adventure Chronicle — implementation design

**Status: APPROVED DIRECTION / NOT YET AN EVENT RECORDER**  
**Baseline:** ChalkBox 2.2.11 visual repair and existing `SessionJournal.lua` v1
**Goal:** turn the Session/Adventure Journal into a character-owned **Full Adventure Chronicle**, not a clone of any other diary addon.

This document is a design contract for the next development phase. **Do not treat timeline events, Today / Timeline / History tabs or the proposed storage described below as already shipped.** Version 2.2.11 only fixes the existing Journal's transparent window, adds its native wood-and-bronze frame, and preserves all historical session data.

## 1. Philosophy

A good Chronicle answers:
- **What did I actually do?** Milestones, quest turn-ins, dungeon visits, significant drops, earned levels and session totals
- **When and where?** Only when timestamp, area and/or instance identity are reliably available
- **How was this recorded?** The source event, module and confidence/evidence level
- **What changed over time?** A useful session summary versus a longer-term history, without fabricating missing old events

It is **not** a chat recorder, raw combat logger, character profiler, automated story generator, achievements replica or copy of another diary addon's UI/code. Keep ChalkBox's compact module language and the warm wood appearance shared with Discoveries and MacroForge.

## 2. Ship safely in small gates

### Gate A — Visual foundations (2.2.11)

- Retain the current 590×460 independent movable window and **Current / Older / Newer / Close** controls.
- Add a full native Blizzard outer dialog frame, with a bronze-line fallback for older Forever clients without `BackdropTemplate`.
- Render the same native world-map wood atlas as Discoveries beneath a light warm tint. Retry the atlas when reopening and preserve an **opaque fallback** if art is unavailable; global theme opacity zero must never hide the journal.
- Split existing content into **Session Summary** and **Field Notes** inset sections with consistent text spacing, bronze rims and soft shadows.
- Add `ChalkBox_JournalThemeRefresh` to the global theme notification list. Leave the underlying `ChalkBoxZoneDB.sessionJournal.version=1` records **exactly as they are**.

### Gate B — Event ledger (future implementation; separate reviewed change)

- Add validated, bounded event append logic and explicit provenance. Begin with reliable nonchat facts: **level-up**, **quest turned in**, **player death**, and **party-dungeon entered / exited** when the actual client API provides enough identity.
- Write unit tests proving deduplication, bounded retention, missing/secret API behavior, and recovery from unclean logout before showing events in the UI.
- Prefer using **the already observed event** or module export over subscribing independently to the same event in multiple subsystems.
- Keep the old session summary read path untouched. Never rewrite past session entries to pretend events were captured.

### Gate C — Full Journal views (future implementation)

- **Today:** XP, gold, completed quests, observed loot and recent authentic moments. Distinguish session totals from lifetime counts.
- **Timeline:** newest-first, time-labeled event list with category/filter and location, when verified. The event detail tells what module actually observed it.
- **History:** previous sessions with summary, significant events and future date/zone filtering. Legacy v1 sessions still show their summaries, with "**Event timeline was not recorded for this session**" instead of a fabricated list.
- Only enable the Timeline/History controls when the read path is complete and tested; don't display empty decorative buttons that imply functionality.

### Gate D — Integrate ChalkBox's existing observations (future)

- Link to DropSense's bounded **outdoor loot-window** points without copying its entire per-item database.
- Highlight a notable actual drop only when item ID is known and rules are explicit, never call a common item a rare with no reliable rarity.
- Include selected AuctionSense or repair context only when it represents a **real observed action**, not unpurchased asking prices or speculative DE profits.
- Optional user-entered notes may be considered later, but must be opt-in and never scan or store chat messages.

## 3. Proposed data structure — additive, separate and versioned

Keep existing `ChalkBoxZoneDB.sessionJournal` **v1** for 20 finished sessions, including `current` and `history`. The chronicle adds a **new sibling table**, e.g.:

```lua
ChalkBoxZoneDB.adventureChronicle = {
  version = 1,
  nextId = 1,
  enabled = true,        -- deliberate user control in settings
  events = {
    {
      id = 1,            -- monotonic per-character local ID
      kind = "level",    -- allowlisted event type, never free-form
      time = 0,          -- real epoch if valid; nil when unavailable
      label = nil,       -- short, sanitized, verified title
      level = 32,        -- only if actually observed
      mapID = nil,       -- numeric map only if verified
      zone = nil,        -- verified bounded string only
      source = "PLAYER_LEVEL_UP",
      sessionKey = nil,  -- stable session association when created
    }
  }
}
```

This is **illustrative schema only**, not live code. The precise key names and session association must be approved through implementation tests and kept stable once released.

### Bounds and privacy

- Limit the overall event list to **600 per character** in the initial implementation, with constant-memory recent-event dedup bookkeeping; older events age out predictably.
- Restrict strings to allowlisted types and bounded length; no raw chat transcripts, other players' names, account details, private guild text or unbounded item-link payloads.
- Never store a floating-point map location when no valid map/instance coordinates exist. Do not invent a timestamp from session-relative clock time.
- No network transfers. All data is local to the character. Add an obvious **Record notable events** control and an intentional **Clear Chronicle History** button behind confirmation; turning recording off must not silently delete old history.
- Avoid persisting duplicate raw loot lists, auctions or every combat-log tick. Use event IDs and provenanced **references** to the owning module's existing observations when possible.
- Save only trusted numeric IDs and validated names; use a specific `unknown` display state rather than fabricated or guessed text.

## 4. Proposed event sources and evidence rules

| Moment | Proposed source | Store only when | Must not infer |
| --- | --- | --- | --- |
| Level gained | `PLAYER_LEVEL_UP` + valid current level | Event corresponds to a numeric level that differs from last recorded event | Unobserved historical level-ups |
| Quest completed | `QUEST_TURNED_IN` event quest ID + safely resolved title | Accepted event has valid numeric quest ID; title optional | A quest being watched/removed means it was completed |
| Player died | `PLAYER_DEAD` | Player death event fired; time if available | Killer name, cause, PvP context or encounter |
| Dungeon run | `GetInstanceInfo` + validated `IsInInstance`, transition events | Confirmed entry or exit for a specific **party** instance | Every zone change, raid, group activity or objective is a dungeon completion |
| Loot highlight | `DropSense` qualified observation | Item ID and **actual loot-window** event recorded, notable rule explained | Server drop rate, spawn point, item owned forever |
| Discovered area | Safe new area/map identity + explicit transition | Current map/zone identity genuinely changed, with bounded dedup | A map exploration achievement or first-ever visit if history is incomplete |
| Rare/milestone item | Existing verified loot record + explicitly supported rarity evidence | A recognized rarity is returned by the client | Crafted / auction-purchased item is a creature drop |
| Gold / repair / XP | Existing session summary counters | Rolling aggregate only, unless a specific transaction event has direct trusted evidence | Profit, kills or individual trades from net change |

## 5. Deduplication and login safety

- Apply a **short duplicate-event window** for repeated callbacks at the same transition; level-ups are keyed by the actual level. A repeatable quest may be completed more than once over time, so never permanently deduplicate by quest ID.
- For dungeon transitions use a **stable instance identity** and state machine: outside → confirmed named instance → outside; rapid floor-map changes should not create another entry. Do not claim completion solely on exit.
- Recover an interrupted logout using the v1 SessionJournal recovery path, **without replaying or duplicating previously committed chronicle events**.
- Emit only after validation; if a secondary API (quest title, zone, epoch) is unavailable, store the valid core event without guessing the missing detail.
- Protect UI and event reads with `pcall` / secret-value guards where appropriate; never trigger protected game behavior or change quest watches while displaying history.

## 6. Integration contracts

- **SessionJournal.lua** remains owner of the existing session aggregate and new Chronicle data facade until separation is warranted. If split into `AdventureChronicle.lua`, put it in the TOC in a deterministic order and update packaging manifest and tests.
- Add a **read-only detached snapshot** interface such as `ChalkBox_ChronicleEvents(filter,page)` with bounded pagination; never expose the SavedVariables table for UI mutation.
- DropSense/QuestSense may send **semantic, validated observations** to the Chronicle through a narrow optional interface; they must not depend on its window being open.
- All UI rendering is on demand; don't rebuild thousands of strings on every combat event.
- Saved user settings and old v1 history should not migrate until the new ledger is stable. No disruptive "reset journal" action is required for the visual fix.

## 7. Tests required before event writing ships

1. Fresh character and existing 20-session `sessionJournal.version=1` data both load intact.
2. Missing `time()`, `GetInstanceInfo`, quest title lookup or map APIs never cause a Lua error, fabricated title or location.
3. Level, quest, death and dungeon transition records are correct, with repeated event callbacks deduplicated and distinct repeated quest turn-ins retained.
4. The event cap is respected under thousands of simulated events, with stable newest-first paging and no growing cache.
5. Disabling recording stops new events without deleting old events.
6. Closing/reopening the UI and an unexpected client quit do not replay milestones.
7. No combat actions, chat captures, store-bought loot claims or speculative drop rates enter the ledger.
8. The new **Today / Timeline / History** views work at multiple scales, with old sessions still browsable even without a new event list.

## 8. Acceptance on a real Forever client

- **Visual:** journal has the same warm textured wood and full outer border as Discoveries, with two readable inset groups; remains legible with the Global Appearance opacity slider at 0; moves, remembers current/older navigation, and responds to theme changes.
- **Future recorder:** complete one quest, gain one level, die once on a test character if appropriate, enter/leave a party dungeon, then compare only actually observed milestones against the log. Restart the client and confirm no duplicate event writes.
- **Size:** inspect SavedVariables after sustained play to verify the event list bound and no raw text leakage.
- **Compatibility:** document when the client lacks event parameters, map art or quest-title APIs rather than disguising the gap.

## Current implementation boundary

**Version 2.2.11 ships Gate A only.** The Chronicle ledger, Today/Timeline/History views, deep module integrations and automatic milestone recordings described in Gates B–D are **designs for subsequent reviewed releases**.

[Architecture](ARCHITECTURE.md) · [Maintainer runbook](MAINTAINER_RUNBOOK.md) · [Player handbook](USER_GUIDE.md)
