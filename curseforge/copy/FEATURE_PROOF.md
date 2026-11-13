# ChalkBox 2.0 — feature and claims audit

This matrix describes **what the current code intends to do and what CI tests exercise**. It is *not* a replacement for a real WoW Forever gameplay QA pass.

| Feature | Source | Safe public claim | Known limits / manual test |
| --- | --- | --- | --- |
| Automatic DropSense | `DropSense.lua` | Records **readable loot-window** item IDs, quantities and observed windows by character | Not all kills/rolls; not an official drop chance; API data may be protected |
| Map Discoveries | `MapDiscoveries.lua` | Optional Discoveries button and separate outdoor/dungeon/creature-source loot browser; **/chalk drops map** fallback | 2.0 late-loading map/canvas placement requires real-world UI check |
| LootSense | `LootSense.lua`, `Core.lua` | Quest and personal KEEP hints; differentiate learned vs potential recipe uses | No guaranteed “safe to sell”, no automatic selling |
| ProfessionSense | `ProfessionSense.lua`, `RecipeAdvisor.lua`, `Libs/` | 2,511 bundled Forever recipes; learned recipe scan on supported professions | Open profession UI to populate actual learned list |
| The Bar | `TrailBar.lua`, `TrailBarStats.lua`, `TrailBarLayout.lua` | Adaptive 18px status strip; customizable modules, right-click menus, Junk/Total vendor bag value | Responsive display can hide low-priority stats if space is insufficient |
| Repair Learning | `RepairLearning.lua` | Real merchant quotes plus bounded learned estimates flagged **~** | Bagged gear/discounts make estimates approximate; never auto repair |
| Session Journal | `SessionJournal.lua` | Current + last 20 sessions of actually observed events | No backfill; raw combat kills are not inferred |
| MacroForge | `MacroForge.lua`, `MacroForgeUI.lua` | Spellbook-aware templates, copy-ready validation and saved builds; optional explicit native macro creation | Cannot bypass GCD, detect procs for execution or automate rotation; needs game-client UI QA |
| QuestSense | `QuestSense.lua` | Smart/Nearby/All accepted quest watches in Blizzard tracker | No new routes, coordinates, quest automation; protected APIs may limit writes |
| CampSense | `CampAura.lua`, `CampSense.lua`, `ReminderToast.lua` | Compact camp reminders informed by supported buff, tent, supply and pet signals | Readable data varies; tent's rested XP ≠ Camp Benefits |
| Combat tools | `CombatMeter.lua`, `NativeMeterPrint.lua` | Optional compact stats, manual PARTY print and native meter gear-menu integration | Protected client meter data may be unavailable in combat |
| Shared theme | `Theme.lua`, `ChalkBox_Settings.lua` | Global ChalkBox background/accents and local opacity | Doesn't recolor Blizzard's interface |
| Emota | `Emota.lua`, `PersonalityContext.lua` | Opt-in contextual emotes and race preferences | Some race entries may offer only baseline behavior |
| QuietGuard & bag position | `QuietGuard.lua`, `BagLayout.lua` | Configurable invite filters, separate bag offset | Different native layouts may need game-client QA |
| Packaging | `scripts/package.py`, `scripts/test_packages.py` | Reproducible one-addon ZIP, both Forever TOCs, included libraries/licenses | Verify GitHub release asset, not Source code ZIP |

## Proof hierarchy

1. **Code + automated Lua fixture** — catches syntax, deterministic branch logic, packaging and regressions.
2. **Actual Forever client** — confirms Blizzard frame loading order, map button visibility, spellbook icons and protected API behavior.
3. **Honest presentation** — only show real gameplay screenshots once item 2 is confirmed. Existing SVG feature grid is clearly labeled editorial illustration.

## Do not claim

- Blizzard/Forever official drop tables or exact per-kill probabilities
- AI-driven combat, unattended macros or GCD circumvention
- Every panel tested at every scale or interface configuration
- MapSense-style continuous zoom/pan as a shipped feature
- Automated selling, repairing, hidden quest markers, fabricated game states
- CurseForge approval, listing URL or performance benchmarks not actually verified

## 2.0 test focus

- [ ] Fresh login → open world map → Discoveries button visible above map canvas
- [ ] Change zones/maps, windowed/fullscreen; click remains reachable
- [ ] `/chalk drops map` opens even if button absent; `/chalk drops map status` prints useful diagnostics
- [ ] Loot several sources; outdoor/dungeon records remain separate
- [ ] MacroForge learned-spell list, icon layout, copy/paste and explicit new native macro function
- [ ] The Bar, CampSense, QuestSense, combat meter and Session Journal work with existing saves

Only mark this checklist complete after real in-client observation. Repository CI does not substitute for it.
