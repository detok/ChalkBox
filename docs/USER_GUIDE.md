# ChalkBox User Guide

**Version 2.0.11 · World of Warcraft: Forever**

ChalkBox puts several small tools in one addon. Everything is managed from **Options → AddOns → ChalkBox**, or **/chalk**. Choose the modules you want; the rest can stay out of sight.

## Finding your way around settings

The ChalkBox home page has three groups:

- **Discover & Track:** LootSense, DropSense, QuestSense and Session Journal.
- **Combat & HUD:** The Bar, Combat Meter, MacroForge and Adventure Prep.
- **Personalize & Manage:** Global Appearance, Emota, QuietGuard and Updates.

The native sidebar contains related pages under their parent module:

| Parent module | Nested pages |
| --- | --- |
| **The Bar** | Modules, Appearance |
| **LootSense** | Appearance |
| **Adventure Prep** | Toast Appearance |
| **Emota** | Race Behavior, Emote Catalog |

Select the module first, then its child page. The same top heading and return-to-ChalkBox navigation appear throughout. Older settings keys and SavedVariables are retained.

## First bank visit (2.0.11)

When a character opens their bank for the first time, ChalkBox no longer decorates bank item buttons or runs bag-anchor moves while Blizzard's bank interface is initializing. The bank stays native, and normal bag highlighting and configured separate-bag positioning resume after it closes. If a blocked-action dialog still occurs, record the exact blocked function or screenshot (and any Lua error stack), since a live-client trace is required to confirm its cause.

## DropSense and Map Discoveries

**2.0.11:** The Area / Dungeon field opens a direct list of all recorded zones and dungeons, with mouse-wheel navigation and paging. Choose a location to browse independently, or choose Follow world map to resync. Found counts item copies, Drops counts the times an item appeared, and Rate is based on *looted corpses from an identifiable creature*, not every kill or official odds.


**2.0.9 — Browse anywhere:** Open the Area / Dungeon dropdown in Discoveries to see **Follow world map**, **Outdoor zones**, and **Dungeons**. The grouped lists contain every location where this character has recorded loot; you can pick any of them without moving the native map. Selecting one pauses map sync and switches to its tab. Choose Follow world map in the dropdown (or toggle the existing top-right Map sync control) to follow the map again. Turning sync off restores the last location you manually chose. Preferences survive relogging and do not change existing loot history or map-button position.


**2.0.5:** The standalone Discoveries journal has a corrected layout and text initialization. Open it from the world map button or `/chalk drops map` to browse area, source and sort filters, search, and collected items.

**2.0.5:** The standalone journal now appears above the native map with an opaque themed reading surface and border. Bag markers and vendor-value calculations are also batched to reduce inventory hitching.


**2.0.5:** The Discoveries journal keeps a legible background and border even when the global theme background strength is set to zero.

**DropSense** collects every readable item it encounters in a loot window while tracking is enabled. Data is saved for the character and survives logout. Open the normal world map and click **Discoveries**, or type **/chalk drops map**.

The Discoveries browser provides:
- **Outdoor / Dungeons** views, kept separate.
- **Area / Dungeon**, **Creature Source** and **Sort** dropdowns.
- Search by item name or item ID.
- Item icons, quantities, observed loot-window counts and pagination.
- A percentage only when ChalkBox can attribute readable windows to one known creature source.

**Drop percentages are not official.** ChalkBox doesn't know the server loot table or observe every killed creature. Mixed-source and unknown-source loot is still recorded, but won't get a misleading creature-specific rate. New accounts have automatic tracking enabled; an explicit older opt-out remains respected.

### Move the map button

Drag **Discoveries** anywhere comfortable on the world map. It remembers its position per character. Right-click the button to reset, use **DropSense → Reset Map Button**, or type **/chalk drops map reset**.

If the button disappears after another map addon changes the layout, type **/chalk drops map**. Run **/chalk drops map status** and include the output in a bug report.

## LootSense and professions

LootSense helps explain why something in your bags might be valuable to *you*. It checks personal **KEEP** protections, supported quest information, ingredients used by recipes you've actually learned, and possible crafting uses from the bundled Forever reference.

Under **LootSense → Appearance**, choose whether to see confirmed crafting uses, possible/unverified uses, camping hints and verified ingredient markers in native bags. Quest and manual KEEP evidence remains the priority.

Type **/chalk keep [item]** to protect an item and **/chalk forget [item]** to remove your protection. These commands don't sell or destroy items.

**ProfessionSense** reads the recipes available through your character's open profession interface. Open a profession window, then use the refresh controls if newly learned recipes haven't appeared yet.

## MacroForge

Type **/chalk macro**, or open **MacroForge** in settings. The builder scans the learned, active spells in your character's spellbook. Choose a template: Engage, Burst + Trinkets, Modifier Keys, Manual Sequence or Mouseover Utility.

Select the abilities and any optional pet, Auto Shot, trinket or targeting actions. MacroForge shows the generated text, warns about unlearned spells and checks the 255-byte length.

