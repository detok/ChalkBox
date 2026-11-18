# ChalkBox design language — code audit and tooltip contract

> Experimental beta engineering audit · 2026-11-18 · No in-game playtest claimed.

## The principle

ChalkBox should feel like one restrained World of Warcraft companion, not
many independently designed addon windows. Keep native Blizzard item rarity,
secure controls, item tooltips, quest tracking and auction actions authoritative.
Our own information is **evidence**, not a replacement for game state.

**First glance:** what it is → recommended action/current state → short reason.
**On demand:** quantities, comparisons, source, age, assumptions and history.
Do not call an asking price a sale, observed drop frequency a true drop chance,
a bank snapshot current bags, a possible recipe learned, or a probabilistic
skill-up guaranteed.

## Visual grammar

| Role | Existing palette name | Application |
| --- | --- | --- |
| Section or module title | `title` (gold) | Standalone hover title; one per surface |
| Addon section inside a native item | `info` (teal) | Identifies what calculation is being added |
| Verified protective/positive state | `good` (green) | Known/protected/confirmed, not speculative upside |
| Money/economic metric | `value` (gold) | Copper, gold, vendor, asking prices |
| Quantities and counts | `count` (blue) | Stack totals, material counts, samples |
| Caution or missing evidence | `warning` (orange) | Not yet priced, incomplete, unverified |
| Actual danger/destructive risk | `danger` (red) | Do not sell a quest item; never for BUY |
| Primary descriptive line | `text` | What to do and why |
| Footnote, control hint or provenance | `muted` | Scan age, last seen, reference-only, Shift hint |

The source of truth is `ChalkBox_TipColor` in `Theme.lua`. New custom
tooltip lines should use `ChalkBox_TipLine(tip,text,role,wrap)`;
comparison fields should use `ChalkBox_TipMetric`; section starts can use
`ChalkBox_TipSection`. Where the shared presentation module might not be
loaded in isolated client/test paths, retain local fallbacks that preserve the
same wording and semantics. **Never recolor Blizzard's own tooltip lines.**

Wording rules: sentence case for explanations; short action labels for
decisions; `Left-click`, `Right-click`, `Shift` for affordances.
Use `per unit` or `/unit` consistently for money. Put evidence next to
the relevant estimate, not as a vague "AI confidence" score. Avoid false
precision, invented conversion rates, unexplained acronyms, repeated addon
branding, and multiple decorative separators.

## Information budget

- Default *addon contribution* to an item tooltip: a compact title, main
  action/result, a reason, then only urgent exceptions such as missing quest
  items or profession training. Aim for 3–6 lines **per major section**;
  several modules can share the same native tooltip.
- Put historical price source, bank snapshot provenance, alternate valuation,
  risk caveats, and full material math behind Shift or a dedicated panel.
- AuctionSense pricing and Intelligence may both appear: pricing supplies
  market **evidence**; Intelligence supplies an **action**. Neither should
  restate the other's complete analysis on every hover.
- Full scans or expensive recipe search must never happen merely because a
  tooltip is shown. Prefer cached, invalidated read-only snapshots.
- Default OFF for experimental Intelligence means zero new Intel lines,
  bank observation, planning, or side effects, regardless of other modules.
- Hover reuse must avoid duplicate lines, clear old *addon-owned* standalone
  GameTooltip content, and avoid secure frame manipulation or combat taint.
- Use **observed/estimated/last seen/unknown** precisely; material and sale
  projections cannot be presented as guaranteed outcomes.

## Module-by-module audit

