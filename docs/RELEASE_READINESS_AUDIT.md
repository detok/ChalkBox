# ChalkBox 2.2.25 — release-readiness audit

**Audit snapshot: November 17, 2026 · reviewed from main commit
`7a01552c8f65d81197a4d60691e51d26d13a6f50`**

This report is a release gate, not a claim that every feature was played
successfully in the Forever client. The 2.2.25 GitHub beta has a passing
`main` workflow (run 44022092185); 2.2.22 remains the last accepted stable
build. Tests mock WoW APIs. Do not publish a stable update based only on CI.

## Audit scope and findings

| System | Code connection reviewed | Assessment / next check |
| --- | --- | --- |
| Load, packaging, settings | Two TOCs, deterministic ZIP manifest, native Settings and Classic fallback navigation | Both TOCs match; all 22 settings-page constructors are registered. Keep both interface IDs and the exact load order. Verify nested pages on Forever and small screens |
| LootSense, quest and professions | `Core` accepted quest evidence → `LootSense`; `ProfessionSense`, `RecipeAdvisor`, bundled Forever recipe reference | Existing active-quest name/count behavior must stay unchanged. `BagReagents` cosmetic outlines are **intentionally paused** for protected-button safety, not a missing module |
| Future quest items | PR #93, **not in main** | Small independently researched catalog, additive tooltip and purple markers remain experimental. Prove item associations, active-quest precedence, sorting and no secure-button taint in-game before integrating |
| DropSense / Discoveries | `DropSense` observed loot and bounded positions → `MapDiscoveries` browser, temporary hover dot, Session Journal loot counters | Source and location samples are observational, not mob spawn coordinates or official rates. Map ID/zoom/render issue has proposed native-pin fix in draft PR #94, not in main |
| Known flights | `DiscoveriesFlights` records only taxi node states verified learned on this character; map filter | Tests pass but zoomed-in drawing still requires real Forever check. Opening a taxi map is needed to populate personally verified nodes. PR #94 changes only rendering |
| AuctionSense / Market / charts | Manual scan → `AuctionSenseUI`, `AuctionCharts`, `AuctionInsights`, bag/DE valuation | Data links exist, but asking prices must never be called sales. Test native Buy/Sell/Auctions interactions, delayed/full scan, and stale-snapshot preservation. Do not merge superseded Market UI PRs together |
| Bank Value / The Bar | `BankValue` → saved per-character snapshot, bank readout and `TrailBar`; AH asks separately labeled | Link exists in main and mocked tests cover Camelot bank lazy loading. Verify first bank open, unreadable tabs, character isolation, Bank -- before observation, Bar module width and bank close |
| Repair learning / bar layout | `RepairLearning` / `TrailBarStats` / `TrailBarLayout` / `ScreenLayout` / `BagLayout` | Integration present; ensure text remains readable at 80–100% UI scale and combat/bank never triggers secure button or anchor changes |
| QuestSense / Nav Beacon | `QuestSense`, `QuestNavigator`, `QuestTrackerMenu` | Live quest watch state and map pin are read-only where required; check smart dungeon watch/restore, nearby mode, ghost mode, map-pin follow, right-click header and no missing client API crashes |
| MacroForge | `MacroForge` ↔ native footer dock and independent workbench | Spellbook-only recipes and explicit Install New; test at multiple resolutions, docking, scroll/copy and safe combat refusal |
| Combat meter / report | `CombatMeter` → `CombatMeterMenu`, `NativeMeterPrint`, `MeterReportCopy` | Manual ranked chat, top-N, copy fallback, reset confirmation, auto OFF by default. Check actual PARTY/SAY delivery only with consent and while grouped; don't mistake an API call for actual delivery |
| Session Journal / camp | `SessionJournal` subscribes to loot/repair/camp and native session metrics; `CampSense`, `CampAura`, `ReminderToast` | Data linkage present; verify logout/relogin bounded history, toast drag/opacity and tent-vs-camp-benefits distinction |
| Emota / QuietGuard | `Emota` and `PersonalityContext`, opt-in guard controls | Automatic emotes OFF by default; unimplemented racial flavor is explicitly labeled planned. Guard filters OFF by default. Check existing opt-in state survives reload |
| Updates | `UpdateCheck` → native Updates settings | No runtime GitHub/HTTP lookup is claimed; local version and opt-in peer comparison only. Keep the wording accurate |

## Specific issues discovered in this pass

1. **Fixed on this draft:** The settings **Open Map Discoveries** button
   previously called a map-owned window that returns false when the native
   World Map is closed, without telling the user. A deliberate open action
   now asks Blizzard's `ToggleWorldMap` once and waits briefly for lazy
   initialization. If unavailable or blocked, settings and slash command
   give an actionable message. The journal still cannot become a standalone
   detached window, and no map geometry is changed.
2. **Fixed on this draft:** Combat Meter settings incorrectly said
   `Appears by default`; the intended normal behavior is **starts hidden**.
