# Install and first five minutes — ChalkBox 2.0 prerelease

## Install

1. Download the **ChalkBox-2.0.1.zip** release asset from https://github.com/detok/ChalkBox/releases/tag/v2.0.0 (not the GitHub "Source code" ZIP).
2. Extract the **ChalkBox** folder to your Forever client's `Interface/AddOns` directory.
3. Verify `Interface/AddOns/ChalkBox/ChalkBox.toc` exists, with **no extra nested folder**.
4. Start/reload WoW Forever; type `/chalk` for options.

Everything is bundled, including the credited profession recipe library. No second addon needed.

## First five minutes

1. **Global Appearance:** choose your ChalkBox background/accent and opacity.
2. **DropSense:** check that sampling is on. Open and loot a couple of different, readable sources.
3. **Map Discoveries:** open your existing world map and look near its **upper-left canvas** for **Discoveries**. The exact position is a 2.0 test focus. If absent, type `/chalk drops map`. Then type `/chalk drops map status` and save the output for a bug report.
4. **MacroForge:** type `/chalk macro`. Choose Engage or Burst, select spells from your learned spellbook and click **Select Text** to copy via Ctrl+C. Don't install a test macro without choosing that option deliberately.
5. **Discoveries controls:** use the Area, Creature and Sort dropdowns; drag the map button if you prefer another position. Right-click or `/chalk drops map reset` to reset.
6. **Updates:** use **ChalkBox → Updates** for the installed version and a copyable release link. It cannot query GitHub inside the game.
7. **Session Journal:** type `/chalk session`. This records future activity; it cannot fabricate records from before installation.
6. **The Bar:** right-click any stat to show/hide or move it, or visit its native settings.
7. **Adventure Prep:** type `/chalk prep test` to preview and position the compact toast.

## Report an issue usefully

Include: **ChalkBox 2.0.0**, your Forever client build, exact command tried, whether `/chalk drops map` opened, the full `/chalk drops map status` output, your map layout (windowed/fullscreen) and any Lua error. Attach a real screenshot when possible.

[Issue form](https://github.com/detok/ChalkBox/issues/new/choose) · [Full guide](../../docs/USER_GUIDE.md) · [2.0 release notes](../../docs/RELEASE_NOTES.md)