| Area/modules reviewed | Tooltip / presentation surface | Audit outcome |
| --- | --- | --- |
| Core | Merchant quest-item tooltip; safety glow | Correctly distinguishes `BUY FOR QUEST` positive action from `DO NOT SELL` danger |
| LootSense | Item tooltip classifier, active and future quests | Good native quest authority; preserve purple future-quest distinction and bounded details; needs future centralized composition with other item sections |
| ProfessionSense | Learned reagent evidence used by tooltip/advisor | Live recipe ownership; alternative/optional flags and explicit unlearning now tracked; do not convert guesses into requirements |
| RecipeAdvisor | Known versus potential recipe copy | Explicit `KNOWN RECIPE`, `RECIPE ALTERNATIVE`, `OPTIONAL REAGENT`; correct uncertainty vocabulary |
| BagReagents / FutureQuestGlow / FutureQuestItems | Material and quest protection overlays | No separate tooltip renderer; keep native icon/rarity and gameplay relevance priority |
| AuctionSense | Native item pricing supplement | Source, low/average, sample size, age, mixed variants and asks-versus-sales already distinguished |
| AuctionSenseUI | Native AH browser and button hovers | Header and help lines now use shared palette where present; keep selected-tab state and secure AH state unchanged |
| AuctionInsights | Bag valuation, personal seller invoices, current stock | Supplies data, not independent tooltip; name-matched historical sales are qualified evidence |
| AuctionIntelligence | Item advice, My Items, plan command | Normal hover now compact, Shift reveals assumptions and market/bank details; speculative sale upside is not colored confirmed green |
| AuctionCharts | Price-history hover dots | Label lowest *asking* price, per-unit, never imply confirmed sale; shared semantic style |
| DisenchantSense | Gear-tooltip modeled material outcomes | Distinguishes unconfirmed outcomes, expected averages, Classic odds, item sale and materials pricing; Shift for full material probabilities |
| DropSense | Native loot-button journal notes | Only player's observed samples, not official odds; sample count and manual reference remain explicit |
| BankValue | Character bank inline value and hover | Distinguishes vendor from AH asking value; emphasizes visible bank snapshot, not craftable bag stock |
| MapDiscoveries | Map item locations, drop sample and map-button hints | Distinguishes near-loot-window locations from creature death locations; map button wording and palette aligned |
| MapNativePins / DiscoveriesFlights | Flight marker hovers | Compact title + verified known path; explicitly clear standalone tooltip before writing |
| QuestSense / QuestTrackerMenu | Native quest tracker/order controls | No independent tooltip renderer; keep Blizzard objective text authoritative |
| QuestNavigator | Movable arrow hover/action hint | Cleared standalone tooltip, title/state/action hint aligned; avoid promising unverified navigation data |
| TrailBar / TrailBarStats / TrailBarLayout | Compact HUD metric hovers | Shared semantic line colors; top heading aligned; no new panels or large hover summaries |
| BagLayout / ScreenLayout | Native positioning tools | No custom tooltip; preserve game controls and bag window clipping behavior |
| CampSense / CampAura / ReminderToast | Camp logic and toast notifications | Not tooltip-driven; theme uses existing semantic roles; keep messages unobtrusive |
| SessionJournal | Persistent session summary window | Not tooltip-driven; ensure concise chart/stat labels and consistent evidence source terminology |
| Emota / PersonalityContext | Idle emotes and contextual settings | No item tooltip; avoid game interruption and keep personality settings clearly labeled |
| CombatMeter / CombatMeterMenu / MeterReportCopy / NativeMeterPrint | Combat panel and read-only chat summaries | No native item-tooltip; avoid spam and distinguish session/last fight summaries |
| MacroForge / MacroForgeUI / MacroForgeDock | Macro editor and docking | No standalone item-tooltip; native macro editor remains primary, clear disabled/error states |
| QuietGuard | Suppress optional game invites and duels | No custom tooltip; settings should describe exact behavior |
| RepairLearning | Repair cost estimate and learned data | Stats/HUD source; label estimates as such and keep legacy state safe |
| UpdateCheck | Local available-version messaging | No tooltip; avoid implying the client silently downloaded an update |
| ChalkBox_Settings | AddOns options hierarchy | One settings home and subpages; consistent module headings, descriptions, toggles and cautious experimental labels |
| Theme | Shared visual colors and decorative panel theme | Source of truth for tooltip roles; never modifies Blizzard UI, item rarity, or secure frames |

## Changes from this design pass

1. Added reusable tooltip line and section helpers in `Theme.lua`.
2. Aligned map flight marker, navigation, bar, native AH and chart hover headings
   and semantic colors (with fallbacks for isolated tests/clients).
3. Corrected merchant quest purchase styling; preserved the red do-not-sell
   warning.
4. Added explicit chart tooltip disclaimer: lowest ask is not a completed sale.
5. Made Intelligence's normal tooltip glance-first and its extended evidence
   available on Shift. Tooltips still honor enabled state.
6. Clarified character-bank valuation as a last-seen character-bank snapshot.
7. Standardized Discoveries map button help and the Market toolbar hover hints.

## Remaining design risks — *not* silently redesigned

1. **Item tooltip stacking.** LootSense, AuctionSense, Intelligence,
   DisenchantSense and future-quest notes currently append independently.
   A future shared read-only tooltip composer could impose one information
   priority and deduplicate sources, but it must be tested carefully against
   Forever's native `TooltipDataProcessor`/legacy callback behavior before
   any cross-module refactor. Do not replace Blizzard tooltips wholesale.
2. **Real-client layout.** Screen size, UI scale, locale, Shift redraw and
   simultaneously available modules cannot be validated by Lua mocks alone.
3. **Long-form copy.** Some detailed Shift tooltips and settings descriptions
   remain verbose by design. Only shorten them when context remains truthful.
4. **Custom color exceptions.** Quest-specific purple and native rarity
   colors have distinct game meanings and should not be blindly forced
   through the general green/gold/teal palette.
5. **Learned/market data provenance.** Unusual Forever recipes, early loading,
   missing item info and bank partial visibility need actual in-game validation.

## Acceptance checklist for every new module

- [ ] Module matches settings name, heading, button and hover copy.
- [ ] Action appears first and does not compete with native Blizzard actions.
- [ ] Semantic color describes the **truth** of the status, not excitement.
- [ ] Numeric estimates state their basis, age and missing information.
- [ ] Tooltip still works with and without `ChalkBox_TipLine` available.
- [ ] Shift/details are optional; default hover remains readable.
- [ ] Hover duplication, addon OFF state, and normal game UI are tested.
- [ ] Lua 5.1 test suite and packaging pipeline pass before beta delivery.
- [ ] Live Forever behavior remains marked unverified until playtested.
