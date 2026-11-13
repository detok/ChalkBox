# ChalkBox — install and quick start

## Installation from GitHub (always available)

1. Visit **https://github.com/detok/ChalkBox/releases** or the [GitHub Releases index](https://github.com/detok/ChalkBox/releases) and download **`ChalkBox-<version>.zip`** — **not** GitHub's “Source code” archive.
2. Find your **World of Warcraft: Forever** installation using Battle.net's game menu → **Show in Explorer / Finder**, then open its `Interface/AddOns` directory.
3. Extract the included **`ChalkBox`** folder directly into `Interface/AddOns`. Final path: `Interface/AddOns/ChalkBox/ChalkBox.toc`. The `ChalkBox_Camelot.toc` should be next to it.
4. Enable ChalkBox on the character-select AddOns menu, enter the game, then type **`/chalk`** or **`/cb`**.

**The CurseForge app is optional.** Once a CurseForge file is approved, it offers a second installation route. GitHub remains the direct download/source home.

**Common nesting mistake:** `AddOns/ChalkBox/ChalkBox/ChalkBox.toc` is wrong.

## Your first five minutes

1. **Open settings** with `/chalk`; see the module categories.
2. **Enable relevant crafting hints** by opening your Leatherworking/Cooking/etc. profession panel, waiting for recipes to load, and running `/chalk loot scan`. Hover a material to see why it matters.
3. **Protect favorite items** with `/chalk keep [item]` (exact name or shift-clicked link).
4. **Inspect TrailBar** at the screen edge for XP and gold. Use `/chalk bar status` if something overlays it.
5. **Preview a reminder** with `/chalk prep test`; move it via Adventure Prep → Toast Appearance.
6. **Inspect quest watches** with `/chalk quests status`; Smart mode is the default.
7. **Pick a meter:** keep ChalkBox's compact window or `/chalk meter hide` and use the Blizzard native meter's **ChalkBox: PRINT top 3 to PARTY** gear-menu entry after combat (client permitting).
8. **Adjust bags if needed:** with separate bags active, try `/chalk bags offset 30`, or reset to 0.

## Troubleshooting quick hits

- **No LootSense hint?** Open a relevant crafting window, `/chalk loot scan`, then `/chalk loot status`. Unrelated items intentionally remain quiet.
- **No party report?** Check group state, finish combat and inspect the local warning. Forever may still protect combat values.
- **No quest watches?** Close the map/quest log, exit combat and use `/chalk quests status`.
- **Bag conflict?** `/chalk bags reset` restores Blizzard anchor.
- **Too many UI widgets?** Hide the extra combat window, disable a module in settings, or place TrailBar at bottom/off.

## Keep preferences when updating

Replacing the addon directory does **not** require deleting your game `WTF` SavedVariables. Use `/reload` after a code-only update; starting the game fresh is safest if a new addon was just installed.
