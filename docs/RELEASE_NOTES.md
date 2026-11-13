# ChalkBox 1.8.6 — TrailBar's full adventure dashboard

**The TrailBar stats previously discussed are finally implemented.** The same tiny **18px** top/bottom strip now has more useful, independently configurable metrics — without turning into another large UI window.

## Brand-new TrailBar stats

- **Free bag slots:** `Bags 12 free` (example). Includes equipped backpack/bags, including profession-specialized bags. Mouseover separates ordinary free slots from specialized ones.
- **Gear durability:** `Gear 87%` (example). Uses a weighted average of equipped repairable item durability; mouseover lists the **worst item** percentage. Warns when equipment is near breaking.
- **Rested XP:** `Rest 42%` (example). Bonus rested XP divided by your current level's total XP requirement; mouseover provides the raw rested XP. This is not Camp Benefits.
- **Home/world latency:** `World 63ms` (example), mouseover details both latency sources. Starts off by default.
- **Hunter pet health:** `Pet 95%` or `Pet none`. If Forever hides pet health as a secret during combat, shows `Pet --` rather than evaluating protected data. Does not appear on non-Hunters.
- The existing **level/XP, XP/hour, time to level, session time and gold/net** displays remain.

## Adaptive 18px layout and new settings

- New native **Esc → Options → AddOns → ChalkBox → TrailBar Stats** category with nine independently saved on/off controls.
- **Balanced** (recommended/default): existing stats, plus bags, gear and rested, with Hunter pet when applicable. World latency is optional.
- **Minimal:** only level, free bag slots and gold.
- **All:** enables all optional modules.
- The bar automatically hides lower-priority widgets when your screen is too narrow, avoiding collisions. These are temporary display choices, not edits to saved settings.
- Mouseover tooltips explain specialty bag restrictions, weighted durability, rested XP and home/world ping.
- More responsive updates via bag, equipment and resting events, plus the existing periodic 5-second update.
- Text becomes caution-colored for nearly broken gear, almost full general bags, low pet health and high world latency, when the client permits the data.

## Commands

- `/chalk bar stats` — enabled vs. currently visible fields.
- `/chalk bar stats balanced`, `/chalk bar stats minimal`, `/chalk bar stats all`.
- `/chalk bar stat bags|gear|rested|latency|pet|rate|eta|time|gold on|off`.
- Existing `/chalk bar top|bottom|off`, `reserve on|off`, `reset`, `status`, and separate-bag slider/commands remain.

## No regression to existing features

LootSense and 2,511 bundled Forever recipes, QuestSense, CampSense, Emota, QuietGuard, compact DPS meter with PRINT/RESET, Blizzard native meter PARTY PRINT and the v1.8.4 separate-bag position adjustment are preserved. The CurseForge planning folder and polished GitHub documentation remain unchanged as player-install ZIP content.

## Install

Download **ChalkBox-1.8.6.zip** from the GitHub Releases page and replace your existing `Interface/AddOns/ChalkBox` directory. Don't delete your WoW `WTF` SavedVariables. Run `/reload` or restart the game.

**Public prerelease / verification note:** Lua 5.1 regression tests validate the data and layout logic, but actual UI appearance, pet secrecy and Native client APIs should be checked in World of Warcraft: Forever. New readings never guess missing values.