3. **Open — client only:** Zone-map pin rendering on the local canvas is
   inconsistent; PR #94 uses native `MapCanvas` provider/pins. Its Lua
   test suite passed, but Forever visual testing remains mandatory.
4. **Open — legal/provenance:** The bundled
   `Libs/ForeverDisenchantData/Materials.lua` comes from MIT-licensed
   DisenchantForever, but that source identifies its Classic probability
   reference as vMaNGOS/CMaNGOS. Those upstream projects have different
   licenses. The actual redistribution rights of the derived numerical data
   and table compilation need review; the immediate MIT label alone is not
   a full chain-of-title conclusion. Do not add another extracted external
   quest database. The separate PR #92 is explicitly **excluded**.
5. **Open — UI acceptance:** Experimental charts, native Auction tab
   highlight, bank label, meter chat, nonstandard Forever map artwork,
   optional purple bag borders, and low-resolution screens cannot be
   certified visually by mocked APIs.

## Candidate-selection decision before any merge

- **Baseline:** 2.2.25 beta from `main`.
- **Review separately:** #94 native zone-map renderer, #93 curated
  future-quest data/marker. They are not yet integrated.
- **Exclude:** #92 questionable extracted quest database.
- **Do not merge wholesale:** Older overlapping preview PRs
  #78/#79/#84–#90. Parts of their behavior are already present in main;
  comparing or mixing whole heads can reintroduce superseded UI decisions
  or duplicate modules. Select specific changes only with source review.
- **Create one versioned release candidate only after deciding exactly
  which of these changes are accepted in-game.** Don't promote or update
  the existing stable tag by accident.

## Required Forever acceptance checklist

Mark a section as accepted only after an actual client test. Preserve
`SavedVariables`; do not reset real user data just to make a test pass.

- [ ] **Install and old-data upgrade:** Upgrade from a previous installed
  version; verify one `ChalkBox` addon, both TOCs, /reload, current version,
  all saved settings/history/auction data intact, no Lua errors.
- [ ] **Native Settings:** Every parent and child page opens; no opaque
  overlay, clipped labels, wrong group, inert buttons or incorrectly
  advertised features. Run at a lower UI scale / narrower window as well.
- [ ] **LootSense:** Live accepted-quest title and collected/required
  counts unchanged, personal KEEP priority, learned vs possible recipes,
  no accidental vendor action. Test future Hops only if #93 is included.
- [ ] **Discoveries:** Loot two outdoor targets, repeated corpse/no false
  counts, source rates labeled observational, valid recent coordinate,
  unsited records handled honestly, list filters/map sync, tooltip pulse
  in zone and nested map views, none in dungeons.
- [ ] **Flight paths:** Visit a real flight master, inspect a known and an
  unknown path on the continent and its zoomed-in zone; pan/zoom/reopen.
  Compare `/chalk drops map flights status`. Native icon must actually
  be visible (not merely hoverable).
- [ ] **Auction House:** Verify initial Buy tab, Market transition and
  return to native Buy/Sell/Auctions, one browse snapshot, safe handling
  of full-listing cooldown/delay, preserved older snapshot and honest
  ask-vs-sale labeling. No background scans.
- [ ] **Bank and Bar:** First-time bank UI, partial/unknown tabs,
  bank readout placement, Bank -- before snapshot, saved value afterward,
  bar module resize/move/lock across /reload, screen/bag offsets,
  combat/bank safety.
- [ ] **Combat:** Meter starts hidden, manual report outside combat,
  requested channel and top N only, copy path where native chat refuses,
  auto off, reset confirmation, locked positioning and no protected API
  errors.
- [ ] **QuestSense and MacroForge:** Smart/nearby/all with manual watch
  restoration; dungeon entry/exit; Nav Auto/manual/corpse/map-pin;
  native macro dock/open, scroll preview, explicit Install New,
  refuses installation during combat and never edits old macros silently.
- [ ] **Journal / Adventure Prep / Emota / QuietGuard:** Current and
  older sessions after relog, tent distinct from camp buffs, toast preview
  move/lock/opacity, opt-in emotes only, guard defaults OFF and old
  preferences preserved.
- [ ] **Packaging and rights:** Review full third-party provenance and
  required notices. Verify current CurseForge flavor exists before
  uploading. Review all ten stored screenshots for obsolete UI.
- [ ] **Release engineering:** Explicit new version in both TOCs,
  changelog, release notes, current CurseForge changelog, stable/beta
  channel, single-root ZIP, successful PR CI, live acceptance,
  final human review, and main push publication. A push to `main`
  triggers the GitHub release workflow automatically.

## Test distinction

There are **50 Lua `tests/test_*.lua` scripts** on main, in addition to
syntax checks, documentation checking, deterministic addon packaging and the
media-kit test. They validate regression contracts under mocked APIs;
they do **not** replace a real Forever UI/chat/auction/map test.

This checklist can be reused for later releases; don't convert unchecked
items into success claims. See [maintainer runbook](MAINTAINER_RUNBOOK.md),
[release process](RELEASE_PROCESS.md), and [release notes](RELEASE_NOTES.md).