**Select Text** highlights the macro so you can press **Ctrl+C**, then paste it in WoW's native **/macro** window. **Install New** is an optional, explicit out-of-combat command that creates a new character macro if the client supports it. Existing same-named macros are not overwritten.

Save up to 16 build recipes per character. After a respec, revisit a saved recipe and replace abilities you no longer know.

MacroForge is a design tool. It cannot automate a rotation, skip spells based on procs or cooldowns, or bypass the global cooldown.

## The Bar

**2.0.7:** Hover details show the metric's key numbers or current state, without repeated explanations. Repair values are still marked as quotes or estimates. Detailed help remains in module settings.


**2.0.6:** Right-click a displayed stat for a small stat-only menu. Right-click the empty Bar background to manage modules, position, and layout. Green choices are enabled, gray choices are disabled, gold marks the current position/alignment, cyan opens more controls, and amber marks hide/reset actions.
 and repair learning

**The Bar** is a compact screen-edge strip. Configure its top/bottom placement, screen reservation and modules under the main Bar page and **Modules**. The **Appearance** page manages opacity and the editable layout. Right-click an individual Bar stat for quick module controls.

Choose the information that fits your screen: XP/rate/ETA, rested XP, gear condition, bags, gold, pet status, latency and optional bag vendor value. On narrow screens, less important modules may be hidden to keep the strip readable.

The **Repair** stat shows an exact price only when a repair merchant exposes it. ChalkBox remembers real repair quotes and can show a marked **~ estimate** elsewhere. No price is displayed as exact without a current quote; it never spends your money.

The **Bag Value** stat can show the vendor resale value of junk or all inspected bag items. It doesn't automatically sell anything.

## Combat Meter

The extra compact meter is **closed each time you log in**. Open it from **Combat Meter** settings or type **/chalk meter show**. Hide it with **/chalk meter hide**.

The window supports DPS, damage, healing, taken damage and interruptions when the client exposes the necessary Blizzard data. It has configurable rows, class/spec icons, opacity, movable/locked positions and a resize grip.

**PRINT** sends a short report to PARTY only when you deliberately click it and the data is safe to report. **RESET** asks before clearing shared Blizzard combat sessions. ChalkBox can also provide a separate manual print action from the native Blizzard meter where available.

## QuestSense

**2.0.8 — Nearby only:** Tracks accepted quests with a confirmed current-zone match and keeps refreshing as you move. Out-of-area manual watches are temporarily hidden—not forgotten—and return automatically when you revisit their area or choose Smart/All. The filter does not calculate walking distance or invent quest coordinates. When reliable zone evidence is unavailable, your current watches are preserved instead of being wiped.


QuestSense organizes watch choices for accepted quests inside Blizzard's existing quest tracker. The Smart, Nearby and All modes are selectable from settings. It doesn't create unverified quest coordinates, auto-complete objectives or replace the native map.

## Adventure Prep

Adventure Prep looks for supported information about **Camp Benefits**, tents/rested XP, usable camping kits and certain class/pet needs. The compact toast tries to provide a useful next action rather than repeating an unchanged checklist.

Open **Adventure Prep → Toast Appearance** to adjust the reminder position, transparency and lock state. Type **/chalk prep test** to preview the toast and move it. Tent use and Camp Benefits are different mechanisms; the addon doesn't assume one automatically proves the other.

## Session Journal

Use **/chalk session** for the current adventure and **/chalk session last** for the previous one. It retains up to 20 completed sessions per character.

Recorded details include observed XP, levels, net gold, quest turn-ins, sampled loot, known loot regions, camp notices and confirmed merchant repair quotes. No data is guessed for activity before ChalkBox was installed.

## Appearance, personality and safety

- **Global Appearance:** shared ChalkBox background color, accent and background strength. Each module keeps its own supported position or opacity settings.
- **Emota:** opt-in contextual character emotes, with **Race Behavior** and **Emote Catalog** nested under Emota.
- **QuietGuard:** optional invite filtering.
- **Bag Position:** adjust Blizzard's separate bag-window offset.
- **Updates:** installed version and a copyable GitHub Releases address. WoW addons cannot fetch GitHub directly. Optional, default-off group-version comparison only notices other ChalkBox installations.

## Install, updates and troubleshooting

Download the installable **ChalkBox-2.0.11.zip** from the [release page](https://github.com/detok/ChalkBox/releases/tag/v2.0.11). Extract the single ChalkBox folder into **Interface/AddOns**. Don't extract an extra nested ChalkBox folder.

When updating, **keep your SavedVariables**. Use **/chalk** to check preferences and **/chalk update** to see the installed version.

If anything looks wrong, include the ChalkBox version, Forever client build, the command you used and any Lua error. For missing map controls, send the full output of **/chalk drops map status**.

[GitHub issues](https://github.com/detok/ChalkBox/issues) · [Troubleshooting](TROUBLESHOOTING.md) · [Changelog](../CHANGELOG.md)

ChalkBox is maintained by **Detok Whitemaine**. It is not affiliated with Blizzard Entertainment.
