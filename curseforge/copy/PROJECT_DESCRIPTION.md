# ChalkBox — a quieter, smarter way to adventure in WoW Forever

**One addon. One settings menu. Helpful tools that stay out of your way.**

ChalkBox brings together item and profession advice, a slim XP-and-gold information bar, quest tracking, camp reminders, combat-meter extras and a little character personality. It is designed specifically for **World of Warcraft: Forever**, with an emphasis on using the game's own interface instead of replacing everything on the screen.

You can keep ChalkBox subtle: use the native quest tracker, keep Blizzard's damage meter, and turn off the parts you don't want.

---

## What ChalkBox brings to your game

### LootSense + ProfessionSense — know why something might be useful

Hover over an item to see contextual advice when ChalkBox has relevant evidence:

- **Quest items** and items you personally marked to keep are prioritized.
- **KNOWN RECIPE** identifies ingredients found in recipes your character's profession window exposed as learned.
- **POTENTIAL USE** clearly distinguishes a recipe found in the bundled database from one you actually know.
- **Camping reagents and tools** are flagged when there is a relevant Forever-specific use.
- **No misleading “safe to sell” verdicts.** ChalkBox does not automatically sell, delete, buy or use items.

The download includes a local **2,511-recipe Forever database** for possible crafting uses; you do not need to install a separate recipe library. Open your profession window once to let ChalkBox learn what your character can actually craft. Where available, material tooltips show recipe names and the amounts in your bags.

### TrailBar — your adventure dashboard in 18 pixels

A compact, **responsive 18-pixel** strip at the top or bottom of your screen shows the numbers that matter:

- Level and XP percentage, session XP/hour, and estimated time to your next level
- **Free bag slots** across equipped bags, with **general vs. profession-only free slots** in the tooltip
- **Gear durability**, including weighted overall condition and lowest-condition item
- **Rested XP** expressed as a percent of one level, separately from Camp Benefits
- **Hunter pet health** when the client permits it, with a safe unavailable state for protected values
- Optional **world latency** (home and world ping in the tooltip)
- Session time, current gold and net gold change

Choose **Balanced**, **Minimal**, or **All**, or enable individual widgets under **ChalkBox → TrailBar Stats**. The bar automatically hides lower-priority metrics at narrow UI widths so labels don't overlap. Increasing the width lets them reappear. The bar stays 18 pixels tall regardless of how many metrics you enable.

Each widget has helpful mouseover detail, and optional reserved-screen-space mode keeps the strip out of ordinary UI. If an API is unavailable, ChalkBox leaves that metric unavailable rather than inventing a number.

### Combat Meter — pick the display you prefer

**Option A: use Blizzard's built-in Forever meter.** ChalkBox adds **“ChalkBox: PRINT top 3 to PARTY”** to that meter's gear menu. After combat, it can send one short report using the selected native window's statistic and fight history. The command works only when a normal party is available and the client permits reading the totals.

**Option B: use ChalkBox's compact meter.** See DPS, Damage Done, HPS, Healing Done, Damage Taken and Interrupts, with genuine class icons, class-colored rows and current/last/overall sessions. Move and resize it, lock its position, adjust opacity, choose class/spec icons and manually PRINT to PARTY. RESET asks for confirmation because Blizzard's damage-session data is shared.

If you prefer **one meter**, hide the ChalkBox window with `/chalk meter hide`; the integration with the Blizzard meter is independent.

### QuestSense — smart watches, familiar quest tracker

QuestSense reads your **accepted quests** through Forever's quest log and manages watches on Blizzard's existing tracker. Choose:

- **Smart** (default): prioritize relevant and recently accepted quests, then fill spare watch slots.
- **Nearby only**: only follow quests with enough current-zone evidence.
- **All accepted**: follow accepted quests in quest-log order, up to your selected limit.

ChalkBox preserves quests you manually watch. It delays watch edits when the world map or quest log is open, in combat, or in other restricted situations. QuestSense is **not** a quest-arrow navigation addon and does not invent map pins.

### Adventure Prep — camping, tent and class-aware reminders

Stay aware of **Camp Benefits** and relevant supplies without repeated, noisy chat. ChalkBox distinguishes the Camp Tent's rested-XP top-up from an ongoing camp buff and can recognize supported Forever status indicators. Optional notices appear near the top of the screen, with adjustable transparency, a draggable/unlockable position and automatic fade.

The reminders can also consider your character's class and pet. They provide **advice**, not automated gameplay.

### Emota — optional personality

When enabled, Emota can occasionally perform native character emotes and idle reactions, influenced by class, race, rest areas and pets. Its automatic reactions are **opt-in** and configurable; there is a catalog to preview or disable individual emotes.

### Small quality-of-life protections

- **QuietGuard:** unsolicited guild-invite and duel protections, with other social restrictions opt-in.
- **Separate bag positioning:** if opening several individual bags pushes a profession bag off the screen, TrailBar settings include a **0–80 UI-point downward offset** (default 0). Combined bags remain in Blizzard's normal layout.
- **Native controls:** the addon uses WoW's normal AddOns settings pages instead of requiring a second configuration app.

---

## Getting started

1. Install the CurseForge **ChalkBox** addon file. For manual installation, place the extracted folder at `Interface/AddOns/ChalkBox/` and confirm that `ChalkBox.toc` is directly inside that folder.
2. Enable ChalkBox on the character selection AddOns screen and enter the game.
3. Type **`/chalk`** (or **`/cb`**) to open **Esc → Options → AddOns → ChalkBox**.
4. Open a crafting profession window once to populate learned recipe information.
5. Try `/chalk prep test` for an on-screen reminder preview.
6. Prefer Blizzard's original combat meter? Type `/chalk meter hide`, then use **ChalkBox: PRINT top 3 to PARTY** in the Blizzard meter's gear menu after combat.

Useful commands: `/chalk loot status`, `/chalk loot scan`, `/chalk keep [item]`, `/chalk quests status`, `/chalk bar status`, `/chalk bags offset 30`, `/chalk meter native status`.

## Designed for Forever — with honest limits

ChalkBox is a **WoW Forever / Camelot focused public prerelease**, not a promise of compatibility with every Retail or Classic client. It relies on client APIs for quests, professions, auras and combat information; some information may be unavailable or protected. Combat reports are **manual, PARTY-only, after-combat** and never automatically sent. Reports will be refused if names or numbers remain secret.

ChalkBox is local Lua code; it does not require an account or online service to use its features. Settings and observed profession recipes live in WoW's SavedVariables.

## Source, help and acknowledgements

**Author:** Detok · **License:** MIT

- **Source and issue tracker:** https://github.com/detok/ChalkBox
- Please report bugs with your ChalkBox version, Forever client build, reproduction steps and exact displayed message. Logs and screenshots can help, but remove any private details first.
- This addon embeds the separately MIT-licensed **LibProfessionDB 1.9.1** by **Pimptasty** and public-domain **LibStub**. Their original license notices are included in the addon package.

*Independent community project. Not affiliated with Blizzard Entertainment or CurseForge.*
