# ChalkBox 2.1.4 — Tooltip readability pass

### No more repeated branding
- Item Insight now uses one meaningful status: KEEP, LEARNED RECIPE, POSSIBLE RECIPE, CAMP USE or BONUS XP.
- The Cozy Sleeping Bag displays the XP benefit directly rather than a second generic item insight title.
- Auction, map and macro interface helper text no longer repeats ChalkBox unnecessarily.

### Meaningful colors
- **Green:** valuable/confirmed utility and healthy state.
- **Gold:** prices, gold and exact values.
- **Blue:** counts, quantities and progress.
- **Amber:** uncertain, estimated, or attention-needed data.
- **Red:** urgent warnings, stale auction snapshots, and quest item sale protection.
- **Gray:** informational footnotes and unavailable values.

### Short, factual details
- Auction tooltips display unit low, unit average, listing/quantity coverage, source and age without promising completed sale prices.
- Drop Journal shows observed items and loots, with any observed rate labeled as a personal sample, never official odds.
- Top Bar hovers keep their existing concise metrics and add semantic colors; no changes to XP/repair/bag calculations.
- Camp notifications are shorter and show the next action quickly.
- Blizzard's native DPS meter still includes PARTY / SAY, Top 3/5/10 and opt-in after-combat reporting from v2.1.3.

### Install
Install `ChalkBox-2.1.4.zip` as the single ChalkBox folder. Preserve SavedVariables and type `/reload`. Automated Lua 5.1/ZIP checks are run by GitHub Actions. Verify the on-screen visuals in WoW Forever.
