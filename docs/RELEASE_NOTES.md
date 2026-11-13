# ChalkBox 1.8.5 — PRINT from Blizzard's own damage meter

No need for two combat meters: **ChalkBox can now add a PRINT entry to the built-in WoW Forever damage meter's gear menu.**

## Blizzard damage meter integration
1. Open Blizzard's original damage meter.
2. Select the statistic (DPS, Damage Done, HPS, Healing, etc.) and the fight (Current, Overall, or a saved fight).
3. After combat, open that damage-meter window's **gear/settings menu**.
4. Click **ChalkBox: PRINT top 3 to PARTY**.

ChalkBox sends one compact top-three report based on **that specific built-in meter window's selection**, e.g. `CB DPS (Fight 5): 1 Detok 555 | 2 Friend 423 | 3 Companion 318`. If the Current session is empty and Forever exposes an Expired/Last session, it tries that completed fight.

The new item uses Blizzard's **`MENU_DAMAGE_METER_WINDOW_SETTINGS`** menu extension rather than covering or modifying Blizzard's damage-meter graphics, layout, sort order or protected combat UI.

## One meter or two — your choice
- To use **only Blizzard's meter**, hide ChalkBox's own window with `/chalk meter hide` or turn off **Show compact DPS meter window** under ChalkBox → Combat Meter. The Blizzard gear-menu PRINT remains.
- To use both windows, leave ChalkBox's meter enabled. Its own PRINT and RESET controls are unchanged.
- The new Blizzard menu entry starts enabled. Disable or re-enable via `/chalk meter native off` / `/chalk meter native on`; inspect with `/chalk meter native status`.

## Safety limits
- Manual click only; no automatic chat messages or automatic damage parsing.
- **PARTY only**: won't send solo or in raids and never redirects to SAY, RAID or instance chat.
- Refuses reports during combat or Edit Mode. Won't read or serialize values that Forever still marks secret after combat.
- Sanitizes names, honors 255-character chat limit, and prevents rapid repeats.
- Reports why no message was sent locally when blocked.

## Preserved
ChalkBox's existing compact combat meter (including class icons, PRINT, RESET and opacity), the 1.8.4 separate-bag downward slider, LootSense and its 1.8.3 First Aid fix, QuestSense, TrailBar, CampSense, Emota and every other module.

## Install
Download **ChalkBox-1.8.5.zip**, replace your `Interface/AddOns/ChalkBox` folder, and `/reload`. All existing settings are retained.

**Public prerelease:** Lua 5.1 automated tests exercise the integration and existing features. Actual server permissions and native menu behavior still require in-game verification in WoW Forever.
