<div align="center">

<img src="curseforge/artwork/chalkbox-github-header-1600x470.svg" alt="ChalkBox for WoW Forever" width="100%" />

# ChalkBox

**A collection of useful tools for World of Warcraft: Forever.**

[Download 2.0.4 — Test release](https://github.com/detok/ChalkBox/releases/tag/v2.0.4) · [Report a bug](https://github.com/detok/ChalkBox/issues/new/choose) · [User guide](docs/USER_GUIDE.md)

</div>

ChalkBox adds small improvements around the parts of the game you use every day: finding useful loot, managing quests, tracking progress, preparing for camp, and setting up your action buttons. Pick the modules you want and turn off the rest.

It installs as **one addon**, including its profession recipe data. You don't need to download any companion packages.

## What's included

| Module | What it does |
| --- | --- |
| **DropSense + Map Discoveries** | Saves the items observed in your loot windows. Browse them by outdoor zone, dungeon, or known creature source from a searchable window attached to the world map. |
| **MacroForge** | Builds copy-ready macros from abilities in your actual spellbook. Includes openers, trinket attempts, modifier keys, mouseover targeting, and manual cast sequences. |
| **LootSense + ProfessionSense** | Helps identify quest items, personally protected items, reagents in learned recipes, and possible crafting uses. Includes the Forever recipe catalog. |
| **The Bar** | An optional 18px screen-edge strip for XP, level progress, bags, rested XP, gold, gear, repair estimates, and other selected stats. |
| **Repair Learning** | Remembers real repair quotes and uses them to estimate the cost of damaged gear away from a merchant. An estimated price is marked with a tilde. |
| **Session Journal** | Keeps a recap of the current session and up to 20 previous sessions: XP, gold changes, quest turn-ins, sampled loot, and other recorded events. |
| **QuestSense** | Manages accepted-quest watches in Blizzard's native tracker. |
| **Combat Meter** | A small optional DPS/healing/interrupt meter, with a manual PARTY report. ChalkBox also adds a separate report action to Blizzard's meter where supported. |
| **Adventure Prep** | Short reminders for supported camping, rested-XP, supplies, buffs and pet-care signals. |
| **Appearance, Emota, QuietGuard & Bags** | Shared ChalkBox colors and transparency; optional character emotes, invite filtering and bag-window positioning. |
| **Updates** | Shows the installed addon version and a copyable GitHub Releases link. An optional group-version comparison can flag newer versions seen among other ChalkBox users. |

### A better-organized settings menu

Open **Options → AddOns → ChalkBox** or type **/chalk**. The main page groups the modules into *Discover & Track*, *Combat & HUD*, and *Personalize & Manage*. A module's more detailed pages now sit underneath it in the native sidebar.

For example, **The Bar → Modules / Appearance**, **LootSense → Appearance**, **Adventure Prep → Toast Appearance**, and **Emota → Race Behavior / Emote Catalog**. Existing saved settings are preserved.

The optional ChalkBox DPS meter **starts closed each time you log in**. Open it yourself from its settings or with **/chalk meter show**.

### Map Discoveries

**2.0.4 fixes:** The standalone Discoveries journal now uses a native background and foreground layer so Blizzard's map cannot cover its panel. Bag highlighting and bag-value displays now combine rapid inventory events instead of repeatedly scanning during bag opening.


**2.0.4 visibility fix:** The journal's dark panel and border remain visible even when Global Appearance background strength is set to zero. Saved discoveries and map-button placement are unchanged.


Open the normal world map and click **Discoveries**. You can drag the map button wherever you prefer; right-click it to reset the position. In the Discoveries window, use the Area/Dungeon, Creature Source and Sort menus, or search for an item by name or ID.

If the button isn't available on your map layout, **/chalk drops map** opens the same window. **/chalk drops map status** provides useful diagnostics.

The recorded percentages describe **observed loot-window appearances for identifiable sources**. They are not official server drop rates or an estimate of every kill. Mixed-source windows and unknown sources still contribute to your item history, but don't produce a made-up creature-specific rate.

### MacroForge

Type **/chalk macro**, choose a template, then select the spells you actually know. Review the generated text and its warnings before copying it into the native macro editor. Saved recipes can be loaded and checked again after learning new abilities.

MacroForge doesn't automate rotations or bypass the global cooldown. Installing a native macro is an explicit, out-of-combat action; it won't silently replace one you've already made.

## Install

1. Download **[ChalkBox-2.0.4.zip](https://github.com/detok/ChalkBox/releases/download/v2.0.4/ChalkBox-2.0.4.zip)** from the GitHub release. Don't use the automatically generated "Source code" ZIP.
2. Extract the single **ChalkBox** folder into your Forever client's **Interface/AddOns** directory.
3. Check that **Interface/AddOns/ChalkBox/ChalkBox.toc** exists. Avoid an extra nested ChalkBox folder.
4. Launch the game and type **/chalk**.

Updating from a previous release? Replace the addon folder, but **keep your SavedVariables** to preserve history, layouts and preferences.

## Useful commands

| Command | Action |
| --- | --- |
| **/chalk** | Open settings |
| **/chalk macro** | Open MacroForge |
| **/chalk drops map** | Open Map Discoveries |
| **/chalk drops map reset** | Restore the map button position |
| **/chalk drops status** | Check DropSense recording |
| **/chalk session** | Open the current Session Journal |
| **/chalk session last** | Open the previous session |
| **/chalk bar status** | Check The Bar |
| **/chalk meter show** | Open the optional meter |
| **/chalk update** | Show installed version and release link |
| **/chalk prep test** | Preview the camping reminder |

[Complete command reference](curseforge/copy/COMMANDS.md) · [Troubleshooting](docs/TROUBLESHOOTING.md)

## CurseForge publishing assets

The **[CurseForge folder](curseforge/)** contains the current project description, short summary, FAQ, changelog and submission checklist, along with the original ChalkBox artwork.

The release also includes a separate **[CurseForge media kit ZIP](https://github.com/detok/ChalkBox/releases/download/v2.0.4/ChalkBox-CurseForge-Media-2.0.4.zip)** with six SVG originals, PNG exports, and ready-to-use listing copy. It is **not an addon installation file**.

The illustrations are promotional graphics, not in-game screenshots. Real screenshots should be captured from the running Forever client before being used in a gallery.

## Compatibility and support

ChalkBox targets **WoW Forever**. Retail and Classic Era compatibility have not been verified. Some client APIs may expose limited data, particularly for combat, loot sources and map layout.

**2.0.4 is a test release** until the reorganized options and meter startup have been checked in-game. Automated Lua 5.1 tests and ZIP packaging run through [GitHub Actions](.github/workflows/release.yml).

Report issues through [GitHub Issues](https://github.com/detok/ChalkBox/issues) with the ChalkBox version, Forever client build, steps to reproduce and any Lua error.

**Created and maintained by Detok Whitemaine.** Released under the [MIT license](LICENSE), with third-party license notices retained. Not affiliated with Blizzard Entertainment.
