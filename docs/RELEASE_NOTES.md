# ChalkBox 1.8.4 — Separate bag window offset

Your individual bag windows can now be nudged downward if a profession bag or other large bag goes off the top of your screen. **The default is unchanged: 0.** No new bag UI is installed.

## New bag positioning
- Open **Esc → Options → AddOns → ChalkBox → TrailBar**.
- Find **Separate bags: move down**. Slide from **0** (Blizzard default) to **80** (maximum), in 5-point steps.
- Start with **30** if the top of the skinning bag is cut off. Adjust until all bag titles are visible.
- ChalkBox uses Blizzard's own bag-anchor layout, repositions only the first anchor, and lets the other separate bags follow naturally.
- **Combined bags are unaffected.** This feature is for individually opened bag windows.
- Changes made during combat are safely deferred until combat ends. Reset to 0 for the original positioning.
- Slash commands: `/chalk bags offset 30`, `/chalk bags reset`, `/chalk bags status`.

## Preserved from earlier releases
- Original 18-pixel TrailBar with level/XP, XP/hour, time to level, session length and gold; its top/bottom position and screen-space reservation remain unchanged.
- LootSense's 1.8.3 First Aid pearl fix and all 2,511 bundled Forever recipes.
- DPS meter with manual party PRINT and RESET, class/spec icons, position and opacity settings, plus QuestSense, CampSense, Emota and other modules.

## Install
Download **ChalkBox-1.8.4.zip**, replace your existing `Interface/AddOns/ChalkBox` directory, and `/reload`. Your existing saved settings are retained.

**Public prerelease:** The Lua 5.1 tests cover the bag positioning logic, while actual in-game Forever bag rendering and other bag-moving addons can differ. Try the slider outside combat with all your bags open and report any overlap or Lua error.
