# ChalkBox 1.7.1 — Camp Tent awareness + the customizable DPS meter

## CampSense now knows when your Camp Tent worked

**Camp Tent is not a persistent Camp Benefits aura.** Its purpose is to refill Rested XP to **5% of a level**, and it applies the **Boosted Rest** lockout debuff (spell **1229451**) for approximately an hour. These are *separate* from the other campfire stat buffs.

- CampSense now scans your **harmful auras** for Boosted Rest, via modern `C_UnitAuras` or Classic `UnitDebuff`, instead of assuming missing Camp Benefits means the tent failed.
- If Boosted Rest is active: **tent already used**, no false tent reminder.
- If your stored Rested XP is already **at least 5% of a level**: another tent cannot increase it, so no reminder.
- If Rested XP is lower, the lockout is absent and both APIs are readable: camp tent top-up *could* help.
- If APIs are unavailable/protected: status **unknown**, never falsely report a failed tent.
- The one-hour **Camp Benefits** stat aura remains a separate status. Its expiry can still be useful, but its absence alone is not evidence a tent needs using.
- Fallback for unusual Forever clients: **Adventure Prep → Tent Used** or `/chalk prep tent done` acknowledges tent use for one hour *in the current session*. `/chalk prep tent clear` clears it; `/chalk prep tent status` explains the current status. Boosted Rest remains authoritative.
- `/chalk prep` prints **both** separate statuses, and the native Adventure Prep settings page shows **Stat buffs / Tent XP** independently.

## The DPS meter, your way

- **Removed CHALKBOX branding and the gold-marker/native-data footer** from the meter window. No filler labels at the bottom.
- The compact header now contains only: **DPS ▸ | Fight ▸ | PRINT | LOCK | X**.
- **LOCK / UNLOCK on the window itself** prevents accidental movement and resizing.
- A real **Opacity slider on the window** (35–100%) plus one in **Options → AddOns → ChalkBox → Combat Meter**; opacity is saved.
- A small **bottom-right resize grip** can resize the window horizontally and vertically. Width and number of visible rows (5–12) save across sessions; three preset sizes still exist in Settings.
- **PRINT** outputs the currently selected fight ranking to *your own local chat*, with stat type and player totals. If Current is empty, it tries the last completed fight. The button **does not send messages to party/raid chat**.
- Forever may hide meter names/totals as *secret* while in combat. PRINT refuses in-combat printing and fails safely if the data is still protected; it never guesses, leaks or performs Lua arithmetic on protected values.
- `/chalk meter print` and `/chalk meter opacity 75` offer direct command alternatives.
- The **Reset Data...** action remains separate, confirmation-required, and affects the Blizzard shared meter only when intentionally selected.

## Installation

Download **ChalkBox-1.7.1.zip**, unzip its single `ChalkBox/` folder into `Interface/AddOns/`, and `/reload`. Existing SavedVariables, LootSense's **2,511 bundled Forever recipes**, TrailBar, Emota, QuestSense and QuietGuard remain.

Test the meter by moving its header, dragging its bottom-right grip, adjusting Opacity and toggling LOCK. After a completed fight, click PRINT. For CampSense, type `/chalk prep` after resting at a tent and look for **Boosted Rest ACTIVE** even when **Camp Benefits** is missing.

**Public prerelease:** CI runs Lua 5.1 and deterministic ZIP tests with mocked combat/auras, not an actual Forever session. If your client returns different protected data, report your build and the exact error. Sources: [Boosted Rest](https://www.wowhead.com/forever/spell=1229451/boosted-rest) and [Blizzard meter API](https://warcraft.wiki.gg/wiki/API:C_DamageMeter.GetCombatSessionFromType).
